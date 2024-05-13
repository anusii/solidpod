/// Common functions for package users.
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart' show Key;

import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart'
    show InitialSetupScreen;
import 'package:solidpod/src/solid/api/rest_api.dart' show initialStructureTest;
import 'package:solidpod/src/solid/popup_login.dart' show SolidPopupLogin;
import 'package:solidpod/src/solid/utils/key_management.dart'
    show KeyManager, verifySecurityKey;
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/widgets/security_key_input.dart'
    show SecurityKeyInput;

/// Login if the user has not done so

Future<void> loginIfRequired(BuildContext context) async {
  final loggedIn = await checkLoggedIn();
  if (!loggedIn) {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SolidPopupLogin(),
        ));
  }
}

/// Initialise the user's PODs if the user has not done so

Future<void> initPodsIfRequired(BuildContext context) async {
  final defaultFolders = await generateDefaultFolders();
  final defaultFiles = await generateDefaultFiles();

  final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists) {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InitialSetupScreen(
                resCheckList: resCheckList,
                child: AlertDialog(
                  title: const Text('Notice'),
                  content: const Text('PODs successfully initialised!'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('OK'))
                  ],
                ),
              )),
    );
  }
}

/// Ask for the security key from the user if the security key is not available
/// or cannot be verfied using the verification key stored in PODs.

Future<void> getKeyFromUserIfRequired(
    BuildContext context, Widget child) async {
  if (await KeyManager.hasSecurityKey()) {
    return;
  } else {
    final verificationKey = await KeyManager.getVerificationKey();

    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecurityKeyInput(
              verifySecurityKeyFunc: (key) =>
                  verifySecurityKey(key, verificationKey),
              child: child),
        ));
  }
}
