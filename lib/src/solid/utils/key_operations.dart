/// Key file operations for loading and saving encryption keys.
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

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Manages file operations for encryption keys.

class KeyOperations {
  // URL of the file with verification key and encrypted private key.

  static String? _encKeyUrl;

  // URL of the file with public key.

  static String? _pubKeyUrl;

  // The verification key.

  static String? _verificationKey;

  // The public key.

  static String? _pubKey;

  // The encrypted (and decrypted) private key.

  static PrvKeyRecord? _prvKeyRecord;

  // The base64 key-derivation salt (null on legacy version 1 PODs).

  static String? _saltB64;

  // The key-derivation scheme version (1 = legacy).

  static int? _keyVersion;

  /// Clear all cached key data.

  static void clear() {
    _encKeyUrl = null;
    _pubKeyUrl = null;
    _verificationKey = null;
    _pubKey = null;
    _prvKeyRecord = null;
    _saltB64 = null;
    _keyVersion = null;
  }

  /// Load verification key and encrypted private key.

  static Future<void> loadEncryptionKey({bool forceReload = false}) async {
    try {
      if (_verificationKey != null && _prvKeyRecord != null && !forceReload) {
        return;
      }

      // Check if user is logged in before attempting to load encryption keys.

      final authData = await AuthDataManager.loadAuthData();
      if (authData == null) {
        throw Exception(
          'Cannot load encryption keys: User is not logged in. '
          'Please login first to access encrypted resources.',
        );
      }

      final r = await readEncKeyFile();
      _verificationKey = r.verificationKey;
      _prvKeyRecord = r.record;
      _saltB64 = r.saltB64;
      _keyVersion = r.version;
    } catch (e) {
      // Log only the exception type, never `$e`: this path handles encryption
      // key material (finding M1).
      debugPrint(
        'KeyOperations => loadEncryptionKey() error: ${e.runtimeType}',
      );
      rethrow;
    }
  }

  /// Generate the content of encKeyFile and save it (on server).

  static Future<void> saveEncryptionKey(
    String verificationKey,
    PrvKeyRecord prvKeyRecord, {
    String? saltB64,
    int? version,
  }) async {
    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    await createResource(
      _encKeyUrl!,
      content: await genEncKeyTTLStr(
        _encKeyUrl!,
        verificationKey,
        prvKeyRecord,
        saltB64: saltB64,
        version: version,
      ),
    );

    // Keep the cache consistent with what was just persisted.

    _saltB64 = saltB64;
    _keyVersion = version;
  }

  /// Load the public key.

  static Future<void> loadPublicKey({bool forceReload = false}) async {
    if (_pubKey != null && !forceReload) {
      return;
    }

    _pubKey = await readPubKeyFile();
  }

  /// Generate the content of pubKeyFile and save it (on server).

  static Future<void> savePublicKey(String pubKey) async {
    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    await createResource(
      _pubKeyUrl!,
      content: await genPubKeyTTLStr(_pubKeyUrl!, pubKey),
    );
  }

  /// Get the cached verification key.

  static String? getVerificationKey() => _verificationKey;

  /// Get the cached base64 key-derivation salt (null on legacy PODs).

  static String? getSalt() => _saltB64;

  /// Get the cached key-derivation scheme version (null if not yet loaded).

  static int? getKeyVersion() => _keyVersion;

  /// Get the cached public key.

  static String? getPublicKey() => _pubKey;

  /// Get the cached private key record.

  static PrvKeyRecord? getPrivateKeyRecord() => _prvKeyRecord;

  /// Set the cached verification key.

  static void setVerificationKey(String key) => _verificationKey = key;

  /// Set the cached public key.

  static void setPublicKey(String key) => _pubKey = key;

  /// Set the cached private key record.

  static void setPrivateKeyRecord(PrvKeyRecord record) =>
      _prvKeyRecord = record;

  /// Clear decrypted private key from memory.

  static void clearDecryptedPrivateKey() {
    if (_prvKeyRecord != null) {
      _prvKeyRecord!.key = null;
    }
  }
}
