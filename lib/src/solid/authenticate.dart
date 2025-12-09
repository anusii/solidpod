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

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';

import 'package:solid_auth/solid_auth.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/misc.dart' 
    show checkLoggedIn, logoutPod;
import 'package:solidpod/src/solid/utils/web_reload_stub.dart'
    if (dart.library.html) 'package:solidpod/src/solid/utils/web_reload_web.dart'
    as web_reload;

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
/// Return a list containing authentication data: user's webId; profile data.
///
/// Error Handling: The function has a catch all to return null if any exception
/// occurs during the authentication process.

Future<List<dynamic>?> solidAuthenticate(
  String serverId,
  BuildContext context,
) async {
  try {
    final loggedIn = await checkLoggedIn();
    //debugPrint('solidAuthenticate() => checkLoggedIn() => $loggedIn');
    Map<dynamic, dynamic>? authData;
    if (loggedIn) {
      authData = await AuthDataManager.loadAuthData();
      if (authData == null) {
        debugPrint('solidAuthenticate() => checkLoggedIn() returned true but loadAuthData() returned null, re-authenticating');
        // Fall through to re-authenticate
      }
    }

    // If not logged in or load failed, perform new authentication
    if (!loggedIn || authData == null) {
      // On web platform, when guest user clicks to login, reload page to reset state
      // This takes them back to homepage where they can properly authenticate
      if (kIsWeb) {
        debugPrint('solidAuthenticate() => Guest user requesting login, reloading page...');
        await Future.delayed(const Duration(milliseconds: 100));
        web_reload.reloadPage();
        // Code after reloadPage() won't execute
        return null;
      }
      
      debugPrint('solidAuthenticate() => solid_auth.authenticate($serverId)');
      // Authentication process for the POD issuer.

      final issuerUri = await getIssuer(serverId);
      authData = await authenticate(Uri.parse(issuerUri), _scopes, context);

      // Validate authentication response before saving
      if (authData.isEmpty) {
        debugPrint('solidAuthenticate() => Authentication returned empty response');
        return null;
      }

      if (authData.containsKey('error')) {
        debugPrint('solidAuthenticate() => Authentication error: ${authData['error']}');
        return null;
      }

      // Validate that required authentication fields are present
      if (!authData.containsKey('accessToken') || authData['accessToken'] == null) {
        debugPrint('solidAuthenticate() => Missing accessToken in authentication response');
        return null;
      }

      // Let saveAuthData() decode the JWT and extract webId
      // If webId extraction fails, saveAuthData() will handle it and skip saving
      await AuthDataManager.saveAuthData(authData);

      // Verify that webId was successfully extracted and saved
      final webId = await AuthDataManager.getWebId();
      if (webId == null || webId.isEmpty) {
        debugPrint('solidAuthenticate() => Failed to extract webId from JWT token');
        return null;
      }

      // Proceed to fetch profile data with the authenticated credentials
      if (authData.containsKey('error')) {
        debugPrint('solidAuthenticate() => Authentication returned error: ${authData['error']}');
        return null;
      }

      final profCardUrl = webId.replaceAll('#me', '');
      final profData = await fetchPrvFile(profCardUrl);

      return [authData, webId, profData];
    }

    // Already logged in successfully - fetch profile data
    final webId = await AuthDataManager.getWebId();
    if (webId == null || webId.isEmpty) {
      debugPrint('solidAuthenticate() => No valid webId found, logging out');
      await logoutPod();
      return null;
    }

    final profCardUrl = webId.replaceAll('#me', '');
    final profData = await fetchPrvFile(profCardUrl);

    return [authData, webId, profData];
  } on Exception catch (e) {
    debugPrint('Solid Authenticate Failed: $e');
    return null;
  }
}
