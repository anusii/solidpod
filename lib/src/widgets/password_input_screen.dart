/// A screen for inputting the master password for encryption, verify and
/// save it to local secure storage
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
/// Authors: Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:solidpod/src/solid/utils.dart' show saveMasterPassword;

/// MasterPasswordInput is a [StatefulWidget] for user to enter
/// the master password for data encryption.
class MasterPasswdInput extends StatefulWidget {
  /// Constructor
  const MasterPasswdInput(
      {required this.verifyPasswordFunc, required this.child, super.key});

  /// The verification function
  final bool Function(String) verifyPasswordFunc;
  final Widget child;

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
    const passwordMsg = 'Please enter the password (also known as master key)'
        ' you previously provided to encrypt your data.';
    var passwordVerified = false;
    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FormBuilder(
                key: formKey,
                onChanged: () {
                  formKey.currentState!.save();
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
                      passwordMsg,
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
                              // Toggle the state to show/hide the password.
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (val) {
                          if (!widget.verifyPasswordFunc(val as String)) {
                            passwordVerified = false;
                            debugPrint('passwordVerified: $passwordVerified');
                            return 'Incorrect Password';
                          } else {
                            passwordVerified = true;
                            debugPrint('passwordVerified: $passwordVerified');
                          }
                          return null;
                        },
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ElevatedButton(
                    onPressed: () async {
                      //(formKey.currentState?.validate() ?? true)
                      if (passwordVerified) {
                        debugPrint('passwordVerified: $passwordVerified');
                        final formData = formKey.currentState?.value as Map;
                        await saveMasterPassword(
                            formData[passwordKey].toString());
                        debugPrint('password saved');
                        Navigator.pop(context);
                      } else {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Incorrect Password'),
                            content: const Text(
                                'The password entered is incorrect!'),
                            actions: [
                              ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Dismiss'))
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    )),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => widget.child),
                      );
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ))
              ]),
            ])));
  }
}
