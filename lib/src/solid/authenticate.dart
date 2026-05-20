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

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show BuildContext;

import 'package:solid_auth/solid_auth.dart'
    show SolidAuthManager, SolidOidcConfig;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/misc.dart' show isUserLoggedIn;

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
/// [redirectUri] is the custom URL scheme for the OAuth to redirect to
/// after authentication.
///
/// [postLogoutRedirectUri]  is an optional redirect URI for logout. If not
/// set assign the same value as [redirectUri].
///
/// Returns `[SolidAuthData, webId, profileTurtle]` on success, null on failure.
Future<List<dynamic>?> solidAuthenticate(
  String serverId,
  BuildContext context, {
  required String clientId,
  required String redirectUri,
  String? postLogoutRedirectUri,
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

    // Check if post logout redirect URI is set. If not use the
    // same value of redirect URI.
    postLogoutRedirectUri ??= redirectUri;

    final authManager = SolidAuthManager(
      config: SolidOidcConfig(
        clientId: clientId,
        redirectUri: Uri.parse(redirectUri),
        postLogoutRedirectUri: Uri.parse(postLogoutRedirectUri),
      ),
    );

    final solidAuthData = await authManager.authenticate(serverId);
    if (solidAuthData == null) return null;

    await AuthDataManager.saveAuthData(
      solidAuthData,
      authManager,
      oidcClientId: clientId,
      redirectUri: redirectUri.toString(),
    );

    final profData = utf8.decode(
      await getResource(solidAuthData.webId.replaceAll('#me', '')),
    );

    return [solidAuthData, solidAuthData.webId, profData];
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
