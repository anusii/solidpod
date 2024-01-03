/// Solid authenticate function, return null if authenticate function fails.
///
// Time-stamp: <Tuesday 2024-01-03 10:57:15 +1100 Zheyuan Xu>
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
/// Authors: Zheyuan Xu
library;

import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid/src/constants/login.dart';
import 'package:solid/src/login/api/rest_api.dart';
import 'package:solid_auth/solid_auth.dart';

Future<List<dynamic>?> solidAuthenticate(
    String serverId, BuildContext context) async {
  try {
    final issuerUri = await getIssuer(serverId);

    // Authentication process for the POD issuer.

    // ignore: use_build_context_synchronously
    final authData = await authenticate(Uri.parse(issuerUri), scopes, context);

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

    return [authData, webId, profData];
  } on () {
    return null;
  }
}
