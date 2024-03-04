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

import 'package:flutter/material.dart';
import 'package:solidpod/src/solid/pod_service.dart';

class PopupLoginButton extends StatelessWidget {
  final TextStyle buttonTextStyle;
  final String webIdFromSettingPage;

  const PopupLoginButton({
    Key? key,
    required this.buttonTextStyle,
    this.webIdFromSettingPage =
        "https://pods.solidcommunity.au/kevin/profile/card#me",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final podService = PodService();
        Map<dynamic, dynamic> authData = await podService.authenticatePOD(
          webIdFromSettingPage,
          context,
        );
        print('authData  $authData');
      },
      child: Text('Pop up Login', style: buttonTextStyle),
    );
  }
}
