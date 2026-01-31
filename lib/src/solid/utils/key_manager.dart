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

import 'package:solidpod/src/solid/utils/authdata_manager.dart';
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

  /// Remove stored security key and set all cached private members to null.

  static Future<void> clear() async {
    try {
      // Remove security key from storage and memory.

      await forgetSecurityKey();

      // Clear sensitive key material from memory.

      _securityKey = null;
      _masterKey = null;

      // Clear all sub-managers.

      KeyOperations.clear();
      IndividualKeyManager.clear();
      SharedKeyManager.clear();

      debugPrint(
        'KeyManager => clear() completed - all sensitive data cleared',
      );
    } on Object catch (e) {
      debugPrint('KeyManager => clear() error during clearing: $e');

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
          'KeyManager => clear() fallback also failed: $fallbackError',
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
      _masterKey = genMasterKey(_securityKey!);
      final verificationKey = genVerificationKey(_securityKey!);

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

      await KeyOperations.saveEncryptionKey(verificationKey, prvKeyRecord);
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
      debugPrint('KeyManager => initPodKeys() error: $e');

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

      if (!verifySecurityKey(_securityKey!, await getVerificationKey())) {
        await forgetSecurityKey();
        throw Exception('Unable to verify the security key!');
      }

      _masterKey = genMasterKey(_securityKey!);
    }

    return _masterKey!;
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

      final verificationKey = await getVerificationKey();

      if (!verifySecurityKey(_securityKey!, verificationKey)) {
        await forgetSecurityKey();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('KeyManager => hasSecurityKey() error: $e');

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

    if (!verifySecurityKey(securityKey, await getVerificationKey())) {
      throw Exception('Unable to verify the provided security key!');
    }

    _securityKey = securityKey;
    _masterKey = genMasterKey(_securityKey!);

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
      debugPrint('KeyManager => forgetSecurityKey() unexpected error: $e');

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
          'KeyManager => forgetSecurityKey() fallback also failed: $fallbackError',
        );
      }
    }
  }

  /// Change the security key and update encKeyFile and indKeyFile in POD.

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
    final oldMasterKey = genMasterKey(_securityKey!);
    _masterKey = oldMasterKey;

    // Load and decrypt keys using old master key.

    await KeyOperations.loadEncryptionKey();
    await IndividualKeyManager.loadIndividualKeys();

    // Decrypt private key.

    var prvKeyRecord = KeyOperations.getPrivateKeyRecord();
    assert(prvKeyRecord != null);
    prvKeyRecord!.key ??= await getPrivateKey();

    // Set the new security key, master key, and verification key.

    _securityKey = newSecurityKey;
    _masterKey = genMasterKey(_securityKey!);
    final newVerificationKey = genVerificationKey(_securityKey!);

    // Encrypt the private key using the new master key (and new IV).

    final iv = genRandIV();
    prvKeyRecord.ivBase64 = iv.base64;
    prvKeyRecord.encKeyBase64 =
        encryptPrivateKey(prvKeyRecord.key!, _masterKey!, iv);

    // Save re-encrypted encryption keys.

    await KeyOperations.saveEncryptionKey(newVerificationKey, prvKeyRecord);
    KeyOperations.setVerificationKey(newVerificationKey);
    KeyOperations.setPrivateKeyRecord(prvKeyRecord);

    // Re-encrypt individual keys with new master key.

    await IndividualKeyManager.reEncryptIndividualKeys(
      oldMasterKey,
      _masterKey!,
    );

    // Save security key to local secure storage.

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
