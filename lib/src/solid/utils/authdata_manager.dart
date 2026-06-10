/// Manages authentication state for Solid-OIDC sessions.
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

import 'dart:convert' show jsonEncode, jsonDecode;

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:solid_auth/solid_auth.dart'
    show SolidAuthData, SolidAuthManager, SolidOidcConfig;

import 'package:solidpod/src/solid/constants/common.dart' show secureStorage;
import 'package:solidpod/src/solid/utils/misc.dart' show writeToSecureStorage;

/// Global auth state notifier for reactive UI updates.
/// Listen to this to get notified when login/logout happens.
final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

/// [AuthDataManager] manages the Solid-OIDC authentication session:
/// - persists enough config to restore [SolidAuthManager] across app restarts
/// - caches auth data in memory to avoid repeated secure-storage reads
/// - delegates token refresh and logout to [SolidAuthManager]

class AuthDataManager {
  /// In-memory [SolidAuthManager] for the active session.
  static SolidAuthManager? _authManager;

  /// Cached webId for fast access without loading the full session.
  static String? _webId;

  /// Secure-storage key for the session config needed to recreate [SolidAuthManager].
  static const String _authDataSecureStorageKey = '_solid_auth_data';

  /// Save auth data after a successful login.
  ///
  /// Stores [authData] and [authManager] in memory, and persists [oidcClientId]
  /// and [redirectUri] to secure storage so [SolidAuthManager] can be
  /// reconstructed on app restart. DPoP key pair and OIDC tokens are persisted
  /// by [SolidAuthManager] internally via [SolidAuthSessionStore].
  static Future<void> saveAuthData(
    SolidAuthData authData,
    SolidAuthManager authManager, {
    String? oidcClientId,
    String? redirectUri,
  }) async {
    _authManager = authManager;
    _webId = authData.webId;

    // Persist only the config needed to reconstruct SolidAuthManager on restart.
    // DPoP key pair and OIDC tokens are persisted by solid_auth internally via
    // SolidAuthSessionStore (called automatically inside SolidAuthManager.login()).
    await writeToSecureStorage(
      _authDataSecureStorageKey,
      jsonEncode({
        'web_id': authData.webId,
        'oidc_client_id': oidcClientId ?? '',
        'redirect_uri': redirectUri ?? '',
      }),
    );

    authStateNotifier.value = true;
  }

  /// Returns current [SolidAuthData], refreshing the token if expired.
  ///
  /// If no in-memory manager exists, attempts to restore the session from
  /// secure storage using [SolidAuthManager.initForIssuer].  Returns null
  /// when the session cannot be restored (forces re-login).
  static Future<SolidAuthData?> loadAuthData() async {
    // Check if live manager already in memory.
    if (_authManager != null) {
      return _getRefreshedAuthData(_authManager!);
    }

    // Slow path: try to restore from secure storage.
    final dataStr = await secureStorage.read(key: _authDataSecureStorageKey);
    if (dataStr == null) return null;

    try {
      final dataMap = jsonDecode(dataStr) as Map<String, dynamic>;
      final storedClientId = dataMap['oidc_client_id'] as String? ?? '';
      final storedRedirectUri = dataMap['redirect_uri'] as String? ?? '';
      _webId = dataMap['web_id'] as String?;

      if (storedClientId.isEmpty || storedRedirectUri.isEmpty) {
        return null;
      }

      final restoredManager = SolidAuthManager(
        config: SolidOidcConfig(
          clientId: storedClientId,
          redirectUri: Uri.parse(storedRedirectUri),
        ),
      );

      // Delegate to solid_auth's tryRestoreSession(), which handles:
      //   1. Loading the stored issuer, scopes, and DPoP key pair PEMs from
      //      SolidAuthSessionStore (persisted at login time).
      //   2. Restoring the DpopKeyManager singleton with the original key pair
      //      so proofs still match the cnf.jkt in the stored access token.
      //   3. Calling initForIssuer() → OidcUserManager.init() which reloads
      //      and transparently refreshes the OIDC tokens if needed.
      final authData = await restoredManager.tryRestoreSession();
      if (authData != null) {
        _authManager = restoredManager;
        _webId = authData.webId;
        authStateNotifier.value = true;
      }

      return authData;
    } on Object {
      return null;
    }
  }

  /// Clears cached state and removes persisted config from secure storage.
  ///
  /// Does NOT contact the IdP — call [getAuthManager]?.logout() or
  /// [getAuthManager]?.forgetUser() before this if needed.
  static Future<bool> removeAuthData() async {
    try {
      _authManager = null;
      _webId = null;

      if (await secureStorage.containsKey(key: _authDataSecureStorageKey)) {
        await secureStorage.delete(key: _authDataSecureStorageKey);
      }

      authStateNotifier.value = false;
      return true;
    } on Object {
      return false;
    }
  }

  /// Returns the current (refreshed if expired) access token, or null.
  static Future<String?> getAccessToken() async {
    final authData = await loadAuthData();
    return authData?.accessToken;
  }

  /// Returns the cached WebID, falling back to secure storage.
  static Future<String?> getWebId() async {
    if (_webId != null) return _webId;

    final dataStr = await secureStorage.read(key: _authDataSecureStorageKey);
    if (dataStr != null) {
      try {
        final dataMap = jsonDecode(dataStr) as Map<String, dynamic>;
        _webId = dataMap['web_id'] as String?;
      } on Object {
        _webId = null;
      }
    }
    return _webId;
  }

  /// Returns the logout endpoint URI from the OIDC discovery document, or null.
  ///
  /// Provided for backwards compatibility. Prefer calling
  /// [getAuthManager]?.logout() directly.
  static Future<String?> getLogoutUrl() async {
    try {
      return _authManager?.oidcManager.discoveryDocument.endSessionEndpoint
          ?.toString();
    } on Object {
      return null;
    }
  }

  /// Exposes the live [SolidAuthManager] for DPoP proof generation and logout.
  static SolidAuthManager? getAuthManager() => _authManager;

  /// Buffer before actual token expiry within which we proactively refresh.
  ///
  /// Refreshing slightly early avoids sending a token that expires mid-flight
  /// and guards against minor client/server clock skew that would otherwise
  /// produce a 401 on an apparently-valid token.
  static const Duration _refreshBuffer = Duration(minutes: 2);

  /// Returns [SolidAuthData] from [manager], refreshing the token if it is
  /// expired or about to expire.
  ///
  /// We do not rely solely on `package:oidc`'s background refresh timer: that
  /// timer is a foreground Dart [Timer] scheduled shortly before expiry and is
  /// suspended while the app is backgrounded, so a token can be stale by the
  /// time the user resumes. Checking the real expiry here (and refreshing
  /// within [_refreshBuffer]) ensures every resource request uses a live token.
  static Future<SolidAuthData?> _getRefreshedAuthData(
    SolidAuthManager manager,
  ) async {
    try {
      var authData = manager.currentAuthData;

      final needsRefresh = authData == null ||
          DateTime.now().add(_refreshBuffer).isAfter(authData.expiresAt);

      if (needsRefresh) {
        // Fall back to the existing (possibly stale) data if the refresh
        // returns null, e.g. when no refresh token is available.
        authData = await manager.refreshToken() ?? authData;
      }
      return authData;
    } on Object {
      return null;
    }
  }
}
