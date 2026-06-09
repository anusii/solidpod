/// Main coordinator class for managing keys for data encryption and sharing.
///
/// This class delegates specific responsibilities to specialized managers:
/// - [KeyStorage]: Secure storage operations
/// - [IndividualKeyManager]: Individual encryption keys
/// - [SharedKeyManager]: Shared encryption keys
/// - [KeyOperations]: Key file loading and saving
///
/// Some terminology used in this class are defined as follows:
/// - security key: the string user provides to unlock encrypted data in PODs
/// - master key: the AES key derived from the security key. Version 2 derives
///   it via Argon2id + HKDF using a stored salt; legacy (version 1) PODs used
///   plain sha256 (see [deriveKeys] / [genLegacyMasterKey]).
/// - verification key: a value derived from the security key and stored on the
///   POD to check the key is correct. Version 2 derives it via the same
///   Argon2id run (HKDF, separate domain); legacy used plain sha224.
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

import 'dart:convert' show base64;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';

import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/individual_key_manager.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/key_operations.dart';
import 'package:solidpod/src/solid/utils/key_storage.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/shared_key_manager.dart';

/// [KeyManager] is the main coordinator class to manage security key and
/// encryption keys for data stored in PODs.
///
/// Some rules we follow:
/// - The "security key" and "master key" are never stored in PODs.
/// - Each encrypted file is associated with its own "individual key".
/// - All "individual key"s are encrypted using AES with the "master key".
/// - All encrypted "individual key"s and their IVs are stored in
///   POD_NAME/encryption/ind-keys.ttl.
/// - The private key is encrypted using the "master key" and stored in
///   POD_NAME/encryption/enc-keys.ttl (together with its IV).
/// - The public key is stored in POD_NAME/sharing/public-key.ttl.
/// - The verification key is stored in POD_NAME/encryption/enc-keys.ttl.

class KeyManager {
  // The security key.

  static String? _securityKey;

  // The master key.

  static Key? _masterKey;

  // Random salt

  static List<int>? _salt;

  /// Remove stored security key and set all cached private members to null.

  static Future<void> clear() async {
    try {
      // Remove security key from storage and memory.

      await forgetSecurityKey();

      // Clear sensitive key material from memory.

      _securityKey = null;
      _masterKey = null;
      _salt = null;

      // Clear all sub-managers.

      KeyOperations.clear();
      IndividualKeyManager.clear();
      SharedKeyManager.clear();

      debugPrint(
        'KeyManager => clear() completed - all sensitive data cleared',
      );
    } on Object catch (e) {
      // Log only the exception type, never `$e`: this class handles the raw
      // security key and master key, and a lower-level error could echo them
      // (finding M1).
      debugPrint(
        'KeyManager => clear() error during clearing: ${e.runtimeType}',
      );

      // Fallback: force-clear all memory state anyway.

      try {
        _securityKey = null;
        _masterKey = null;
        KeyOperations.clear();
        IndividualKeyManager.clear();
        SharedKeyManager.clear();
        debugPrint('KeyManager => clear() fallback memory clear succeeded');
      } catch (fallbackError) {
        debugPrint(
          'KeyManager => clear() fallback also failed: '
          '${fallbackError.runtimeType}',
        );
      }
    }
  }

  /// Initialise the encKeyFile, indKeyFile and pubKeyFile
  /// and save them (on server).

  static Future<void> initPodKeys(String securityKey) async {
    try {
      assert(securityKey.trim().isNotEmpty);

      // Clear cached value (if there are any).

      await clear();

      // Set the security key, master key, and verification key in memory first.
      // NOTE: Do NOT save to local storage yet - must save to server first.

      _securityKey = securityKey;
      _salt = generateSalt();
      final keys = await deriveKeys(_securityKey!, _salt!);
      _masterKey = keys.masterKey;
      final verificationKey = keys.verificationKey;

      // Set the public-private key pair.

      final pair = await genRandRSAKeyPair();
      final pubKey = trimPubKeyStr(pair.publicKey);
      final iv = genRandIV();
      final prvKeyRecord = PrvKeyRecord(
        encKeyBase64: encryptPrivateKey(pair.privateKey, _masterKey!, iv),
        ivBase64: iv.base64,
        key: pair.privateKey,
      );

      // Save encKeyFile, indKeyFile, and pubKeyFile (on server) FIRST.
      // This ensures server has the verification key before we save locally.

      await KeyOperations.saveEncryptionKey(
        verificationKey,
        prvKeyRecord,
        saltB64: base64.encode(_salt!),
        version: kdfVersion,
      );
      await IndividualKeyManager.saveIndividualKeys(null);
      await KeyOperations.savePublicKey(pubKey);

      // Cache the keys in operations manager.

      KeyOperations.setVerificationKey(verificationKey);
      KeyOperations.setPublicKey(pubKey);
      KeyOperations.setPrivateKeyRecord(prvKeyRecord);

      // Only save to local storage AFTER server save succeeds.
      // This prevents orphaned local keys when server save fails.

      await KeyStorage.writeSecurityKey(_securityKey!);
    } catch (e) {
      debugPrint('KeyManager => initPodKeys() error: ${e.runtimeType}');

      // Clear memory state on failure to prevent inconsistent state.

      _securityKey = null;
      _masterKey = null;
      rethrow;
    }
  }

  /// Get the master key.

  static Future<Key> getMasterKey() async {
    if (_masterKey == null) {
      _securityKey ??= await KeyStorage.readSecurityKey();

      if (_securityKey == null) {
        throw Exception('You must first set the security key!');
      }

      try {
        _masterKey = await _resolveMasterKey(_securityKey!);
      } on SecurityKeyVerificationException {
        // Only forget the stored key on a genuine mismatch, not on transient
        // errors (network, missing file).
        await forgetSecurityKey();
        rethrow;
      }
    }

    return _masterKey!;
  }

  /// Verify [securityKey] against the verification value stored on the POD and
  /// return the derived master key.
  ///
  /// For version 2 PODs the master key is derived with Argon2id + HKDF using
  /// the stored salt. For legacy (version 1) PODs the old sha256 master key is
  /// returned. Throws [SecurityKeyVerificationException] when the key is wrong.
  ///
  /// Does NOT migrate; callers that want migration use [_resolveMasterKey].

  static Future<({Key masterKey, int version})> _verifyAndDerive(
    String securityKey,
  ) async {
    await KeyOperations.loadEncryptionKey();
    final version = KeyOperations.getKeyVersion() ?? 1;
    final storedVerification = await getVerificationKey();

    if (version >= 2) {
      final saltB64 = KeyOperations.getSalt();
      if (saltB64 == null) {
        throw Exception(
          'Missing key-derivation salt for a version $version POD!',
        );
      }
      final keys = await deriveKeys(securityKey, base64.decode(saltB64));
      if (!constantTimeEquals(storedVerification, keys.verificationKey)) {
        throw SecurityKeyVerificationException(
          'Unable to verify the security key!',
        );
      }
      _salt = base64.decode(saltB64);
      return (masterKey: keys.masterKey, version: version);
    }

    // Legacy (version 1): verify with the old sha224 scheme.

    if (!verifySecurityKey(securityKey, storedVerification)) {
      throw SecurityKeyVerificationException(
        'Unable to verify the security key!',
      );
    }
    return (masterKey: genLegacyMasterKey(securityKey), version: 1);
  }

  /// Verify [securityKey] and return the master key, migrating legacy PODs to
  /// the current scheme ([kdfVersion]) on the first successful login.

  static Future<Key> _resolveMasterKey(String securityKey) async {
    final r = await _verifyAndDerive(securityKey);
    if (r.version < kdfVersion) {
      return _migrateToV2(securityKey, r.masterKey);
    }
    return r.masterKey;
  }

  /// Re-derive version 2 keys for [targetSecurityKey] with a fresh salt and
  /// re-encrypt all key material currently protected by [oldMasterKey].
  ///
  /// Re-encrypts the private key (in enc-keys.ttl) and all individual keys (in
  /// ind-keys.ttl) under the new master key, and persists the new verification
  /// value + salt + version on the server. Data files are NOT touched: each is
  /// encrypted under its own individual key, only the master-key encryption of
  /// those keys changes. Returns the new master key and salt; does NOT write
  /// the security key to local storage.

  static Future<({Key masterKey, List<int> salt})> _rekeyToV2(
    Key oldMasterKey,
    String targetSecurityKey,
  ) async {
    // Load and decrypt existing key material under the old master key.

    await KeyOperations.loadEncryptionKey();
    await IndividualKeyManager.loadIndividualKeys();

    final prvKeyRecord = KeyOperations.getPrivateKeyRecord();
    assert(prvKeyRecord != null);
    prvKeyRecord!.key ??= decryptPrivateKey(
      prvKeyRecord.encKeyBase64,
      oldMasterKey,
      IV.fromBase64(prvKeyRecord.ivBase64),
    );

    // Derive new version 2 keys with a fresh salt.

    final newSalt = generateSalt();
    final keys = await deriveKeys(targetSecurityKey, newSalt);
    final newMasterKey = keys.masterKey;

    // Re-encrypt the private key under the new master key.

    final iv = genRandIV();
    prvKeyRecord.ivBase64 = iv.base64;
    prvKeyRecord.encKeyBase64 = encryptPrivateKey(
      prvKeyRecord.key!,
      newMasterKey,
      iv,
    );

    await KeyOperations.saveEncryptionKey(
      keys.verificationKey,
      prvKeyRecord,
      saltB64: base64.encode(newSalt),
      version: kdfVersion,
    );
    KeyOperations.setVerificationKey(keys.verificationKey);
    KeyOperations.setPrivateKeyRecord(prvKeyRecord);

    // Re-encrypt all individual keys under the new master key.

    await IndividualKeyManager.reEncryptIndividualKeys(
      oldMasterKey,
      newMasterKey,
    );

    return (masterKey: newMasterKey, salt: newSalt);
  }

  /// Re-key a legacy POD to the current scheme ([kdfVersion]) without changing
  /// the security key. Returns the new master key.

  static Future<Key> _migrateToV2(
    String securityKey,
    Key oldMasterKey,
  ) async {
    debugPrint('KeyManager => migrating POD keys to version $kdfVersion');
    final r = await _rekeyToV2(oldMasterKey, securityKey);
    _salt = r.salt;
    return r.masterKey;
  }

  /// Get the verification key.
  ///
  /// Throws an exception if user is not logged in.

  static Future<String> getVerificationKey() async {
    var verificationKey = KeyOperations.getVerificationKey();
    if (verificationKey == null) {
      await KeyOperations.loadEncryptionKey();
      verificationKey = KeyOperations.getVerificationKey();
    }
    assert(verificationKey != null);
    return verificationKey!;
  }

  /// Check if the security is available.

  static Future<bool> hasSecurityKey() async {
    try {
      _securityKey ??= await KeyStorage.readSecurityKey();

      if (_securityKey == null) {
        return false;
      }

      // Check if user is logged in before attempting to verify.

      final authData = await AuthDataManager.loadAuthData();

      if (authData == null) {
        // User not logged in - can't verify key without auth.
        // Keep the security key in storage for when they login.

        return false;
      }

      // Verifying a version 2 key requires deriving it (Argon2id), so cache the
      // resulting master key. Migrates legacy PODs on first successful login.

      _masterKey ??= await _resolveMasterKey(_securityKey!);

      return true;
    } catch (e) {
      debugPrint('KeyManager => hasSecurityKey() error: ${e.runtimeType}');

      // If verification key file doesn't exist, this will throw.
      // In that case, the key in storage is orphaned and should be removed.

      await forgetSecurityKey();
      return false;
    }
  }

  /// Set the security key.

  static Future<void> setSecurityKey(String securityKey) async {
    if (await hasSecurityKey()) {
      debugPrint('Security key already set, do nothing.');
      return;
    }

    // Verify the key and derive the master key (migrating legacy PODs on the
    // way). Throws [SecurityKeyVerificationException] if the key is wrong.

    _masterKey = await _resolveMasterKey(securityKey);
    _securityKey = securityKey;

    await KeyStorage.writeSecurityKey(_securityKey!);
  }

  /// Remove the security key from memory and local secure storage.
  ///
  /// This function is platform-safe:
  /// - Uses FlutterSecureStorage which is safe on all platforms including web.
  /// - Only clears memory-based state.
  /// - Never attempts file system operations.
  ///
  /// Errors during storage deletion are logged but don't prevent memory cleanup.

  static Future<void> forgetSecurityKey() async {
    try {
      // Step 1: Remove from secure storage (safe on all platforms).

      await KeyStorage.deleteSecurityKey();

      // Step 2: ALWAYS clear sensitive data from memory (most critical).
      // Do this even if storage deletion failed.

      _securityKey = null;
      _masterKey = null;

      // Clear decrypted keys from all managers.

      KeyOperations.clearDecryptedPrivateKey();
      IndividualKeyManager.clearDecryptedKeys();

      debugPrint(
        'KeyManager => forgetSecurityKey() cleared all sensitive data from memory',
      );
    } on Object catch (e) {
      debugPrint(
        'KeyManager => forgetSecurityKey() unexpected error: ${e.runtimeType}',
      );

      // Fallback: null out everything anyway.

      try {
        _securityKey = null;
        _masterKey = null;
        KeyOperations.clearDecryptedPrivateKey();
        IndividualKeyManager.clearDecryptedKeys();
        debugPrint(
          'KeyManager => forgetSecurityKey() fallback memory clear succeeded',
        );
      } catch (fallbackError) {
        debugPrint(
          'KeyManager => forgetSecurityKey() fallback also failed: '
          '${fallbackError.runtimeType}',
        );
      }
    }
  }

  /// Change the security key and update encKeyFile and indKeyFile in POD.

  static Future<void> changeSecurityKey(
    String currentSecurityKey,
    String newSecurityKey,
  ) async {
    assert(newSecurityKey.trim().isNotEmpty);
    assert(newSecurityKey != currentSecurityKey);

    // Verify the current key and derive its (possibly legacy) master key.
    // Throws [SecurityKeyVerificationException] if the current key is wrong.

    final old = await _verifyAndDerive(currentSecurityKey);

    // Re-key all material to version 2 under the new security key.

    final r = await _rekeyToV2(old.masterKey, newSecurityKey);

    // Commit the new in-memory state and persist the security key locally.

    _securityKey = newSecurityKey;
    _masterKey = r.masterKey;
    _salt = r.salt;

    await KeyStorage.writeSecurityKey(_securityKey!);
  }

  /// Return the public key.

  static Future<String> getPublicKey() async {
    var pubKey = KeyOperations.getPublicKey();

    if (pubKey == null) {
      await KeyOperations.loadPublicKey();
      pubKey = KeyOperations.getPublicKey();
    }

    assert(pubKey != null);
    return pubKey!;
  }

  /// Return the private key.
  ///
  /// Throws an exception if user is not logged in.

  static Future<String> getPrivateKey() async {
    var prvKeyRecord = KeyOperations.getPrivateKeyRecord();

    if (prvKeyRecord == null) {
      await KeyOperations.loadEncryptionKey();
      prvKeyRecord = KeyOperations.getPrivateKeyRecord();
    }

    assert(prvKeyRecord != null);

    prvKeyRecord!.key ??= decryptPrivateKey(
      prvKeyRecord.encKeyBase64,
      await getMasterKey(),
      IV.fromBase64(prvKeyRecord.ivBase64),
    );

    return prvKeyRecord.key!;
  }

  /// Retrieve the (decrypted) individual key for an existing resource.
  ///
  /// Return null if the corresponding key does not exist.

  static Future<Key?> getIndividualKey(String resourceUrl) async {
    return await IndividualKeyManager.getIndividualKey(
      resourceUrl,
      await getMasterKey(),
    );
  }

  /// Add the (encrypted) individual key for file.

  static Future<void> addIndividualKey({
    required String resourcePath,
    required Key indKey,
    bool isFile = true,
  }) async {
    await IndividualKeyManager.addIndividualKey(
      resourcePath: resourcePath,
      indKey: indKey,
      masterKey: await getMasterKey(),
      isFile: isFile,
    );
  }

  /// Remove the (encrypted) individual key for file.

  static Future<void> removeIndividualKey({
    required String resourcePath,
    bool isFile = true,
  }) async {
    await IndividualKeyManager.removeIndividualKey(
      resourcePath: resourcePath,
      isFile: isFile,
    );
  }

  /// Retrieve the (decrypted) individual key for a shared encrypted resource.
  ///
  /// Return null if the corresponding key does not exist.

  static Future<Key?> getSharedIndividualKey(String resourceUrl) async {
    return await SharedKeyManager.getSharedIndividualKey(
      resourceUrl,
      await getPrivateKey(),
    );
  }

  /// Remove the (encrypted) shared individual key for file.

  static Future<void> removeSharedIndividualKey(String resourceUrl) async {
    await SharedKeyManager.removeSharedIndividualKey(resourceUrl);
  }
}
