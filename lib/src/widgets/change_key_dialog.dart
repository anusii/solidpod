/// Show a pop up widget to change the security key
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
/// Authors: Kevin Wang, Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/widgets/secret_input_form.dart';

/// Displays a dialog for changing the key
/// [context] is the BuildContext from which this function is called.
Future<void> changeKeyPopup(BuildContext context, Widget child) async {
  final verificationKey = await KeyManager.getVerificationKey();

  const message = 'Please enter the current security key, the new security key,'
      ' and repeat the new security key.';
  const currentKeyStr = 'current_security_key';
  const newKeyStr = 'new_security_key';
  const newKeyRepeatStr = 'new_security_key_repeat';
  final formKey = GlobalKey<FormBuilderState>();

  String? validateCurrentKey(String key) =>
      verifySecurityKey(key, verificationKey)
          ? null
          : 'Incorrect security key.';

  String? validateNewKey(String key) => verifySecurityKey(key, verificationKey)
      ? 'New security key is identical to current security key.'
      : null;

  String? validateNewKeyRepeat(String key) {
    final formData = formKey.currentState?.value as Map<String, dynamic>;
    if (formData.containsKey(newKeyStr) &&
        formData.containsKey(newKeyRepeatStr) &&
        formData[newKeyStr].toString() !=
            formData[newKeyRepeatStr].toString()) {
      return 'New security keys do not match.';
    }
    return null;
  }

  Future<void> submitForm(Map<String, dynamic> formDataMap) async {
    final currentKey = formDataMap[currentKeyStr].toString();
    final newKey = formDataMap[newKeyStr].toString();
    final newKeyRepeat = formDataMap[newKeyRepeatStr].toString();

    if (validateCurrentKey(currentKey) != null ||
        validateNewKey(newKey) != null ||
        validateNewKeyRepeat(newKeyRepeat) != null) {
      return;
    }

    late Color bgColor;
    late Duration duration;
    late String msg;

    try {
      await KeyManager.changeSecurityKey(currentKey, newKey);

      msg = 'Successfully changed the security key!';
      bgColor = Colors.green;
      duration = const Duration(seconds: 4);
    } on Exception catch (e) {
      msg = 'Failed to change security key! $e';
      bgColor = Colors.red;
      duration = const Duration(seconds: 7);
    } finally {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(context, msg, bgColor, duration: duration);
      }
    }
  }

  final inputFields = [
    (
      fieldKey: currentKeyStr,
      fieldLabel: 'Current Security Key',
      validateFunc: (key) => validateCurrentKey(key as String),
    ),
    (
      fieldKey: newKeyStr,
      fieldLabel: 'New Security Key',
      validateFunc: (key) => validateNewKey(key as String),
    ),
    (
      fieldKey: newKeyRepeatStr,
      fieldLabel: 'Repeat New Security Key',
      validateFunc: (key) => validateNewKeyRepeat(key as String),
    )
  ];

  final changeKeyForm = SecretInputForm(
    title: 'Change Security Key',
    message: message,
    inputFields: inputFields,
    formKey: formKey,
    submitFunc: submitForm,
    child: child,
  );

  // Use MediaQuery to get the size of the current screen.

  if (context.mounted) {
    final size = MediaQuery.of(context).size;

    // Calculate the desired width and height.

    final width = size.width * 0.5;
    final height = size.height * 0.5;

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: width,
                    minHeight: height,
                  ),
                  child: changeKeyForm),
            ));
  }
}

// Show a message

void _showSnackBar(BuildContext context, String msg, Color bgColor,
    {Duration duration = const Duration(seconds: 4)}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: bgColor,
      duration: duration,
    ),
  );
}
