/// Input security key for encryption.
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

import 'package:solidpod/src/solid/utils/key_management.dart' show KeyManager;

/// A [StatefulWidget] for user to enter the security key for data
/// encryption. It is verified and saved to local secure storage

class SecurityKeyInput extends StatefulWidget {
  /// Constructor.

  const SecurityKeyInput(
      {required this.verifySecurityKeyFunc, required this.child, super.key});

  /// The verification function
  final bool Function(String) verifySecurityKeyFunc;
  final Widget child;

  @override
  // ignore: library_private_types_in_public_api
  _SecurityKeyInputState createState() => _SecurityKeyInputState();
}

class _SecurityKeyInputState extends State<SecurityKeyInput> {
  bool _showKey = false;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    const inputKey = 'SecurityKey';
    const message = 'Please enter the security key'
        ' you previously provided to secure your data.';
    var keyVerified = false;
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
                      'Security Key',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      message,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return FormBuilderTextField(
                          name: inputKey,
                          obscureText:
                              !_showKey, // Controls whether the security key is shown or hidden.
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'SECURITY KEY',
                            labelStyle: const TextStyle(
                              color: Colors.blue,
                              letterSpacing: 1.5,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_showKey
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  // Toggle the state to show/hide the security key.
                                  _showKey = !_showKey;
                                });
                              },
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            (val) {
                              if (!widget
                                  .verifySecurityKeyFunc(val as String)) {
                                keyVerified = false;
                                debugPrint('keyVerified: $keyVerified');
                                return 'Incorrect Security Key';
                              } else {
                                keyVerified = true;
                                debugPrint('keyVerified: $keyVerified');
                              }
                              return null;
                            },
                          ]),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ElevatedButton(
                    onPressed: () async {
                      if (keyVerified) {
                        debugPrint('keyVerified: $keyVerified');
                        final formData = formKey.currentState?.value as Map;
                        await KeyManager.setSecurityKey(
                            formData[inputKey].toString());
                        debugPrint('security key saved');
                        Navigator.pop(context);
                      } else {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Incorrect Security Key'),
                            content: const Text(
                                'The security key entered is incorrect!'),
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
                      style: TextStyle(color: Colors.black, fontSize: 12),
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
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ))
              ]),
            ])));
  }
}
