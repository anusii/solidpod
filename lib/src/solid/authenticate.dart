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
    show secureStorage, solidAuthDataSecureStorageKey;
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';

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

    // Save solid login data to secure storage

    await writeToSecureStorage(
        solidAuthDataSecureStorageKey,
        jsonEncode(SolidAuthData(
          webId,
          authData['logoutUrl'] as String,
          authData['rsaInfo'] as Map<String, dynamic>,
          authData['authResponse'] as Credential,
        )));

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

/// A model class for saving solid server auth data and refresh access token.

class SolidAuthData {
  /// Create an instance of SolidAuthData from auth data
  SolidAuthData(
    this.webId,
    this.logoutUrl,
    this.rsaInfo,
    this.authResponse,
  );

  /// The web ID of POD
  final String webId;

  /// The URL for logging out
  final String logoutUrl;

  /// The RSA keypair and their JWK format
  final Map<String, dynamic> rsaInfo;

  /// The authentication response
  Credential authResponse;

  TokenResponse? _tokenResponse;

  /// Returns the RSA keypair
  KeyPair get rsaKeyPair => rsaInfo['rsa'] as KeyPair;

  /// Returns the JWK format of the RSA public key
  dynamic get rsaPublicKeyJwk => rsaInfo['pubKeyJwk'];

  /// Returns the ID token
  IdToken get idToken => authResponse.idToken;

  /// Returns the refresh token
  String get refreshToken => authResponse.refreshToken as String;

  /// Returns the access token
  String? get accessToken {
    _tokenResponse ??=
        TokenResponse.fromJson((authResponse.response as Map).cast());
    return _tokenResponse!.accessToken;
  }

  /// Returns the expires_in duration
  Duration? get expiresIn {
    _tokenResponse ??=
        TokenResponse.fromJson((authResponse.response as Map).cast());
    return _tokenResponse!.expiresIn;
  }

  /// Refresh the access token
  Future<void> refresh([bool forceRefresh = false]) async {
    _tokenResponse = await authResponse.getTokenResponse(forceRefresh);
  }

  /// Reconstruct the map data structure returned by the solid-auth
  /// authenticate method
  Future<Map<String, dynamic>> get authData async {
    _tokenResponse ??=
        TokenResponse.fromJson((authResponse.response as Map).cast());
    return {
      'client': authResponse.client,
      'rsaInfo': rsaInfo,
      'authResponse': authResponse,
      'tokenResponse': _tokenResponse,
      'accessToken': accessToken,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'logoutUrl': logoutUrl,
    };
  }

  /// Construct a new SolidAuthData instance from a map structure
  // ignore: sort_constructors_first
  SolidAuthData.fromJson(Map<String, dynamic> json)
      : webId = json['web_id'] as String,
        logoutUrl = json['logout_url'] as String,
        rsaInfo = json['rsa_info'] as Map<String, dynamic>,
        authResponse =
            Credential.fromJson((json['auth_response'] as Map).cast());

  /// Convert a SolidAuthData instance into a map
  Map<String, dynamic> toJson() => {
        'web_id': webId,
        'logout_url': logoutUrl,
        'rsa_info': rsaInfo,
        'auth_response': authResponse.toJson(),
      };
}

/// Retrieve solid auth data from secure storage
Future<SolidAuthData?> getSolidAuthData() async {
  final authDataStr =
      await secureStorage.read(key: solidAuthDataSecureStorageKey);
  if (authDataStr != null) {
    return SolidAuthData.fromJson(
        jsonDecode(authDataStr) as Map<String, dynamic>);
  } else {
    return null;
  }
}
