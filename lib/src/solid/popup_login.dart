/// pop up login button
///
/// Copyright (C) 2023, Software Innovation Institute, ANU.
///
/// License: http://www.apache.org/licenses/LICENSE-2.0
///
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///
/// Authors: Kevin Wang
library;

import 'dart:convert';

import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/src/solid/pod_service.dart';

class PopupLoginButton extends StatefulWidget {
  const PopupLoginButton({
    required this.buttonTextStyle,
    super.key,
    this.webID = 'https://solid.empwr.au/u7274552/profile/card#me',
  });
  final TextStyle buttonTextStyle;
  final String webID;

  @override
  State<PopupLoginButton> createState() => _PopupLoginButtonState();
}

class _PopupLoginButtonState extends State<PopupLoginButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final podService = PodService();
        final authData =
            await podService.authenticatePOD(widget.webID, context);

        // some useful data from the authData to contruct the authDataMap

        final accessToken = authData['accessToken'].toString();
        final rsaInfo = authData['rsaInfo'];
        final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
        final publicKeyJwk = rsaInfo['pubKeyJwk'];

        final authDataMap = <String, dynamic>{
          'accessToken': accessToken,
          'rsaInfo': {
            'rsa': keyPairToMap(rsaKeyPair), // Convert KeyPair to a Map
            'pubKeyJwk': publicKeyJwk,
          },
        };

        final jsonStr = json.encode(authDataMap);

        // Save the authData to the secure storage.

        const storage = FlutterSecureStorage();

        await storage.write(key: 'authData', value: jsonStr);
      },
      child: Text('Pop up Login', style: widget.buttonTextStyle),
    );
  }

  // Convert KeyPair to a Map.

  Map<String, dynamic> keyPairToMap(KeyPair keyPair) {
    return {
      'publicKey': keyPair.publicKey,
      'privateKey': keyPair.privateKey,
    };
  }
}
