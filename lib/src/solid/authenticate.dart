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

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:fast_rsa/fast_rsa.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:solid_auth/solid_auth.dart';
import 'package:solid_auth/src/openid/openid_client.dart';

import 'package:solidpod/src/solid/constants.dart'
    show secureStorage, SOLID_AUTH_DATA_SECURE_STORE_KEY;
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';

// Scopes variables used in the authentication process.

final List<String> _scopes = <String>[
  'openid',
  'profile',
  'offline_access',
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
    final issuerUri = await getIssuer(serverId);

    // Authentication process for the POD issuer.

    // ignore: use_build_context_synchronously
    final authData = await authenticate(Uri.parse(issuerUri), _scopes, context);

    final accessToken = authData['accessToken'].toString();
    final decodedToken = JwtDecoder.decode(accessToken);
    final webId = decodedToken['webid'].toString();

    final rsaInfo = authData['rsaInfo'];
    final rsaKeyPair = rsaInfo['rsa'];
    final publicKeyJwk = rsaInfo['pubKeyJwk'];
    final profCardUrl = webId.replaceAll('#me', '');

    final dPopToken =
        genDpopToken(profCardUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'GET');

    final profData = await fetchPrvFile(profCardUrl, accessToken, dPopToken);

    await writeToSecureStorage(
        SOLID_AUTH_DATA_SECURE_STORE_KEY,
        jsonEncode(SolidAuthData(
          rsaKeyPair.publicKey,
          rsaKeyPair.privateKey,
          authData['logoutUrl'] as String,
          webId,
          authData['authResponse'] as Credential,
        )));

    // write authentication data to flutter secure storage
    await writeToSecureStorage('webid', webId);

    // Since we cannot write object data to jason and also to flutter
    // secure storage convert all data to String and save that as a jason
    // map
    final authDataTemp = Map.from(authData);

    // Removing all object like data
    authDataTemp.remove('client');
    authDataTemp.remove('authResponse');
    authDataTemp.remove('idToken');
    authDataTemp.remove('rsaInfo');
    authDataTemp.remove('expiresIn');

    // Creating new fields for public/private key pair so that can be used
    // to get data from and to POD
    final rsaInfoTemp = Map.from(rsaInfo as Map);
    rsaInfoTemp.remove('rsa');
    rsaInfoTemp['rsa'] = keyPairToMap(rsaKeyPair);
    authDataTemp['rsaInfo'] = rsaInfoTemp;

    // json encode data
    final authDataStr = json.encode(authDataTemp);
    await writeToSecureStorage('authdata', authDataStr);

    return [authData, webId, profData];
    // TODO 20240108 gjw WHY DOES THIS RESULT IN
    // avoid_catches_without_on_clauses CONTRAVENTION? IT SEEMS TO WANT AN ON
    // CLAUSE YET COMPLAINS WHEN ADD ONE IN SINCE THE catch (e) IS A CATCHLL?
    //
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    debugPrint('Solid Authenticate Failed: $e');
    return null;
  }
}

class SolidAuthData {
  final String rsaPublicKey;
  final String rsaPrivateKey;
  final String logoutUrl;
  final String webId;

  Credential authResponse;
  TokenResponse? _tokenResponse;

  SolidAuthData(
    this.rsaPublicKey,
    this.rsaPrivateKey,
    this.logoutUrl,
    this.webId,
    this.authResponse,
  );

  KeyPair get rsaKeyPair => KeyPair(rsaPublicKey, rsaPrivateKey);
  IdToken get idToken => authResponse.idToken;
  String get refreshToken => authResponse.refreshToken as String;

  String? get accessToken {
    _tokenResponse ??=
        TokenResponse.fromJson((authResponse.response as Map).cast());
    return _tokenResponse!.accessToken;
  }

  Duration? get expiresIn {
    _tokenResponse ??=
        TokenResponse.fromJson((authResponse.response as Map).cast());
    return _tokenResponse!.expiresIn;
  }

  Future<void> refreshTokens() async {
    _tokenResponse = await authResponse.getTokenResponse();
  }

  SolidAuthData.fromJson(Map<String, dynamic> json)
      : rsaPublicKey = json['rsa_public_key'] as String,
        rsaPrivateKey = json['rsa_private_key'] as String,
        logoutUrl = json['logout_url'] as String,
        webId = json['web_id'] as String,
        authResponse =
            Credential.fromJson((json['auth_response'] as Map).cast());

  Map<String, dynamic> toJson() => {
        'rsa_public_key': rsaPublicKey,
        'rsa_private_key': rsaPrivateKey,
        'logout_url': logoutUrl,
        'web_id': webId,
        'auth_response': authResponse.toJson(),
      };
}

Future<SolidAuthData?> loadSolidAuthData() async {
  final authDataStr =
      await secureStorage.read(key: SOLID_AUTH_DATA_SECURE_STORE_KEY);
  if (authDataStr != null) {
    return SolidAuthData.fromJson(
        jsonDecode(authDataStr) as Map<String, dynamic>);
  } else {
    return null;
  }
}
