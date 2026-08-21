/// Authenticate against a Solid server using Solid-OIDC.
///
// Time-stamp: <Monday 2025-07-14 11:29:39 +1000 Graham Williams>
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
/// Authors: Zheyuan Xu, Graham Williams, Anushka Vidanage

library;

import 'dart:convert';

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart' show BuildContext;

import 'package:oidc/oidc.dart' show OidcPlatformSpecificOptions;

import 'package:solid_auth/solid_auth.dart'
    show SolidAuthManager, SolidOidcConfig;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/exceptions.dart'
    show SolidAuthCancelledException;
import 'package:solidpod/src/solid/utils/misc.dart' show isUserLoggedIn;

/// Selects the appropriate redirect URI from [uris] based on the runtime
/// platform, using the URI format (and, on web, the origin) as the
/// discriminator:
///
/// | Platform | Matched format |
/// |---|---|
/// | Web | The entry whose origin equals the app's current origin ([Uri.base]) |
/// | Android / iOS / macOS | Custom scheme URI (not `http://` or `https://`) |
/// | Desktop (Windows / Linux) | `http://localhost` loopback URI |
///
/// Falls back to the first element when no format-matched entry is found, so
/// a single-element list always returns that element unchanged.
///
/// Throws [ArgumentError] if [uris] is empty.
String pickRedirectUri(List<String> uris) {
  if (uris.isEmpty) throw ArgumentError('redirectUris must not be empty');
  if (uris.length == 1) return uris.first;

  if (kIsWeb) {
    final currentOrigin = Uri.base.origin;
    return uris.firstWhere(
      (u) {
        final parsed = Uri.tryParse(u);
        if (parsed == null) return false;
        if (!parsed.isScheme('http') && !parsed.isScheme('https')) {
          return false;
        }
        return parsed.origin == currentOrigin;
      },
      orElse: () => uris.firstWhere(
        (u) => u.startsWith('https://'),
        orElse: () => uris.first,
      ),
    );
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // Android, iOS and macOS all rely on a custom URI scheme. On macOS this
    // is required because oidc_macos uses ASWebAuthenticationSession, which
    // hands the redirect back to the app via a registered URL scheme rather
    // than via an `http://localhost` callback server.
    return uris.firstWhere(
      (u) => !u.startsWith('http://') && !u.startsWith('https://'),
      orElse: () => uris.first,
    );
  }
  // Remaining desktop targets (Windows / Linux) use the oidc_desktop
  // implementation, which starts a local loopback callback server.
  return uris.firstWhere(
    (u) => u.startsWith('http://localhost'),
    orElse: () => uris.first,
  );
}

/// Returns true while [solidAuthenticate] is awaiting the browser-based OAuth
/// flow.

// bool isSolidAuthenticatePending() => isAuthenticatePending();

/// Aborts any in-flight [solidAuthenticate] call. Delegates to
/// `solid_auth.cancelAuthenticate()` which closes the local OAuth callback
/// server and errors the pending awaiter, so this caller unwinds with a
/// [SolidAuthCancelledException].

void cancelSolidAuthenticate() {
  // unawaited(cancelAuthenticate());
}

// State cached by prewarmSolidAuthenticate() and consumed (then cleared) by
// the next solidAuthenticate() call, so long as its parameters match.
SolidAuthManager? _prewarmedManager;
String? _prewarmedServerId;
String? _prewarmedClientId;
String? _prewarmedRedirectUri;
OidcPlatformSpecificOptions? _prewarmedOidcOptions;

void _clearPrewarmedManager() {
  _prewarmedManager = null;
  _prewarmedServerId = null;
  _prewarmedClientId = null;
  _prewarmedRedirectUri = null;
  _prewarmedOidcOptions = null;
}

/// Resolves [serverId]'s issuer and initialises the underlying OIDC manager
/// ahead of time, so a later [solidAuthenticate] call with the exact same
/// [serverId], [clientId], [redirectUris], and [oidcOptions] can skip
/// straight to the browser redirect.
///
/// This exists for Safari: `window.open()` must fire within the same
/// user-gesture handling as the login button's click, but [solidAuthenticate]
/// normally awaits a WebID HTTP GET and an OIDC discovery-document GET first,
/// which pushes it past that window and gets the popup silently blocked.
/// Call this speculatively — e.g. when the login screen first shows a fixed
/// default server — so the button click reuses an already-initialised
/// manager instead. Failures are swallowed; [solidAuthenticate] will simply
/// redo the work from scratch.
Future<void> prewarmSolidAuthenticate(
  String serverId, {
  required String clientId,
  required List<String> redirectUris,
  List<String> postLogoutRedirectUris = const [],
  OidcPlatformSpecificOptions? oidcOptions,
}) async {
  if (clientId.isEmpty || redirectUris.isEmpty) return;
  try {
    if (await isUserLoggedIn()) return;

    final effectiveRedirectUri = pickRedirectUri(redirectUris);
    final effectivePostLogoutUri = postLogoutRedirectUris.isNotEmpty
        ? pickRedirectUri(postLogoutRedirectUris)
        : effectiveRedirectUri;

    final manager = SolidAuthManager(
      config: SolidOidcConfig(
        clientId: clientId,
        redirectUri: Uri.parse(effectiveRedirectUri),
        postLogoutRedirectUri: Uri.parse(effectivePostLogoutUri),
        options: oidcOptions,
      ),
    );
    await manager.prewarm(serverId);

    _prewarmedManager = manager;
    _prewarmedServerId = serverId;
    _prewarmedClientId = clientId;
    _prewarmedRedirectUri = effectiveRedirectUri;
    _prewarmedOidcOptions = oidcOptions;
  } on Object catch (e) {
    debugPrint('prewarmSolidAuthenticate() failed: $e');
  }
}

/// Asynchronously authenticate a user against a Solid server [serverId].
///
/// [serverId] is the user's WebID or an issuer URI. Issuer resolution is
/// handled internally by [SolidAuthManager].
///
/// [context] is kept for API compatibility but is no longer required by the
/// underlying Solid-OIDC flow.
///
/// [clientId] must be the URL of the app's client profile JSON-LD
/// document (or a pre-registered client ID). Required.
///
/// [redirectUris] is the preferred parameter: provide one URI per platform
/// and [pickRedirectUri] selects the correct one automatically at runtime.
/// For example:
/// ```dart
/// redirectUris: [
///   'https://your-domain/redirect.html',  // web
///   'com.example.app://redirect',          // android / ios / macOS
///   'http://localhost:4400/redirect',      // desktop (Windows / Linux)
/// ]
/// ```
///
/// [postLogoutRedirectUris] works the same way for the post-logout redirect.
/// Defaults to the same selection as [redirectUris] when omitted.
///
/// [oidcOptions] passes through platform-specific `package:oidc` settings.
/// On web, the default navigation mode opens a new popup/tab via
/// `window.open()`, which Safari's popup blocker silently blocks because it
/// fires after the async WebID/issuer-discovery lookups below rather than
/// synchronously within the click handler. Call [prewarmSolidAuthenticate]
/// ahead of the click to remove those awaits from this call's path instead.
///
/// `OidcPlatformSpecificOptions_Web_NavigationMode.samePage` avoids the
/// popup entirely via a full-page redirect, but the browser fully reloads
/// mid-flow, so any code awaiting this call never resumes — only pass it if
/// your caller doesn't rely on that continuation running (solidui's stock
/// widgets do, so don't set this when using them).
///
/// Returns `[SolidAuthData, webId, profileTurtle]` on success, null on failure.
Future<List<dynamic>?> solidAuthenticate(
  String serverId,
  BuildContext context, {
  required String clientId,
  required List<String> redirectUris,
  List<String> postLogoutRedirectUris = const [],
  OidcPlatformSpecificOptions? oidcOptions,
}) async {
  try {
    // Return existing session without re-authenticating.
    if (await isUserLoggedIn()) {
      final authData = await AuthDataManager.loadAuthData();
      if (authData != null) {
        final profData = utf8.decode(
          await getResource(authData.webId.replaceAll('#me', '')),
        );
        return [authData, authData.webId, profData];
      }
    }

    if (clientId.isEmpty) {
      throw Exception(
        'oidcClientId is required for Solid-OIDC authentication. '
        'Provide the URL of your app\'s client profile JSON-LD document.',
      );
    }

    // Resolve the effective redirect URI.
    final effectiveRedirectUri = pickRedirectUri(redirectUris);

    if (effectiveRedirectUri.isEmpty) {
      throw ArgumentError(
        'A redirect URI is required. Provide at least one URI via redirectUris.',
      );
    }

    // Resolve the post-logout URI the same way; default to the redirect URI.
    final effectivePostLogoutUri = postLogoutRedirectUris.isNotEmpty
        ? pickRedirectUri(postLogoutRedirectUris)
        : effectiveRedirectUri;

    // Reuse the manager warmed up by prewarmSolidAuthenticate() when it
    // matches this call's parameters — that's what lets the redirect below
    // fire without first re-running the WebID lookup and discovery fetch.
    final authManager = (_prewarmedManager != null &&
            _prewarmedServerId == serverId &&
            _prewarmedClientId == clientId &&
            _prewarmedRedirectUri == effectiveRedirectUri &&
            _prewarmedOidcOptions == oidcOptions)
        ? _prewarmedManager!
        : SolidAuthManager(
            config: SolidOidcConfig(
              clientId: clientId,
              redirectUri: Uri.parse(effectiveRedirectUri),
              postLogoutRedirectUri: Uri.parse(effectivePostLogoutUri),
              options: oidcOptions,
            ),
          );
    _clearPrewarmedManager();

    final solidAuthData = await authManager.authenticate(serverId);
    if (solidAuthData == null) return null;

    await AuthDataManager.saveAuthData(
      solidAuthData,
      authManager,
      oidcClientId: clientId,
      redirectUri: effectiveRedirectUri,
    );

    final profData = utf8.decode(
      await getResource(solidAuthData.webId.replaceAll('#me', '')),
    );

    return [solidAuthData, solidAuthData.webId, profData];
    // return [authData, webId, profData];
    // } on AuthCancelledException catch (e) {
    //   throw SolidAuthCancelledException(e.message);
  } on Object catch (e) {
    debugPrint('Solid Authenticate Failed: $e');
    return null;
  }
}

/// Silently restores a previously saved login session without browser interaction.
///
/// Returns `[SolidAuthData, webId, profileTurtle]` if a valid persisted session
/// is found, or `null` if there is no session or it cannot be restored.
///
/// Unlike [solidAuthenticate], this never opens a browser window. Use it on
/// app startup to automatically skip the login page when the user is still
/// logged in.
Future<List<dynamic>?> tryRestoreSession() async {
  try {
    final authData = await AuthDataManager.loadAuthData();
    if (authData == null) return null;

    final profData = utf8.decode(
      await getResource(authData.webId.replaceAll('#me', '')),
    );
    return [authData, authData.webId, profData];
  } on Object catch (e) {
    debugPrint('tryRestoreSession failed: $e');
    return null;
  }
}

// /// Builds the OAuth redirect URI from [appUrlScheme] or [frontendRedirectUrl].
// Uri _buildRedirectUri(String? appUrlScheme, String? frontendRedirectUrl) {
//   if (frontendRedirectUrl != null && frontendRedirectUrl.isNotEmpty) {
//     return Uri.parse(frontendRedirectUrl);
//   }
//   if (appUrlScheme != null && appUrlScheme.isNotEmpty) {
//     return Uri.parse('$appUrlScheme://callback');
//   }
//   throw Exception(
//     'Either appUrlScheme or frontendRedirectUrl must be provided '
//     'for the OAuth redirect.',
//   );
// }
