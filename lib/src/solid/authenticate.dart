/// Authenticate against a solid server and return null if authentication fails.
///
// Time-stamp: <Friday 2024-02-16 11:07:50 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid_auth/solid_auth.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/misc.dart'
    show saveWebId, checkLoggedIn;

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
    String serverId, BuildContext context) async {
  try {
    final loggedIn = await checkLoggedIn();
    debugPrint('solidAuthenticate() => checkLoggedIn() => $loggedIn');
    Map<dynamic, dynamic>? authData;
    if (loggedIn) {
      authData = await AuthDataManager.loadAuthData();
      assert(authData != null);
    } else {
      // Authentication process for the POD issuer.
      final issuerUri = await getIssuer(serverId);
      authData = await authenticate(Uri.parse(issuerUri), _scopes, context);

      debugPrint('solidAuthenticate() => authenticate() => $authData');

      // print(authData as Map<String, dynamic>);  // this cast fails silently

      // write authentication data to flutter secure storage
      await AuthDataManager.saveAuthData(authData);
    }

    final accessToken = authData!['accessToken'].toString();
    final decodedToken = JwtDecoder.decode(accessToken);
    final webId = decodedToken['webid'].toString();

    await saveWebId(webId);

    // final rsaInfo = authData['rsaInfo'];
    // final rsaKeyPair = rsaInfo['rsa'];
    // final publicKeyJwk = rsaInfo['pubKeyJwk'];
    final profCardUrl = webId.replaceAll('#me', '');

    // final dPopToken =
    //     genDpopToken(profCardUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'GET');

    final profData = await fetchPrvFile(profCardUrl);

    return [authData, webId, profData];
  } on Exception catch (e) {
    debugPrint('Solid Authenticate Failed: $e');
    return null;
  }
}
