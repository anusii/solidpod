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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Manages secure storage operations for the security key.

class KeyStorage {
  // The string key for storing auth data in secure storage.

  static const String _securityKeySecureStorageKey = '_solid_security_key';

  /// Check if the security key exists in secure storage.

  static Future<bool> hasStoredSecurityKey() async {
    try {
      final key = await secureStorage.read(key: _securityKeySecureStorageKey);
      return key != null;
    } catch (e) {
      // Log only the exception type, never `$e`: this path handles the raw
      // security key and a lower-level error could echo it (finding M1).
      debugPrint(
          'KeyStorage => hasStoredSecurityKey() error: ${e.runtimeType}');
      return false;
    }
  }

  /// Read the security key from secure storage.

  static Future<String?> readSecurityKey() async {
    try {
      return await secureStorage.read(key: _securityKeySecureStorageKey);
    } catch (e) {
      debugPrint('KeyStorage => readSecurityKey() error: ${e.runtimeType}');
      return null;
    }
  }

  /// Write the security key to secure storage.

  static Future<void> writeSecurityKey(String securityKey) async {
    await writeToSecureStorage(_securityKeySecureStorageKey, securityKey);
  }

  /// Remove the security key from secure storage.
  ///
  /// This function is platform-safe:
  /// - Uses FlutterSecureStorage which is safe on all platforms including web.
  /// - Errors during deletion are logged but don't prevent function from completing.

  static Future<void> deleteSecurityKey() async {
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
