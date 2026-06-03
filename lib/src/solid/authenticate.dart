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

import 'package:solid_auth/solid_auth.dart'
    show SolidAuthManager, SolidOidcConfig;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/exceptions.dart'
    show SolidAuthCancelledException;
import 'package:solidpod/src/solid/utils/misc.dart' show isUserLoggedIn;

/// Selects the appropriate redirect URI from [uris] based on the runtime
/// platform, using the URI format as the discriminator:
///
/// | Platform | Matched format |
/// |---|---|
/// | Web | `https://` URI (same-origin BroadcastChannel requirement) |
/// | Android / iOS | Custom scheme URI (not `http://` or `https://`) |
/// | Desktop (Windows / macOS / Linux) | `http://localhost` loopback URI |
///
/// Falls back to the first element when no format-matched entry is found, so
/// a single-element list always returns that element unchanged.
///
/// Throws [ArgumentError] if [uris] is empty.
String pickRedirectUri(List<String> uris) {
  if (uris.isEmpty) throw ArgumentError('redirectUris must not be empty');
  if (uris.length == 1) return uris.first;

  if (kIsWeb) {
    return uris.firstWhere(
      (u) => u.startsWith('https://'),
      orElse: () => uris.first,
    );
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    // Mobile platforms use a custom URI scheme (not http or https).
    return uris.firstWhere(
      (u) => !u.startsWith('http://') && !u.startsWith('https://'),
      orElse: () => uris.first,
    );
  }
  // Desktop: Windows / macOS / Linux use a localhost loopback URL.
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
///   'com.example.app://redirect',          // android / ios
///   'http://localhost:4400/redirect',      // desktop
/// ]
/// ```
///
/// [postLogoutRedirectUris] works the same way for the post-logout redirect.
/// Defaults to the same selection as [redirectUris] when omitted.
///
///
/// Returns `[SolidAuthData, webId, profileTurtle]` on success, null on failure.
Future<List<dynamic>?> solidAuthenticate(
  String serverId,
  BuildContext context, {
  required String clientId,
  required List<String> redirectUris,
  List<String> postLogoutRedirectUris = const [],
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

    final authManager = SolidAuthManager(
      config: SolidOidcConfig(
        clientId: clientId,
        redirectUri: Uri.parse(effectiveRedirectUri),
        postLogoutRedirectUri: Uri.parse(effectivePostLogoutUri),
      ),
    );

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
