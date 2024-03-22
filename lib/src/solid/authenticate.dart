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

    // write authentication data to flutter secure storage
    await writeToSecureStorage('webid', webId);

    // Since we cannot write object data to jason and also to flutter
    // secure storage convert all data to String and save that as a jason
    // map
    final authDataTemp = Map.from(authData);

    // Removing all object like data
    authDataTemp.remove('client');
    authDataTemp.remove('authResponse');
    // authDataTemp.remove('idToken');
    authDataTemp.remove('rsaInfo');
    // authDataTemp.remove('expiresIn');

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


class AuthData {
  //TODO: add additional fields e.g. RSA keys, JWK etc.
  final String webId;
  final String clientId;
  final String clientSecret;
  final String accessToken;
  final String tokenType;
  final String refreshToken;
  final Duration expiresIn;
  final DateTime expiresAt;
  final IdToken idToken;

  AuthData(
    this.webId,
    this.clientId,
    this.clientSecret,
    this.accessToken,
    this.tokenType,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
    this.idToken,
  );

  AuthData.fromJson(Map<String, dynamic> json)
    : webId = json['web_id'] as String,
      clientId = json['client_id'] as String,
      clientSecret = json['client_secret'] as String,
      accessToken = json['access_token'] as String,
      tokenType = json['token_type'] as String,
      refreshToken = json['refresh_token'] as String,
      expiresIn = json['expires_at'] as Duration,  // TODO: convert string to duration
      expiresAt = DateTime.fromMillisecondsSinceEpoch(json['expires_in'] as int, isUtc: true),
      idToken = json['id_token'] as IdToken;  // TODO: convert string to idToken

  Map<String, dynamic> toJson() => {
    'web_id': webId,
    'client_id': clientId,
    'client_secret': clientSecret,
    'access_token': accessToken,
    'token_type': tokenType,
    'refresh_token': refreshToken,
    'expires_in': expiresIn as String,  //TODO: convert Duration to String
    'expires_at': expiresAt.millisecond,
    'id_token': idToken as String,  //TODO: convert idToken to String
  };
  

Future<TokenResponse> refreshTokens() async {

  //TODO: put this in read/write_to_secure_storage functions
  // String authDataStr = jsonEncode(authData);
  // final authDataMap = jsonDecode(authDataStr) Map<String, dynamic>;
  // final authData = AuthData.fromJson(authDataMap);

  //TODO: make use of the AuthData model class
  final webId = await getWebId();
  final authData = await getAuthData();

  final issuerUri = await getIssuer(webId as String);
  Issuer issuer = await Issuer.discover(Uri.parse(issuerUri));

  final String _clientId = authData['client_id'] as String;
  final String _clientSecret = authData['client_secret'] as String;
  var client = Client(issuer, _clientId, clientSecret: _clientSecret);

  Credential authResponse = client.createCredential(
    accessToken: authData['access_token'] as String,
    tokenType: authData['token_type'] as String,
    refreshToken: authData['refresh_token'] as String,
    expiresIn: authData['expires_in'] as Duration,
    expiresAt: authData['expires_at'] as DateTime,
    idToken: authData['id_token'] as String,
  );

  TokenResponse tokenResponse = await authResponse.getTokenResponse(true);
  return tokenResponse;
}
