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

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/src/solid/pod_service.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/src/solid/pod_service.dart';

class PopupLoginButton extends StatefulWidget {
  final TextStyle buttonTextStyle;
  final String webID;

  const PopupLoginButton({
    Key? key,
    required this.buttonTextStyle,
    this.webID = "https://solid.empwr.au/u7274552/profile/card#me",
  }) : super(key: key);

  @override
  State<PopupLoginButton> createState() => _PopupLoginButtonState();
}

class _PopupLoginButtonState extends State<PopupLoginButton> {
  // final FutureProvider<Map<dynamic, dynamic>> authDataProvider =
  //     FutureProvider<Map<dynamic, dynamic>>((ref) async {
  //   final podService = PodService();
  //   final authData = await podService.authenticatePOD(widget.webID, context);
  //   return authData;
  // });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final podService = PodService();
        final authData =
            await podService.authenticatePOD(widget.webID, context);

        // Here, you can handle the authData, e.g., store it locally, update the UI, etc.

        // Assuming you want to print or store authData
        // print('authData: $authData');

        String jsonAuthData = jsonEncode(authData.map((key, value) {
          return MapEntry(key, value);

          // if (value is CustomClass) {
          //   return MapEntry(key, value.toJson());
          // } else {
          //   return MapEntry(key, value);
          // }
        }));

        print(jsonAuthData);

        FlutterSecureStorage storage = const FlutterSecureStorage();

        storage.write(key: 'authData', value: jsonAuthData);

        // Optionally, serialize and save the data, handle navigation, show messages, etc.
      },
      child: Text('Pop up Login', style: widget.buttonTextStyle),
    );
  }

  // String serializeMap(Map<dynamic, dynamic> map) {
  //   return map.entries.map((entry) => '${entry.key}:${entry.value}').join(',');
  // }

  // Map<dynamic, dynamic> deserializeMap(String serializedMap) {
  //   return Map.fromIterable(
  //     serializedMap.split(','),
  //     key: (item) => item.split(':')[0],
  //     value: (item) => item.split(':')[1],
  //   );
  // }
}
