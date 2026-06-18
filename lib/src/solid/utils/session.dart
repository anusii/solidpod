/// Authentication session and lifecycle helpers (login state,
/// logout flows, token issuance).
///
// Time-stamp: <Thursday 2026-01-22 11:12:44 +1100 Graham Williams>
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

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid_auth/solid_auth.dart' show DpopTokenGenerator;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/app_info.dart';
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

/// Extract the app name and the version from the package info
/// Return a record (with named fields https://dart.dev/language/records).

Future<({String name, String version})> getAppNameVersion() async =>
    (name: await AppInfo.name, version: await AppInfo.version);

/// Return the web ID.

Future<String?> getWebId() async => AuthDataManager.getWebId();

/// Whether [ownerWebId] refers to a POD other than the current user's.
///
/// Returns true when [ownerWebId] is non-null and differs from the logged-in
/// user's WebID — i.e. when an operation should be routed to the external-POD
/// code path. Returns false when [ownerWebId] is null or names the current
/// user's own POD.
///
/// Shared by the read/write/delete entry points so that the "own POD vs
/// external POD" decision is made consistently in a single place.

Future<bool> isExternalOwner(String? ownerWebId) async =>
    ownerWebId != null && ownerWebId != await getWebId();

/// Resolve [ownerWebId] to the WebID to use for external-POD operations.
///
/// Returns [ownerWebId] when it names another user's POD (see
/// [isExternalOwner]), or null when the operation targets the current user's
/// own POD. The returned value is suitable for passing as the `webId`
/// argument of URL-resolution helpers, which treat null as "the current
/// user's POD".

Future<String?> resolveExternalOwner(String? ownerWebId) async =>
    await isExternalOwner(ownerWebId) ? ownerWebId : null;

/// Check whether a user is logged in or not.
///
/// Check if the local storage has authentication
/// details of the user and also check whether the
/// access token is expired or not.

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

/// Delete login information from the local storage.
///
/// returns true if successful.

Future<bool> deleteLogIn() async => AuthDataManager.removeAuthData();

/// Set directory name for the app for storing the POD data.
///
/// If not initially set the app name will be taken by default.

Future<void> setAppDirName(String inputAppDirName) async {
  if (inputAppDirName.isEmpty) {
    appDirName = await AppInfo.canonicalName;
  } else {
    appDirName = inputAppDirName;
  }
}

/// Get tokens necessary to fetch a resource from a POD.
///
/// returns the access token and DPoP token.

Future<({String accessToken, String dPopToken})> getTokensForResource(
  String resourceUrl,
  String httpMethod,
) async {
  final authData = await AuthDataManager.loadAuthData();

  if (authData == null) {
    throw Exception('Authentication data not available. Please login first.');
  }

  final authManager = AuthDataManager.getAuthManager();
  if (authManager == null) {
    throw Exception('Auth manager not available. Please login first.');
  }

  final dPopToken = await DpopTokenGenerator.generateForRequest(
    endpointUrl: resourceUrl,
    httpMethod: httpMethod,
    accessToken: authData.accessToken,
    keyManager: authManager.keyManager,
  );

  return (
    accessToken: authData.accessToken,
    dPopToken: dPopToken,
  );
}

/// Logging out the user with comprehensive error handling and platform support
///
/// This function performs a complete logout that includes:
/// 1. Clearing all encryption keys from memory
/// 2. Clearing application-specific caches
/// 3. Calling the OIDC logout endpoint via SolidAuthManager (with error tolerance)
/// 4. Removing authentication data from secure storage
///
/// Returns true if critical cleanup (key/auth data) succeeds.

Future<bool> logoutPod() async {
  try {
    await KeyManager.clear();

    // Clear app caches before any network operations to prevent race conditions.
    if (_onLogoutClearCaches != null) {
      try {
        await _onLogoutClearCaches!();
      } on Object catch (e) {
        debugPrint('logoutPod() cache callback failed (non-critical): $e');
      }
    }

    // Contact the OIDC logout endpoint and rotate the DPoP key.
    // Must be called before removeAuthData() clears _authManager.

    try {
      await AuthDataManager.getAuthManager()?.logout();
    } on Object catch (e) {
      debugPrint('logoutPod() OAuth2 logout warning (non-critical): $e');
    }

    final authDataRemoved = await AuthDataManager.removeAuthData();
    return authDataRemoved;
  } on Object catch (e) {
    debugPrint('logoutPod() CRITICAL ERROR: $e');
    try {
      await AuthDataManager.removeAuthData();
      await KeyManager.clear();
    } on Object catch (_) {}
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

    // Get logout URL from discovery doc before clearing the manager.

    String? logoutUrl;
    try {
      logoutUrl = await AuthDataManager.getLogoutUrl();
    } on Object catch (_) {}

    // Clear local token state only — no browser redirect.

    await AuthDataManager.getAuthManager()?.forgetUser();

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
