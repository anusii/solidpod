/// A widget to view private data in a POD.
///
// Time-stamp: <Monday 2024-03-04 15:45:47 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage

import 'dart:convert';

//import 'package:encrypt/encrypt.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A widget to show the user all the encryption keys stored in their POD.

class ShowKeys extends StatefulWidget {
  /// Parameters for getting the keys from Solid POD.

  const ShowKeys({
    super.key,
  });

  @override
  State<ShowKeys> createState() => _ShowKeysState();
}

class _ShowKeysState extends State<ShowKeys> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static Future? _asyncDataFetch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: FutureBuilder(

          /// fetchSurveyData need to create method fetchHealthData
          future: _asyncDataFetch,
          builder: (context, snapshot) {
            Widget returnVal;
            if (snapshot.connectionState == ConnectionState.done) {
              returnVal = _loadedScreen(snapshot.data as String);
            } else {
              returnVal = loadingScreen(200);
            }
            return returnVal;
          }),
    );
  }

  @override
  void initState() {
    _asyncDataFetch = _fetchKeyData();
    super.initState();
  }

  Future<String> _fetchKeyData() async {
    final webId = await secureStorage.read(key: 'webid');
    final authDataStr = await secureStorage.read(key: 'authdata');
    final authData = jsonDecode(authDataStr!);
    final rsaInfo = authData['rsaInfo'];
    final rsaKeyPair = KeyPair(
        rsaInfo['publicKey'] as String, rsaInfo['privateKey'] as String);
    final publicKeyJwk = rsaInfo['pubKeyJwk'];
    final accessToken = authData['accessToken'];
    final keyFileUrl =
        webId!.replaceAll(profCard, 'keypod/$encDir/$encKeyFile');
    final dPopTokenKey =
        genDpopToken(keyFileUrl, rsaKeyPair, publicKeyJwk, 'GET');

    final keyData = await fetchPrvFile(
      keyFileUrl,
      accessToken as String,
      dPopTokenKey,
    );

    return keyData;
  }

  Widget _loadedScreen(String keyData) {
    final encFileData = getFileContent(keyData);

    //TODO av-20240319: Need to get the encryption key
    // to decrypt the private key value

    // encKey = secureStorage.read(key: 'key')

    // final keyMaster = Key.fromUtf8(encKey);
    // final ivInd = IV.fromBase64(encFileData['iv'][1] as String);
    // final encrypterKey =
    //     Encrypter(AES(keyMaster, mode: AESMode.cbc));

    // final eccKey = Encrypted.from64(medFileKey);
    // final keyIndPlain = encrypterKey.decrypt(eccKey, iv: ivInd);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              DataTable(columnSpacing: 30.0, columns: const [
                DataColumn(
                  label: Text(
                    'Parameter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Value',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ], rows: [
                DataRow(cells: [
                  const DataCell(Text(
                    'Encryption key verification',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  )),
                  DataCell(Text(
                    encFileData['encKey'][1] as String,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  )),
                ]),
                DataRow(cells: [
                  const DataCell(Text(
                    'Private key',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  )),
                  DataCell(Text(
                    encFileData['prvKey'][1] as String,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  )),
                ])
              ])
            ],
          ),
        ),
      ),
    );
  }
}
