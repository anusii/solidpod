/// Common functions for package users.
///
// Time-stamp: <Friday 2024-02-16 10:59:10 +1100 Graham Williams>
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

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';
import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/popup_login.dart';
import 'package:solidpod/src/solid/utils.dart';

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

/// Initialise the user's POD if the user has not done so

Future<void> initPodIfRequired(BuildContext context, Widget child) async {
  final defaultFolders = await generateDefaultFolders();
  final defaultFiles = await generateDefaultFiles();

  final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists) {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => InitialSetupScreen(
                resCheckList: resCheckList,
                child: child,
              )),
    );
  }
}

/// Ask for the master password from the user if the master password is not
/// stored in local secure storage or
/// it cannot be verfied using the verification key stored in PODs

Future<void> askMasterPasswordIfRequired(BuildContext context) async {
  final masterPasswd = await loadMasterPassword();
  final verificationKey = await getVerificationKey();
  assert(verificationKey != null);

  // if (masterPasswd != null) {
  //   await removeMasterPassword();
  //   print('password deleted');
  // }

  if (masterPasswd == null ||
      !verifyMasterPassword(masterPasswd, verificationKey!)) {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MasterPasswdInput(verficationKey: verificationKey!),
        ));
  }
}

/// MasterPasswordInput is a [StatefulWidget] for user to enter
/// the master password for data encryption.
class MasterPasswdInput extends StatefulWidget {
  /// Constructor
  const MasterPasswdInput({required this.verficationKey, super.key});

  /// The verification key
  final String verficationKey;

  @override
  // ignore: library_private_types_in_public_api
  _MasterPasswdInputState createState() => _MasterPasswdInputState();
}

class _MasterPasswdInputState extends State<MasterPasswdInput> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    const passwordKey = 'password';
    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FormBuilder(
                key: formKey,
                onChanged: () {
                  formKey.currentState!.save();
                  debugPrint(formKey.currentState!.value.toString());
                },
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Please provide your password used to secure your data',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      requiredPwdMsg,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FormBuilderTextField(
                      name: passwordKey,
                      obscureText:
                          // Controls whether the password is shown or hidden.

                          !_showPassword,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'PASSWORD',
                        labelStyle: const TextStyle(
                          color: Colors.blue,
                          letterSpacing: 1.5,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _showPassword =
                                  // Toggle the state to show/hide the password.

                                  !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (val) {
                          if (genVerificationKey(val as String) !=
                              widget.verficationKey) {
                            return 'Incorrect Password';
                          }
                          return null;
                        },
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? true) {
                      final formData = formKey.currentState?.value as Map;
                      await saveMasterPassword(
                          formData[passwordKey].toString());
                      print(
                          'password ${formData[passwordKey].toString()} saved');
                    }
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  )),
            ])));
  }
}
