/// Secure storage operations for security key management.
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

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/web_secure_key_cache_stub.dart'
    if (dart.library.js_interop) 'package:solidpod/src/solid/utils/web_secure_key_cache_web.dart';

/// Manages secure storage operations for the security key.

class KeyStorage {
  // The string key for storing auth data in secure storage.

  static const String _securityKeySecureStorageKey = '_solid_security_key';

  // Session copy of the security key on web (avoids an IndexedDB round-trip on
  // every read within a session).
  //
  // Why the web path is special: plain `flutter_secure_storage` keeps its
  // AES-GCM key *unwrapped* in the same `localStorage` as the ciphertext, so a
  // same-origin script or a copy of `localStorage` recovers both — and the
  // security key derives the master key protecting every encrypted resource.
  //
  // On web we therefore cache the security key via [WebSecureKeyCache]: it is
  // encrypted under a **non-extractable** AES-GCM key held as an opaque
  // `CryptoKey` in IndexedDB. A storage dump then yields only ciphertext and a
  // key handle whose bytes can never be exported, so the key cannot be
  // recovered offline. (A live same-origin XSS can still *use* — but not
  // exfiltrate — the key; that is an inherent browser limitation, mitigated by
  // CSP/XSS prevention, not storage.) The cache survives reloads, so the user
  // is not forced to re-enter the key.
  //
  // Native platforms are unaffected: they use the OS-backed secure store
  // (Keychain / Keystore / DPAPI / libsecret) and persist as before.

  static String? _webSecurityKey;

  // Best-effort removal of any security key a previous build may have written
  // to web `localStorage`, so upgrading users do not leave the exposed value
  // behind. Never re-reads the value.

  static Future<void> _purgeLegacyWebEntry() async {
    try {
      if (await secureStorage.containsKey(key: _securityKeySecureStorageKey)) {
        await secureStorage.delete(key: _securityKeySecureStorageKey);
        debugPrint('KeyStorage => purged legacy web security key');
      }
    } on Object catch (e) {
      debugPrint(
        'KeyStorage => _purgeLegacyWebEntry() error: ${e.runtimeType}',
      );
    }
  }

  /// Check if the security key exists.
  ///
  /// On web this checks the in-memory session value and the encrypted
  /// IndexedDB cache; on native platforms it queries secure storage.

  static Future<bool> hasStoredSecurityKey() async {
    if (kIsWeb) {
      if (_webSecurityKey != null) {
        return true;
      }
      try {
        return await WebSecureKeyCache.has();
      } on Object catch (e) {
        debugPrint('KeyStorage => hasStoredSecurityKey(web) '
            'error: ${e.runtimeType}');
        return false;
      }
    }
    try {
      final key = await secureStorage.read(key: _securityKeySecureStorageKey);
      return key != null;
    } catch (e) {
      // Log only the exception type, never `$e`: this path handles the raw
      // security key and a lower-level error could echo it (finding M1).
      debugPrint(
        'KeyStorage => hasStoredSecurityKey() error: ${e.runtimeType}',
      );
      return false;
    }
  }

  /// Read the security key.
  ///
  /// On web this returns the in-memory session value, falling back to the
  /// encrypted IndexedDB cache (never a plaintext `localStorage` value); on
  /// native platforms it reads from secure storage.

  static Future<String?> readSecurityKey() async {
    if (kIsWeb) {
      if (_webSecurityKey != null) {
        return _webSecurityKey;
      }
      try {
        _webSecurityKey = await WebSecureKeyCache.read();
      } on Object catch (e) {
        // Any decode/crypto error => behave as if not cached (re-prompt).

        debugPrint(
          'KeyStorage => readSecurityKey(web) error: ${e.runtimeType}',
        );
        _webSecurityKey = null;
      }
      return _webSecurityKey;
    }
    try {
      return await secureStorage.read(key: _securityKeySecureStorageKey);
    } catch (e) {
      debugPrint(
        'KeyStorage => readSecurityKey() error: ${e.runtimeType}',
      );
      return null;
    }
  }

  /// Write the security key.
  ///
  /// On web the key is kept in memory and cached in encrypted form via
  /// [WebSecureKeyCache] (non-extractable IndexedDB key); any legacy plaintext
  /// `localStorage` copy is purged. On native platforms it is written to secure
  /// storage.

  static Future<void> writeSecurityKey(String securityKey) async {
    if (kIsWeb) {
      _webSecurityKey = securityKey;
      try {
        // Encrypted, dump-resistant persistence (survives reload).

        await WebSecureKeyCache.write(securityKey);
      } on Object catch (e) {
        // Best-effort: on failure we keep the key in memory for this session
        // only (the user re-enters it after a reload).

        debugPrint('KeyStorage => writeSecurityKey(web) '
            'cache failed: ${e.runtimeType}');
      }
      // Remove any plaintext value persisted by an earlier build.

      await _purgeLegacyWebEntry();
      return;
    }
    await writeToSecureStorage(
      _securityKeySecureStorageKey,
      securityKey,
    );
  }

  /// Remove the security key.
  ///
  /// This function is platform-safe:
  /// - On web it clears the in-memory value, deletes the encrypted IndexedDB
  ///   cache, and purges any legacy plaintext `localStorage` copy.
  /// - On native platforms it deletes from FlutterSecureStorage.
  /// - Errors during deletion are logged but don't prevent function from completing.

  static Future<void> deleteSecurityKey() async {
    if (kIsWeb) {
      _webSecurityKey = null;
      try {
        await WebSecureKeyCache.delete();
      } on Object catch (e) {
        debugPrint('KeyStorage => deleteSecurityKey(web) '
            'error: ${e.runtimeType}');
      }
      await _purgeLegacyWebEntry();
      return;
    }
    try {
      if (await secureStorage.containsKey(key: _securityKeySecureStorageKey)) {
        try {
          await secureStorage.delete(key: _securityKeySecureStorageKey);
          debugPrint(
            'KeyStorage => deleteSecurityKey() removed from secure storage',
          );
        } on Object catch (e) {
          debugPrint(
            'KeyStorage => deleteSecurityKey() deletion failed '
            '(non-critical): ${e.runtimeType}',
          );
        }
      }
    } on Object catch (e) {
      debugPrint(
        'KeyStorage => deleteSecurityKey() unexpected error: ${e.runtimeType}',
      );
    }
  }
}
