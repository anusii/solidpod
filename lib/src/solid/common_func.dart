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

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart'
    show InitialSetupScreen;
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show KeyManager, verifySecurityKey;
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/widgets/login_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/secret_input_form.dart';

/// Login if the user has not done so

Future<bool> loginIfRequired(BuildContext context) async {
  final loggedIn = await checkLoggedIn();
  if (!loggedIn && context.mounted) {
    await loginWebIdInputDialog(
      context,
    );
    // await Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => const SolidPopupLogin(),
    //     ));
  }
  return checkLoggedIn();
}

/// Initialise the user's PODs if the user has not done so

Future<void> initPodsIfRequired(BuildContext context) async {
  final defaultFolders = await generateDefaultFolders();
  final defaultFiles = await generateDefaultFiles();

  final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists && context.mounted) {
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
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ask for the security key from the user if the security key is not available
/// or cannot be verfied using the verification key stored in PODs.

Future<void> getKeyFromUserIfRequired(
  BuildContext context,
  Widget child,
) async {
  if (await KeyManager.hasSecurityKey()) {
    return;
  } else {
    final verificationKey = await KeyManager.getVerificationKey();

    const message = 'Please enter the security key you previously provided'
        ' for securing your data.';
    const inputKey = 'security_key';
    final inputField = (
      fieldKey: inputKey,
      fieldLabel: 'Security Key',
      validateFunc: (key) {
        assert(key != null);
        return verifySecurityKey(key as String, verificationKey)
            ? null
            : 'Incorrect Security Key';
      }
    );
    final securityKeyInput = SecretInputForm(
      title: 'Security Key',
      message: message,
      inputFields: [inputField],
      formKey: GlobalKey<FormBuilderState>(),
      submitFunc: (formDataMap) async {
        await KeyManager.setSecurityKey(formDataMap[inputKey].toString());
        debugPrint('Security key saved');
        if (context.mounted) Navigator.pop(context);
      },
      child: child,
    );

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => securityKeyInput),
      );
    }
  }
}

/// Delete a data file (and its ACL file if exist), remove its individual key
/// and the corresponding IV from the ind-key-file
Future<void> deleteDataFile(
  String fileName,
  BuildContext context, {
  ResourceContentType contentType = ResourceContentType.turtleText,
}) async {
  final loggedIn = await loginIfRequired(context);

  const smallGapH = SizedBox(width: 10);
  String msg;

  if (loggedIn) {
    final filePath = [await getDataDirPath(), fileName].join('/');
    final fileUrl = await getFileUrl(filePath);
    final status = await checkResourceStatus(fileUrl);

    switch (status) {
      case ResourceStatus.exist:
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Notice'),
              content: Text('Delete data file "$fileName"?'),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await deleteFile(filePath, contentType: contentType);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Successfully deleted data file "$fileName".',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                smallGapH,
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }
        return;

      case ResourceStatus.notExist:
        msg = 'Data file "$fileName" does not exist.';

      case ResourceStatus.unknown:
        msg =
            'Error occurred when checking the status of data file "$fileName".';
    }
  } else {
    msg = 'Please login to delete the data file';
  }

  if (context.mounted) await alert(context, msg);
}
