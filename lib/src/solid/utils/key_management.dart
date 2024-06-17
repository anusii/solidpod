/// Utilities for managing keys for data protection.
///
/// Some terminology used in this class are defined as follows:
/// - security key: the string user provides to unlock encrypted data in PODs
/// - master key: the sha256 of the security key
/// - verification key: the sha224 of the security key
/// - individual key: the AES key used to encrypt an individual file
/// - public/private key pair: the RSA key pair for data sharing.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Dawei Chen

library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:crypto/crypto.dart';
import 'package:rdflib/rdflib.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:encrypt/encrypt.dart' hide RSA;
import 'package:fast_rsa/fast_rsa.dart' show RSA;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart' show tripleMapToTTLStr;

/// Derive the master key from the security key
Key genMasterKey(String securityKey) => Key.fromUtf8(
    sha256.convert(utf8.encode(securityKey)).toString().substring(0, 32));

/// Derive the verification key from the security key
String genVerificationKey(String securityKey) =>
    sha224.convert(utf8.encode(securityKey)).toString().substring(0, 32);

/// Verify the security key
bool verifySecurityKey(String securityKey, String verificationKey) =>
    verificationKey == genVerificationKey(securityKey);

/// Create a random individual/session key
Key genRandIndividualKey() => Key.fromSecureRandom(32);

/// Create a random intialisation vector
IV genRandIV() => IV.fromLength(16);

/// Create a random public-private key pair
Future<({String publicKey, String privateKey})> genRandRSAKeyPair() async {
  final pair = await RSA.generate(2048);
  return (publicKey: pair.publicKey, privateKey: pair.privateKey);
}

/// Encrypt the private key for data sharing
String encryptPrivateKey(String privateKey, Key masterKey, IV iv) =>
    encryptData(privateKey, masterKey, iv, mode: AESMode.cbc);

/// Decrypt the (encrypted) private key for data sharing
String decryptPrivateKey(String encPrivateKey, Key masterKey, IV iv) =>
    decryptData(encPrivateKey, masterKey, iv, mode: AESMode.cbc);

/// Add the encrypted individual/session key string [encIndKey] and
/// the corresponding IV string [ivBase64] for file with path [filePath]
Future<void> _addIndKey(
    String filePath, String encIndKey, String ivBase64) async {
  final sub = await getFileUrl(filePath);

  final query = 'INSERT DATA {<$sub> <$appsTerms$pathPred> "$filePath"; '
      '<$appsTerms$ivPred> "$ivBase64"; '
      '<$appsTerms$sessionKeyPred> "$encIndKey".};';

  final fileUrl = await getFileUrl(await getIndKeyPath());

  await updateFileByQuery(fileUrl, query);
}

/// Delete the encrypted individual/session key string [encIndKey] and
/// the corresponding IV string [ivBase64] for file with path [filePath]
Future<void> _delIndKey(
    String filePath, String encIndKey, String ivBase64) async {
  final sub = await getFileUrl(filePath);

  final query = 'DELETE DATA {<$sub> <$appsTerms$pathPred> "$filePath"; '
      '<$appsTerms$ivPred> "$ivBase64"; '
      '<$appsTerms$sessionKeyPred> "$encIndKey".};';

  final fileUrl = await getFileUrl(await getIndKeyPath());

  await updateFileByQuery(fileUrl, query);
}

/// [KeyManager] is a class to manage security key and encryption keys
/// for data stored in PODs.
///
/// Some rules we follow:
/// - The "security key" and "master key" are never stored in PODs
/// - Each encrypted file is associated with its own "individual key"
/// - All "individual key"s are encrypted using AES with the "master key"
/// - All encrypted "individual key"s and their IVs are stored in
///   POD_NAME/encryption/ind-keys.ttl
/// - The private key is encrypted using the "master key" and stored in
///   POD_NAME/encryption/enc-keys.ttl (together with its IV)
/// - The public key is stored in POD_NAME/sharing/public-key.ttl
/// - The verification key is stored in POD_NAME/encryption/enc-keys.ttl

class KeyManager {
  /// URL of the file with verification key and encrypted private key
  static String? _encKeyUrl;

  /// URL of the file with encrypted individual keys
  static String? _indKeyUrl;

  /// URL of the file with public key
  static String? _pubKeyUrl;

  /// The security key
  static String? _securityKey;

  /// The master key
  static Key? _masterKey;

  /// The verification key
  static String? _verificationKey;

  /// The public key
  static String? _pubKey;

  /// The encrypted (and decrypted) private key
  static _PrvKeyRecord? _prvKeyRecord;

  /// The encrypted (and decrypted) individual keys
  static Map<String, _IndKeyRecord>? _indKeyMap;

  /// The string key for storing auth data in secure storage
  static const String _securityKeySecureStorageKey = '_solid_security_key';

  /// Remove stored security key and set all cached private members to null
  static Future<void> clear() async {
    await forgetSecurityKey();

    _encKeyUrl = null;
    _indKeyUrl = null;
    _pubKeyUrl = null;

    _securityKey = null;
    _masterKey = null;
    _verificationKey = null;

    _pubKey = null;
    _prvKeyRecord = null;

    _indKeyMap = null;
  }

  /// Initialise the encKeyFile, indKeyFile and pubKeyFile
  /// and save them (on server)
  static Future<void> initPodKeys(String securityKey) async {
    assert(securityKey.trim().isNotEmpty);

    // Clear cached value (if there are any)
    await clear();

    // Set the security key, master key, and verification key

    _securityKey = securityKey;
    _masterKey = genMasterKey(_securityKey!);
    _verificationKey = genVerificationKey(_securityKey!);
    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);

    // Set the public-private key pair

    final pair = await genRandRSAKeyPair();
    _pubKey = trimPubKeyStr(pair.publicKey);
    final iv = genRandIV();
    _prvKeyRecord = _PrvKeyRecord(
        encKeyBase64: encryptPrivateKey(pair.privateKey, _masterKey!, iv),
        ivBase64: iv.base64,
        key: pair.privateKey);

    // Save encKeyFile, indKeyFile, and pubKeyFile (on server)

    await _saveEncKeyFile();
    await _saveIndKeyFile();
    await _savePubKeyFile();
  }

  /// Get the master key
  static Future<Key> getMasterKey() async {
    if (_masterKey == null) {
      _securityKey ??=
          await secureStorage.read(key: _securityKeySecureStorageKey);

      if (_securityKey == null) {
        throw Exception('You must first set the security key!');
      }

      if (!verifySecurityKey(_securityKey!, await getVerificationKey())) {
        await forgetSecurityKey();
        throw Exception('Unable to verify the security key!');
      }

      _masterKey = genMasterKey(_securityKey!);
    }

    return _masterKey!;
  }

  /// Get the verification key
  static Future<String> getVerificationKey() async {
    if (_verificationKey == null) {
      await _loadEncKeyFile();
    }
    assert(_verificationKey != null);
    return _verificationKey!;
  }

  /// Check if the security is available
  static Future<bool> hasSecurityKey() async {
    _securityKey ??=
        await secureStorage.read(key: _securityKeySecureStorageKey);

    if (_securityKey == null) {
      return false;
    }

    if (!verifySecurityKey(_securityKey!, await getVerificationKey())) {
      await forgetSecurityKey();
      return false;
    }

    return true;
  }

  /// Set the security key
  static Future<void> setSecurityKey(String securityKey) async {
    if (await hasSecurityKey()) {
      debugPrint('Security key already set, do nothing.');
      return;
    }

    if (!verifySecurityKey(securityKey, await getVerificationKey())) {
      throw Exception('Unable to verify the provided security key!');
    }

    _securityKey = securityKey;
    _masterKey = genMasterKey(_securityKey!);

    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);
  }

  /// Remove the security key from memory and local secure storage
  static Future<void> forgetSecurityKey() async {
    if (await secureStorage.containsKey(key: _securityKeySecureStorageKey)) {
      await secureStorage.delete(key: _securityKeySecureStorageKey);
    }

    // Remove the security key, master key, decrypted private key,
    // and decrypted individual keys from memory (if applicable).

    _securityKey = null;
    _masterKey = null;

    if (_prvKeyRecord != null) {
      _prvKeyRecord!.key = null;
    }

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final record in _indKeyMap!.values) {
        record.key = null;
      }
    }
  }

  /// Change the security key and update encKeyFile and indKeyFile in POD
  static Future<void> changeSecurityKey(
      String currentSecurityKey, String newSecurityKey) async {
    if (!verifySecurityKey(currentSecurityKey, await getVerificationKey())) {
      throw Exception('Unable to verify the current security key!');
    }

    assert(newSecurityKey.trim().isNotEmpty);
    assert(newSecurityKey != currentSecurityKey);

    _securityKey = currentSecurityKey;
    _masterKey ??= genMasterKey(_securityKey!);

    // Load key files and decrypt the private key and individual keys
    // using the old master key

    await _loadEncKeyFile();
    await _loadIndKeyFile();

    assert(_prvKeyRecord != null);
    _prvKeyRecord!.key ??= await getPrivateKey();

    assert(_indKeyMap != null);
    if (_indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final fileUrl = entry.key;
        final record = entry.value;
        record.key ??= await getIndividualKey(fileUrl);
        _indKeyMap![fileUrl] = record;
      }
    }

    // Set the new security key, master key, and verification key

    _securityKey = newSecurityKey;
    _masterKey = genMasterKey(_securityKey!);
    _verificationKey = genVerificationKey(_securityKey!);

    // Encrypt the private key using the new master key (and new IV)

    final iv = genRandIV();
    _prvKeyRecord!.ivBase64 = iv.base64;
    _prvKeyRecord!.encKeyBase64 =
        encryptPrivateKey(_prvKeyRecord!.key!, _masterKey!, iv);

    // Re-generate the content of encKeyFile and save it (on server)
    await _saveEncKeyFile();

    // Encrypt the individual keys using the new mater key (and new IVs)

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final fileUrl = entry.key;
        final record = entry.value;

        final iv = genRandIV();
        final indKey = record.key;
        assert(indKey != null);

        record.ivBase64 = iv.base64;
        record.encKeyBase64 = encryptData(indKey!.base64, _masterKey!, iv);

        _indKeyMap![fileUrl] = record;
      }
    }

    // Re-generate the content of indKeyFile and save it (on server)
    await _saveIndKeyFile();

    // Save security key to local secure storage
    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);
  }

  /// Return the public key
  static Future<String> getPublicKey() async {
    if (_pubKey == null) {
      await _loadPubKeyFile();
    }
    assert(_pubKey != null);
    return _pubKey!;
  }

  /// Return the private key
  static Future<String> getPrivateKey() async {
    if (_prvKeyRecord == null) {
      await _loadEncKeyFile();
    }

    assert(_prvKeyRecord != null);

    _prvKeyRecord!.key ??= decryptPrivateKey(_prvKeyRecord!.encKeyBase64,
        await getMasterKey(), IV.fromBase64(_prvKeyRecord!.ivBase64));

    return _prvKeyRecord!.key!;
  }

  /// Returns true if there is an individual key for a given resource
  static Future<bool> hasIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);
    return _indKeyMap!.containsKey(resourceUrl);
  }

  /// Return the (decrypted) individual key for an existing resource
  static Future<Key> getIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }

    assert(_indKeyMap != null);
    if (!_indKeyMap!.containsKey(resourceUrl)) {
      throw Exception(
          'Unable to locate the individual key for resource:\n$resourceUrl');
    }

    final record = _indKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      record.key = Key.fromBase64(decryptData(record.encKeyBase64,
          await getMasterKey(), IV.fromBase64(record.ivBase64)));
      _indKeyMap![resourceUrl] = record;
    }
    return record.key!;
  }

  /// Add the (encrypted) individual key for file
  static Future<void> addIndividualKey(String filePath, Key indKey) async {
    final fileUrl = await getFileUrl(filePath);
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);

    final iv = genRandIV();
    final encIndKey = encryptData(indKey.base64, await getMasterKey(), iv);
    _indKeyMap![fileUrl] = _IndKeyRecord(
        filePath: filePath, encKeyBase64: encIndKey, ivBase64: iv.base64);

    await _addIndKey(filePath, encIndKey, iv.base64);
  }

  /// Remove the (encrypted) individual key for file
  static Future<void> removeIndividualKey(String filePath) async {
    final fileUrl = await getFileUrl(filePath);
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);

    if (_indKeyMap!.containsKey(fileUrl)) {
      final record = _indKeyMap!.remove(fileUrl);
      assert(record != null);
      await _delIndKey(filePath, record!.encKeyBase64, record.ivBase64);
      debugPrint('Deleted $record');
    } else {
      debugPrint('Individual key for "$filePath" does not exist, do nothing.');
    }
  }

  /// Load the file with verification key and encrypted private key
  static Future<void> _loadEncKeyFile({bool forceReload = false}) async {
    if (_verificationKey != null && _prvKeyRecord != null && !forceReload) {
      return;
    }

    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    // _checkMasterKey();

    // Get and parse the encKeyFile
    final map = await loadPrvTTL(_encKeyUrl!);

    if (!map.containsKey(_encKeyUrl)) {
      throw Exception('Invalid content in file: "$_encKeyUrl"');
    }
    assert(map.length == 1);

    final v = map[_encKeyUrl] as Map;
    _verificationKey = v[encKeyPred] as String;

    _prvKeyRecord = _PrvKeyRecord(
        encKeyBase64: v[prvKeyPred] as String, ivBase64: v[ivPred] as String);
  }

  /// Generate the content of indKeyFile and save it (on server)
  static Future<void> _saveEncKeyFile() async {
    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    await createResource(_encKeyUrl!,
        content: await _genEncKeyTTLStr(), replaceIfExist: true);
  }

  /// Load the file with encrypted individual keys
  static Future<void> _loadIndKeyFile({bool forceReload = false}) async {
    if (_indKeyMap != null && !forceReload) {
      return;
    }

    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    _indKeyMap ??= <String, _IndKeyRecord>{};

    final map = await loadPrvTTL(_indKeyUrl!);

    for (final entry in map.entries) {
      final k = entry.key;
      final v = entry.value as Map;
      if (v.containsKey(sessionKeyPred)) {
        _indKeyMap![k] = _IndKeyRecord(
            encKeyBase64: v[sessionKeyPred] as String,
            ivBase64: v[ivPred] as String,
            filePath: v[pathPred] as String);
      }
    }
  }

  /// Generate the content of indKeyFile and save it (on server)
  static Future<void> _saveIndKeyFile() async {
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    await createResource(_indKeyUrl!,
        content: await _genIndKeyTTLStr(), replaceIfExist: true);
  }

  /// Load the file with public key
  static Future<void> _loadPubKeyFile({bool forceReload = false}) async {
    if (_pubKey != null && !forceReload) {
      return;
    }

    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    // Get and parse the pubKeyFile
    final map = await loadPrvTTL(_pubKeyUrl!);

    if (!map.containsKey(_pubKeyUrl)) {
      throw Exception('Invalid content in file: "$_pubKeyUrl"');
    }

    _pubKey = map[_pubKeyUrl][pubKeyPred] as String;
  }

  /// Generate the content of pubKeyFile and save it (on server)
  static Future<void> _savePubKeyFile() async {
    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    await createResource(_pubKeyUrl!,
        content: await _genPubKeyTTLStr(), replaceIfExist: true);
  }

  /// Generate the content of encKeyFile
  static Future<String> _genEncKeyTTLStr() async {
    assert(_verificationKey != null);
    assert(_prvKeyRecord != null);

    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    final tripleMap = <String, Map<String, String>>{};
    tripleMap[_encKeyUrl!] = {
      titlePred: encKeyFileTitle,
      encKeyPred: _verificationKey!,
      ivPred: _prvKeyRecord!.ivBase64,
      prvKeyPred: _prvKeyRecord!.encKeyBase64,
    };

    return tripleMapToTTLStr(tripleMap);
  }

  /// Generate the content of indKeyFile
  static Future<String> _genIndKeyTTLStr() async {
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    final tripleMap = <String, Map<String, String>>{};
    tripleMap[_indKeyUrl!] = {titlePred: indKeyFileTitle};

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final fileUrl = entry.key;
        final record = entry.value;

        final indKey = record.key;
        assert(indKey != null);

        tripleMap[fileUrl] = {
          pathPred: record.filePath,
          ivPred: record.ivBase64,
          sessionKeyPred: record.encKeyBase64,
        };
      }
    }

    return tripleMapToTTLStr(tripleMap);
  }

  /// Generate the content of pubKeyFile
  static Future<String> _genPubKeyTTLStr() async {
    assert(_pubKey != null);

    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    final tripleMap = <String, Map<String, String>>{};
    tripleMap[_pubKeyUrl!] = {
      titlePred: pubKeyFileTitle,
      pubKeyPred: _pubKey!,
    };

    return tripleMapToTTLStr(tripleMap);
  }
}

/// [_IndKeyRecord] is a simple class to store encrypted and decrypted AES keys
/// of individual data files.

class _IndKeyRecord {
  /// Constructor
  _IndKeyRecord(
      {required this.filePath,
      required this.encKeyBase64,
      required this.ivBase64});

  /// The path of file corresponds to the key
  final String filePath;

  /// The base64 string of the encrypted key
  String encKeyBase64;

  /// The base64 string of the IV
  String ivBase64;

  /// The corresponding decrypted key
  Key? key;

  @override
  String toString() {
    return 'IndividualKeyRecord {\n'
        '    filePath: $filePath,\n'
        '    encIndKey: $encKeyBase64,\n'
        '    iv: $ivBase64\n'
        '}';
  }
}

/// [_PrvKeyRecord] is a simple class to store encrypted and decrypted
/// private key for data sharing.

class _PrvKeyRecord {
  /// Constructor
  _PrvKeyRecord({required this.encKeyBase64, required this.ivBase64, this.key});

  /// The base64 string of the encrypted private key
  String encKeyBase64;

  /// The base64 string of the IV
  String ivBase64;

  /// The corresponding decrypted private key
  String? key;
}

/// [RecipientPubKey] is a class to store public keys of another POD.
/// This public key is used to share encrypted data to this POD

class RecipientPubKey {
  /// Constructor
  RecipientPubKey({required this.recipientWebId});

  /// The webId of the recipient
  String recipientWebId;

  /// The content of the public key
  String? _recipientPubKeyContent;

  /// The public key with prefix and suffix
  RSAPublicKey? _recipientPubKey;

  /// Get the public key
  Future<RSAPublicKey> getPubKey() async {
    if (_recipientPubKey == null) {
      await _setPubKey();
    }

    return _recipientPubKey!;
  }

  /// Get the public key content
  Future<String> getPubKeyContent() async {
    if (_recipientPubKeyContent == null) {
      await _setPubKey();
    }

    return _recipientPubKeyContent!;
  }

  /// Set the public key
  Future<void> _setPubKey() async {
    /// Get recipient's public key
    final recipientPubKeyUrl =
        recipientWebId.replaceAll(profCard, await getPubKeyPath());

    // Get and parse the pubKeyFile
    final map = await loadPrvTTL(recipientPubKeyUrl);

    if (!map.containsKey(recipientPubKeyUrl)) {
      throw Exception('Invalid content in file: "$recipientPubKeyUrl"');
    }

    _recipientPubKeyContent = map[recipientPubKeyUrl][pubKeyPred] as String;

    final recipientPubKeyStr = genPubKeyStr(_recipientPubKeyContent as String);

    final parser = RSAKeyParser();
    _recipientPubKey = parser.parse(recipientPubKeyStr) as RSAPublicKey;
  }

  /// Encrypt a given value using public key
  Future<String> encryptData(String dataVal) async {
    if (_recipientPubKey == null) {
      await _setPubKey();
    }

    final encrypter = Encrypter(RSA(publicKey: _recipientPubKey));
    return encrypter.encrypt(dataVal).base64;
  }
}

/// Generate TTL string from triples stored in a map:
/// {subject: {predicate: object}}
/// where
/// - subject: the URL of a file
/// - predicate-object: the key-value pairs to be stores in the file

String _genTTLStr(Map<String, Map<String, String>> tripleMap) {
  assert(tripleMap.isNotEmpty);
  final g = Graph();
  final nsTerms = Namespace(ns: appsTerms);
  final nsTitle = Namespace(ns: terms);

  for (final sub in tripleMap.keys) {
    assert(tripleMap[sub] != null && tripleMap[sub]!.isNotEmpty);
    final f = URIRef(sub);
    for (final pre in tripleMap[sub]!.keys) {
      final obj = tripleMap[sub]![pre] as String;
      final ns = (pre == titlePred) ? nsTitle : nsTerms;
      g.addTripleToGroups(f, ns.withAttr(pre), obj);
    }
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}
