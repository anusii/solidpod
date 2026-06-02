/// Authentication / session-lifecycle helpers (login state, logout, tokens).
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:fast_rsa/fast_rsa.dart' show KeyPair;
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid_auth/solid_auth.dart' show genDpopToken, logout;

import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';

/// Global callback for clearing application-specific caches during logout.
/// Apps should register their cache clearing logic here.
/// This ensures caches are cleared BEFORE any blocking network operations.
Future<void> Function()? _onLogoutClearCaches;

/// Register a callback to clear application-specific caches during logout.
/// This callback will be invoked BEFORE the OAuth2 logout endpoint call,
/// preventing race conditions where cached data might be visible during logout.
void registerLogoutCacheCallback(Future<void> Function() callback) {
  _onLogoutClearCaches = callback;
}

/// Return the web ID
Future<String?> getWebId() async => AuthDataManager.getWebId();

/// Check whether a user is logged in or not
///
/// Check if the local storage has authentication
/// details of the user and also check whether the
/// access token is expired or not

Future<bool> isUserLoggedIn() async {
  final webId = await AuthDataManager.getWebId();

  if (webId != null && webId.isNotEmpty) {
    final accessToken = await AuthDataManager.getAccessToken();
    if (accessToken != null && !JwtDecoder.isExpired(accessToken)) {
      return true;
    }
  }

  return false;
}

/// Delete login information from the local storage
///
/// returns true if successful

Future<bool> deleteLogIn() async => AuthDataManager.removeAuthData();

/// Get tokens necessary to fetch a resource from a POD
///
/// returns the access token and DPoP token
Future<({String accessToken, String dPopToken})> getTokensForResource(
  String resourceUrl,
  String httpMethod,
) async {
  final authData = await AuthDataManager.loadAuthData();

  if (authData == null) {
    throw Exception('Authentication data not available. Please login first.');
  }

  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];

  return (
    accessToken: authData['accessToken'] as String,
    dPopToken: genDpopToken(resourceUrl, rsaKeyPair, publicKeyJwk, httpMethod),
  );
}

/// Logging out the user with comprehensive error handling and platform support
///
/// This function performs a complete logout that includes:
/// 1. Clearing all encryption keys from memory
/// 2. Removing authentication data from secure storage
/// 3. Calling the OAuth2 logout endpoint (with error tolerance on web)
///
/// Returns true if logout succeeds or critical operations complete,
/// false only if critical operations (key/auth cleanup) fail.
Future<bool> logoutPod() async {
  try {
    // Step 1: Clear all cached encryption keys and security data from memory
    // This is CRITICAL and must be done regardless of other failures
    await KeyManager.clear();
    debugPrint('logoutPod() => KeyManager.clear() completed');

    // Step 2: Get the logout URL before removing auth data
    final logoutUrl = await AuthDataManager.getLogoutUrl();

    // Step 3: Remove authentication data from secure storage
    // This is CRITICAL - must succeed
    final authDataRemoved = await AuthDataManager.removeAuthData();
    if (!authDataRemoved) {
      debugPrint(
        'logoutPod() => WARNING: AuthDataManager.removeAuthData() failed',
      );
      // Don't return false yet - logout endpoint is still needed
    }

    // Step 3.5: Clear application-specific caches BEFORE network call
    // This is CRITICAL to prevent race conditions where UI reads stale cache
    // during logout, especially when network is slow
    if (_onLogoutClearCaches != null) {
      try {
        await _onLogoutClearCaches!();
      } on Object catch (e) {
        debugPrint(
          'logoutPod() => WARNING: Application cache callback failed (non-critical): $e',
        );
        // Continue - the critical auth data is already cleared
      }
    } else {
      debugPrint('logoutPod() => No application cache callback registered');
    }

    // Step 4: Attempt OAuth2 logout
    // This is OPTIONAL - should not block if it fails
    if (logoutUrl != null && logoutUrl.isNotEmpty) {
      try {
        // Call the OAuth2 logout endpoint
        // On web, this may fail with platform-related exceptions, but we continue anyway
        await logout(logoutUrl);
        debugPrint('logoutPod() => OAuth2 logout endpoint called successfully');
      } on Object catch (e) {
        // On Flutter Web, platform-related exceptions might occur
        // This is NOT a critical failure - the local session is already cleared
        debugPrint('logoutPod() => OAuth2 logout warning (non-critical): $e');
        // Continue - local data is already cleared which is most important
      }
    } else {
      debugPrint(
        'logoutPod() => No logout URL available, skipping OAuth2 logout',
      );
    }

    // Success if we cleared the local data (most important part)
    return authDataRemoved;
  } on Object catch (e) {
    // Catch any remaining exceptions
    debugPrint('logoutPod() => CRITICAL ERROR: $e');
    // Even if we reach here, attempt to clear auth data as fallback
    try {
      await AuthDataManager.removeAuthData();
      await KeyManager.clear();
    } catch (fallbackError) {
      debugPrint('logoutPod() => Fallback cleanup also failed: $fallbackError');
    }
    return false;
  }
}

/// Clear all login state without opening a browser.
///
/// Performs the same cleanup as [logoutPod] but invalidates the IdP session
/// via a headless HTTP request rather than launching a visible browser
/// window. Use this when switching accounts or recovering from stale
/// credentials.

Future<bool> silentLogout() async {
  try {
    await KeyManager.clear();

    final logoutUrl = await AuthDataManager.getLogoutUrl();
    final authDataRemoved = await AuthDataManager.removeAuthData();

    if (_onLogoutClearCaches != null) {
      try {
        await _onLogoutClearCaches!();
      } on Object catch (e) {
        debugPrint('silentLogout() cache callback failed (non-critical): $e');
      }
    }

    // Best-effort IdP session invalidation via headless HTTP GET.

    if (logoutUrl != null && logoutUrl.isNotEmpty) {
      try {
        await http.get(Uri.parse(logoutUrl));
      } on Object catch (e) {
        debugPrint('silentLogout() headless logout failed (non-critical): $e');
      }
    }

    return authDataRemoved;
  } on Object catch (e) {
    debugPrint('silentLogout() CRITICAL: $e');
    try {
      await AuthDataManager.removeAuthData();
      await KeyManager.clear();
    } on Object catch (_) {}
    return false;
  }
}

/// Removes header and footer (which mess up the TTL format) from a PEM-formatted public key string.
///
/// This function takes a public key string, typically in PEM format, and removes
/// the standard PEM headers and footers.

String trimPubKeyStr(String keyStr) {
  final itemList = keyStr.split('\n');
  itemList.remove('-----BEGIN RSA PUBLIC KEY-----');
  itemList.remove('-----END RSA PUBLIC KEY-----');
  itemList.remove('-----BEGIN PUBLIC KEY-----');
  itemList.remove('-----END PUBLIC KEY-----');

  final keyStrTrimmed = itemList.join();

  return keyStrTrimmed;
}
