/// Authenticate against a solid server and return null if authentication fails.
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
/// Authors: Zheyuan Xu, Graham Williams

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solid_auth/solid_auth.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/misc.dart'
    show isUserLoggedIn, logoutPod;

// Scopes variables used in the authentication process.

final List<String> _scopes = <String>[
  'openid',
  'profile',
  'offline_access',
  'webid', // web ID is necessary to get refresh token
];

/// Asynchronously authenticate a user against a Solid server [serverId].
///
/// [serverId] is an issuer URI and is essential for the
/// authentication process with the POD (Personal Online Datastore) issuer.
///
/// [context] of the current widget is required for the authenticate process.
///
/// [wasAlreadyLoggedIn] is an optional pre-computed login status. When provided
/// it avoids a redundant call to [isUserLoggedIn] (and the associated secure
/// storage read + token-expiry check) that the caller may have already done.
///
/// Return a list containing authentication data: user's webId; profile data.
///
/// Error Handling: The function has a catch all to return null if any exception
/// occurs during the authentication process.

Future<List<dynamic>?> solidAuthenticate(
  String serverId,
  BuildContext context, {
  bool? wasAlreadyLoggedIn,
}) async {
  try {
    // Use the caller-supplied value when available to avoid a redundant
    // isUserLoggedIn() call (secure storage read + possible token refresh).
    final loggedIn = wasAlreadyLoggedIn ?? await isUserLoggedIn();
    Map<dynamic, dynamic>? authData;
    if (loggedIn) {
      authData = await AuthDataManager.loadAuthData();
      // authData == null means refresh failed; fall through to re-authenticate
    }

    // If not logged in or load failed, perform new authentication
    if (!loggedIn || authData == null) {
      debugPrint('solidAuthenticate() => solid_auth.authenticate($serverId)');
      // Authentication process for the POD issuer.

      final issuerUri = await getIssuer(serverId);
      authData = await authenticate(Uri.parse(issuerUri), _scopes, context);

      // Validate authentication response before saving
      if (authData.isEmpty) {
        return null;
      }

      if (authData.containsKey('error')) {
        return null;
      }

      // Validate that required authentication fields are present
      if (!authData.containsKey('accessToken') ||
          authData['accessToken'] == null) {
        return null;
      }

      // Let saveAuthData() decode the JWT and extract webId
      // If webId extraction fails, saveAuthData() will handle it and skip saving
      await AuthDataManager.saveAuthData(authData);

      // Verify that webId was successfully extracted and saved
      final webId = await AuthDataManager.getWebId();
      if (webId == null || webId.isEmpty) {
        return null;
      }

      // Fetch profile data. When the user entered a WebID URL (profile/card#me)
      // as the server ID, [getIssuer] already fetched the profile document to
      // extract the OIDC issuer URI. Reuse that cached body to avoid a second
      // HTTP GET to the same URL.
      final profCardUrl = webId.replaceAll('#me', '');
      var profData = getCachedIssuerProfileBody(profCardUrl);
      // If the issuer was resolved from a plain URI (not a WebID profile URL),
      // the profile body was not pre-fetched. Fetch it now with the
      // authenticated access token.
      profData ??= utf8.decode(await getResource(profCardUrl));
      AuthDataManager.setCachedProfData(profData);

      return [authData, webId, profData];
    }

    // Already logged in successfully - return cached or freshly-fetched profile.
    final webId = await AuthDataManager.getWebId();
    if (webId == null || webId.isEmpty) {
      await logoutPod();
      return null;
    }

    // Use the in-memory profile cache to avoid an unnecessary HTTP request on
    // every cached-session login.
    final profCardUrl = webId.replaceAll('#me', '');
    var profData = AuthDataManager.getCachedProfData();
    if (profData == null) {
      profData = utf8.decode(await getResource(profCardUrl));
      AuthDataManager.setCachedProfData(profData);
    }

    return [authData, webId, profData];
  } on Object catch (e) {
    debugPrint('Solid Authenticate Failed: $e');
    return null;
  }
}
