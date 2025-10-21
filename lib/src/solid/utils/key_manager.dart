/// Class to manage keys for data encryption and sharing.
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
/// Authors: Dawei Chen, Anushka Vidanage

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:pointycastle/asymmetric/api.dart';

import 'package:solidpod/src/solid/api/rest_api.dart'
    show createResource, updateFileByQuery;
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

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

  /// URL of the file with shared encrypted individual keys
  static String? _sharedIndKeyUrl;

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
  static PrvKeyRecord? _prvKeyRecord;

  /// The encrypted (and decrypted) individual keys
  static Map<String, IndKeyRecord>? _indKeyMap;

  /// The decrypted shared individual keys
  static Map<String, SharedIndKeyRecord>? _sharedIndKeyMap;

  /// The string key for storing auth data in secure storage
  static const String _securityKeySecureStorageKey = '_solid_security_key';

  /// Remove stored security key and set all cached private members to null
  static Future<void> clear() async {
    await forgetSecurityKey();

    _encKeyUrl = null;
    _indKeyUrl = null;
    _pubKeyUrl = null;
    _sharedIndKeyUrl = null;

    _securityKey = null;
    _masterKey = null;
    _verificationKey = null;

    _pubKey = null;
    _prvKeyRecord = null;

    _indKeyMap = null;
    _sharedIndKeyMap = null;
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
    _prvKeyRecord = PrvKeyRecord(
      encKeyBase64: encryptPrivateKey(pair.privateKey, _masterKey!, iv),
      ivBase64: iv.base64,
      key: pair.privateKey,
    );

    // Save encKeyFile, indKeyFile, and pubKeyFile (on server)

    await _saveEncKey();
    await _saveIndKey();
    await _savePubKey();
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
      await _loadEncKey();
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
    String currentSecurityKey,
    String newSecurityKey,
  ) async {
    if (!verifySecurityKey(currentSecurityKey, await getVerificationKey())) {
      throw Exception('Unable to verify the current security key!');
    }

    assert(newSecurityKey.trim().isNotEmpty);
    assert(newSecurityKey != currentSecurityKey);

    _securityKey = currentSecurityKey;
    _masterKey ??= genMasterKey(_securityKey!);

    // Load key files and decrypt the private key and individual keys
    // using the old master key

    await _loadEncKey();
    await _loadIndKey();

    assert(_prvKeyRecord != null);
    _prvKeyRecord!.key ??= await getPrivateKey();

    assert(_indKeyMap != null);
    if (_indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final resourceUrl = entry.key;
        final record = entry.value;
        record.key ??= await getIndividualKey(resourceUrl);
        _indKeyMap![resourceUrl] = record;
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
    await _saveEncKey();

    // Encrypt the individual keys using the new master key (and new IVs)

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final resourceUrl = entry.key;
        final record = entry.value;

        final iv = genRandIV();
        final indKey = record.key;
        assert(indKey != null);

        record.ivBase64 = iv.base64;
        record.encKeyBase64 = encryptData(indKey!.base64, _masterKey!, iv);

        _indKeyMap![resourceUrl] = record;
      }
    }

    // Re-generate the content of indKeyFile and save it (on server)
    await _saveIndKey();

    // Save security key to local secure storage
    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);
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
    if (_prvKeyRecord == null) {
      await _loadEncKey();
    }

    assert(_prvKeyRecord != null);

    _prvKeyRecord!.key ??= decryptPrivateKey(
      _prvKeyRecord!.encKeyBase64,
      await getMasterKey(),
      IV.fromBase64(_prvKeyRecord!.ivBase64),
    );

    return _prvKeyRecord!.key!;
  }

  /// Returns true if there is an individual key for a given resource
  static Future<bool> hasIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await _loadIndKey();
    }
    assert(_indKeyMap != null);
    return _indKeyMap!.containsKey(resourceUrl);
  }

  /// Return the (decrypted) individual key for an existing resource
  static Future<Key> getIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await _loadIndKey();
    }

    assert(_indKeyMap != null);
    if (!_indKeyMap!.containsKey(resourceUrl)) {
      throw Exception(
        'Unable to locate the individual key for resource:\n$resourceUrl',
      );
    }

    final record = _indKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      record.key = Key.fromBase64(
        decryptData(
          record.encKeyBase64,
          await getMasterKey(),
          IV.fromBase64(record.ivBase64),
        ),
      );
      _indKeyMap![resourceUrl] = record;
    }
    return record.key!;
  }

  /// Add the (encrypted) individual key for file
  static Future<void> addIndividualKey(
    String resourcePath,
    Key indKey, {
    bool isFile = true,
  }) async {
    final resourceUrl = await (isFile ? getFileUrl : getDirUrl)(resourcePath);

    if (_indKeyMap == null) {
      await _loadIndKey();
    }
    assert(_indKeyMap != null);

    final iv = genRandIV();
    final encIndKey = encryptData(indKey.base64, await getMasterKey(), iv);

    final record = IndKeyRecord(
      resourcePath: resourcePath,
      encKeyBase64: encIndKey,
      ivBase64: iv.base64,
    );
    _indKeyMap![resourceUrl] = record;

    final query = await getIndKeyQuery(record,
        operation: SparqlOperation.insert, isFile: isFile);
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    await updateFileByQuery(_indKeyUrl!, query);
  }

  /// Remove the (encrypted) individual key for file
  static Future<void> removeIndividualKey(
    String resourcePath, {
    bool isFile = true,
  }) async {
    final resourceUrl = await (isFile ? getFileUrl : getDirUrl)(resourcePath);
    if (_indKeyMap == null) {
      await _loadIndKey();
    }
    assert(_indKeyMap != null);

    if (_indKeyMap!.containsKey(resourceUrl)) {
      final record = _indKeyMap!.remove(resourceUrl);
      assert(record != null);

      final query = await getIndKeyQuery(record!,
          operation: SparqlOperation.delete, isFile: isFile);
      _indKeyUrl ??= await getFileUrl(await getIndKeyPath());
      await updateFileByQuery(_indKeyUrl!, query);

      debugPrint('Deleted $record');
    } else {
      debugPrint(
          'Individual key for "$resourcePath" does not exist, do nothing.');
    }
  }

  /// Returns true if there is an individual key for a given resource
  static Future<bool> hasSharedIndividualKey(String resourceUrl) async {
    if (_sharedIndKeyMap == null || _sharedIndKeyMap!.isEmpty) {
      await _loadSharedIndKey();
    }
    assert(_sharedIndKeyMap != null);
    return _sharedIndKeyMap!.containsKey(resourceUrl);
  }

  /// Return the (decrypted) individual key for an existing resource
  static Future<Key> getSharedIndividualKey(String resourceUrl) async {
    if (_sharedIndKeyMap == null) {
      await _loadSharedIndKey();
    }

    assert(_sharedIndKeyMap != null);
    if (!_sharedIndKeyMap!.containsKey(resourceUrl)) {
      throw Exception(
        'Unable to locate the individual key for resource:\n$resourceUrl',
      );
    }

    final record = _sharedIndKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      _prvKeyRecord!.key ??= await getPrivateKey();
      final encrypter = Encrypter(
        RSA(
          privateKey:
              RSAKeyParser().parse(_prvKeyRecord!.key!) as RSAPrivateKey,
        ),
      );

      record.resourcePath = encrypter.decrypt64(record.encResourcePath);
      record.accessList = encrypter.decrypt64(record.encAccessList);
      record.key = Key.fromBase64(encrypter.decrypt64(record.encKey));
      _sharedIndKeyMap![resourceUrl] = record;
    }

    return record.key!;
  }

  /// Remove the (encrypted) shared individual key for file
  static Future<void> removeSharedIndividualKey(
    String resourceUrl,
    String resUniqueId,
  ) async {
    if (_sharedIndKeyMap == null) {
      await _loadSharedIndKey();
    }
    assert(_sharedIndKeyMap != null);

    if (_sharedIndKeyMap!.containsKey(resourceUrl)) {
      final record = _sharedIndKeyMap!.remove(resourceUrl);
      assert(record != null);

      // Delete shared key from shared keys file
      final query = await getSharedIndKeyDeletionQuery(resUniqueId, record!);
      _sharedIndKeyUrl ??= await getFileUrl(await getSharedKeyFilePath());

      await updateFileByQuery(_sharedIndKeyUrl!, query);

      debugPrint('Deleted $record');
    } else {
      debugPrint(
        'Shared individual key for "$resourceUrl" does not exist, do nothing.',
      );
    }
  }

  /// Load verification key and encrypted private key
  static Future<void> _loadEncKey({bool forceReload = false}) async {
    if (_verificationKey != null && _prvKeyRecord != null && !forceReload) {
      return;
    }

    final r = await readEncKeyFile();
    _verificationKey = r.verificationKey;
    _prvKeyRecord = r.record;
  }

  /// Generate the content of indKeyFile and save it (on server)
  static Future<void> _saveEncKey() async {
    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    await createResource(
      _encKeyUrl!,
      content:
          await genEncKeyTTLStr(_encKeyUrl!, _verificationKey!, _prvKeyRecord!),
    );
  }

  /// Load encrypted individual keys
  static Future<void> _loadIndKey({bool forceReload = false}) async {
    if (_indKeyMap != null && !forceReload) {
      return;
    }
    _indKeyMap = await readIndKeyFile();
  }

  /// Generate the content of indKeyFile and save it (on server)
  static Future<void> _saveIndKey() async {
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    await createResource(
      _indKeyUrl!,
      content: await genIndKeyTTLStr(_indKeyUrl!, _indKeyMap),
    );
  }

  /// Load the public key
  static Future<void> _loadPubKey({bool forceReload = false}) async {
    if (_pubKey != null && !forceReload) {
      return;
    }

    _pubKey = await readPubKeyFile();
  }

  /// Generate the content of pubKeyFile and save it (on server)
  static Future<void> _savePubKey() async {
    assert(_pubKey != null);
    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    await createResource(
      _pubKeyUrl!,
      content: await genPubKeyTTLStr(_pubKeyUrl!, _pubKey!),
    );
  }

  /// Load shared (encrypted) individual keys
  static Future<void> _loadSharedIndKey({bool forceReload = false}) async {
    if (_sharedIndKeyMap != null && !forceReload) {
      return;
    }

    if (_prvKeyRecord == null) {
      await _loadEncKey();
    }
    assert(_prvKeyRecord != null);
    _prvKeyRecord!.key ??= await getPrivateKey();

    _sharedIndKeyMap = await readSharedIndKey(_prvKeyRecord!.key!);
  }
}
