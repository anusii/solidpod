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

import 'package:encrypt/encrypt.dart';
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// [KeyManager] is a class to manage security key and encryption keys
/// for data stored in PODs.
/// Part of the terminology used in this class are defined as follows:
/// - security key: the string user provides to unlock encrypted data in PODs
/// - master key: the sha256 of the security key
/// - verification key: the sha224 of the security key
/// - individual key: the AES key used to encrypt an individual file
/// - public/private key pair: the RSA key pair for data sharing
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
  static late String _securityKey;

  /// The master key
  static Key? _masterKey;

  /// The verification key
  static String? _verificationKey;

  /// The public key
  static String? _pubKey;

  /// The private key
  static String? _prvKey;

  /// The encrypted (and decrypted) individual keys
  static Map<String, _KeyRecord>? _indKeyMap;

  /// The string key for storing auth data in secure storage
  static const String _securityKeySecureStorageKey = '_solid_security_key';

  /// Set the security key
  static Future<void> setSecurityKey(String securityKey,
      {bool saveLocally = true}) async {
    final verified = await verifySecurityKey(securityKey);
    if (!verified) {
      throw Exception('Unable to verified the provided security key!');
    } else {
      _securityKey = securityKey;
      _masterKey = genMasterKey(_securityKey);

      if (saveLocally) {
        await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey);
      }
    }
  }

  /// Remove the security key from local secure storage
  static Future<void> forgetSecurityKey() async {
    if (await secureStorage.containsKey(key: _securityKeySecureStorageKey)) {
      await secureStorage.delete(key: _securityKeySecureStorageKey);
    }
  }

  /// Change the security key and update encKeyFile and indKeyFile in POD
  static Future<void> changeSecurityKey(
      String currentSecurityKey, String newSecurityKey) async {
    assert(newSecurityKey.trim().isNotEmpty);

    await setSecurityKey(currentSecurityKey, saveLocally: false);

    final newMasterKey = genMasterKey(newSecurityKey);

    // Re-generate the content of encKeyFile

    final encKeyTriples = <String, Map<String, String>>{};
    _prvKey ??= await getPrivateKey();
    assert(_encKeyUrl != null);
    _verificationKey = genVerificationKey(newSecurityKey);
    final prvKeyIV = getIV();
    encKeyTriples[_encKeyUrl!] = {
      titlePred: encKeyFileTitle,
      encKeyPred: _verificationKey!,
      ivPred: prvKeyIV.base64,
      prvKeyPred: encryptData(_prvKey!, newMasterKey, prvKeyIV),
    };
    final encKeyContent = _genTTLStr(encKeyTriples);
    print(encKeyContent);

    // Write encKeyFile to server
    await createResource(_encKeyUrl!,
        content: encKeyContent, replaceIfExist: true);

    // Re-generate the content of indKeyFile

    final indKeyTriples = <String, Map<String, String>>{};
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);

    assert(_indKeyUrl != null);
    indKeyTriples[_indKeyUrl!] = {titlePred: indKeyFileTitle};

    for (final entry in _indKeyMap!.entries) {
      final fileUrl = entry.key;
      final keyRecord = entry.value;
      final indIV = getIV();
      final indKey = await getIndividualKey(resourceUrl: fileUrl);
      final encIndKey = encryptData(indKey.base64, newMasterKey, indIV);
      indKeyTriples[fileUrl] = {
        pathPred: keyRecord.filePath,
        ivPred: indIV.base64,
        sessionKeyPred: encIndKey,
      };
      _indKeyMap![fileUrl]!.ivBase64 = indIV.base64;
      _indKeyMap![fileUrl]!.encKeyBase64 = encIndKey;
    }

    final indKeyContent = _genTTLStr(indKeyTriples);
    print(indKeyContent);

    // Write indKeyFile to server
    await createResource(_indKeyUrl!,
        content: indKeyContent, replaceIfExist: true);

    await setSecurityKey(newSecurityKey);
  }

  /// Verify the provided security key using verification key stored in POD
  static Future<bool> verifySecurityKey(String securityKey) async {
    if (_verificationKey == null) {
      await _loadEncKeyFile();
    }
    assert(_verificationKey != null);
    return _verificationKey == genVerificationKey(securityKey);
  }

  /// Return the public key
  static Future<String> getPublicKey() async {
    if (_pubKey == null) {
      await _loadPubKey();
    }
    assert(_pubKey != null);
    return _pubKey!;
  }

  /// Return the private key
  static Future<String> getPrivateKey() async {
    if (_prvKey == null) {
      _checkMasterKey();
      await _loadEncKeyFile();
    }
    assert(_prvKey != null);
    return _prvKey!;
  }

  /// Generate a new individual key OR
  /// return the (decrypted) individual key for an existing resource
  static Future<Key> getIndividualKey({String? resourceUrl}) async {
    if (resourceUrl == null) {
      return Key.fromSecureRandom(32);
    }

    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }

    assert(_indKeyMap != null);

    if (!_indKeyMap!.containsKey(resourceUrl)) {
      throw Exception(
          'Unable to find the individual key for resource: $resourceUrl');
    }

    final record = _indKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      _checkMasterKey();

      record.key = Key.fromBase64(decryptData(
          record.encKeyBase64, _masterKey!, IV.fromBase64(record.ivBase64)));
      _indKeyMap![resourceUrl] = record;
    }
    return record.key!;
  }

  /// Check if the master key is available
  static void _checkMasterKey() {
    if (_masterKey == null) {
      throw Exception('You must first set the security key.');
    }
  }

  /// Load the file with verification key and encrypted private key
  static Future<void> _loadEncKeyFile({bool forceReload = false}) async {
    if (_verificationKey != null && _prvKey != null && !forceReload) {
      return;
    }

    if (_encKeyUrl == null) {
      final encKeyPath = await getEncKeyPath();
      _encKeyUrl = await getFileUrl(encKeyPath);
    }

    _checkMasterKey();

    // Get and parse the encKeyFile
    final map = await loadPrvTTL(_encKeyUrl!);

    if (!map.containsKey(_encKeyUrl)) {
      throw Exception('Invalid content in file: $encKeyFile');
    }
    assert(map.length == 1);

    final v = map[_encKeyUrl] as Map;
    _verificationKey = v[encKeyPred] as String;

    _prvKey = decryptData(v[prvKeyPred] as String, _masterKey!,
        IV.fromBase64(v[ivPred] as String));
  }

  /// Load the file with encrypted individual keys

  static Future<void> _loadIndKeyFile({bool forceReload = false}) async {
    if (_indKeyMap != null && !forceReload) {
      return;
    }

    if (_indKeyUrl == null) {
      final indKeyPath = await getIndKeyPath();
      _indKeyUrl = await getFileUrl(indKeyPath);
    }

    _indKeyMap ??= <String, _KeyRecord>{};

    final map = await loadPrvTTL(_indKeyUrl!);

    for (final entry in map.entries) {
      final k = entry.key;
      final v = entry.value as Map;
      if (v.containsKey(sessionKeyPred)) {
        _indKeyMap![k] = _KeyRecord(
            encKeyBase64: v[sessionKeyPred] as String,
            ivBase64: v[ivPred] as String,
            filePath: v[pathPred] as String);
      }
    }
  }

  /// Load the file with public key
  static Future<void> _loadPubKey({bool forceReload = false}) async {
    if (_pubKey != null && !forceReload) {
      return;
    }

    if (_pubKeyUrl == null) {
      final pubKeyPath = await getPubKeyPath();
      _pubKeyUrl = await getFileUrl(pubKeyPath);
    }

    // Get and parse the pubKeyFile
    final map = await loadPrvTTL(_pubKeyUrl!);

    if (!map.containsKey(_pubKeyUrl)) {
      throw Exception('Invalid content in file: $pubKeyFile');
    }

    _pubKey = map[_pubKeyUrl][pubKeyPred] as String;
  }
}

/// [_KeyRecord] is a simple class to store encrypted and decrypted AES keys

class _KeyRecord {
  /// Constructor
  _KeyRecord(
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
}

/// Generate TTL string from triples stored in a map:
/// {subject: {predicate: object}}
/// where
/// - subject: the URL of a file
/// - predicate-object: the key-value pairs to be stores in the file

String _genTTLStr(Map<String, Map<String, String>> triples) {
  assert(triples.isNotEmpty);
  final g = Graph();
  final nsTerms = Namespace(ns: appsTerms);
  final nsTitle = Namespace(ns: '$terms$titlePred');

  for (final sub in triples.keys) {
    assert(triples[sub] != null && triples[sub]!.isNotEmpty);
    final f = URIRef(sub);
    for (final pre in triples[sub]!.keys.toList()..sort()) {
      final obj = triples[sub]![pre] as String;
      if (pre == titlePred) {
        g.addTripleToGroups(f, nsTitle, obj);
      } else {
        g.addTripleToGroups(f, nsTerms.withAttr(pre), obj);
      }
    }
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}
