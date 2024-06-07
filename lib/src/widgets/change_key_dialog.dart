/// A pop up widget for changing security key
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
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/widgets/secret_input_form.dart';

/// Change key dialog widget
class ChangeKeyDialog extends StatefulWidget {
  /// Constructor
  const ChangeKeyDialog({super.key});

  @override
  State<ChangeKeyDialog> createState() => _ChangeKeyDialogState();
}

class _ChangeKeyDialogState extends State<ChangeKeyDialog> {
  bool _isObscuredCurrentKey = true;
  bool _isObscuredNewKey = true;
  bool _isObscuredRepeatNewKey = true;

  final TextEditingController _currentKeyController = TextEditingController();
  final TextEditingController _newKeyController = TextEditingController();
  final TextEditingController _repeatKeyController = TextEditingController();

  void _toggleVisibilityCurrentKey() {
    setState(() {
      _isObscuredCurrentKey = !_isObscuredCurrentKey;
    });
  }

  void _toggleVisibilityNewKey() {
    setState(() {
      _isObscuredNewKey = !_isObscuredNewKey;
    });
  }

  void _toggleVisibilityRepeatNewKey() {
    setState(() {
      _isObscuredRepeatNewKey = !_isObscuredRepeatNewKey;
    });
  }

  // Show a message
  void _showSnackBar(String msg, Color bgColor,
      {Duration duration = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bgColor,
        duration: duration,
      ),
    );
  }

  Future<void> _changeKey() async {
    if (_newKeyController.text == _currentKeyController.text) {
      _showSnackBar('The new key and old key are the same. Please try again.',
          Colors.red);
    } else if (_newKeyController.text != _repeatKeyController.text) {
      _showSnackBar('The new keys do not match. Please try again.', Colors.red);
    } else {
      late String msg;
      late Color bgColor;
      late Duration duration;
      try {
        await KeyManager.changeSecurityKey(
            _currentKeyController.text, _newKeyController.text);

        msg = 'Successfully changed the security key!';
        bgColor = Colors.green;
        duration = const Duration(seconds: 4);
      } on Exception catch (e) {
        msg = 'Failed to change security key! $e';
        bgColor = Colors.red;
        duration = const Duration(seconds: 7);
      } finally {
        // Close the dialog
        Navigator.of(context).pop();

        // Show message
        _showSnackBar(msg, bgColor, duration: duration);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the size of the current screen.

    final size = MediaQuery.of(context).size;

    // Calculate the desired width and height.

    final width = size.width * 0.6;
    final height = size.height * 0.5;

    return AlertDialog(
      title: const Text('Change Security Key'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width,
          minHeight: height,
        ),
        child: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: _currentKeyController,
                obscureText: _isObscuredCurrentKey,
                decoration: InputDecoration(
                  labelText: 'Your current security key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuredCurrentKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleVisibilityCurrentKey,
                  ),
                ),
              ),
              TextField(
                controller: _newKeyController,
                obscureText: _isObscuredNewKey,
                decoration: InputDecoration(
                  labelText: 'New security key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuredNewKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleVisibilityNewKey,
                  ),
                ),
              ),
              TextField(
                controller: _repeatKeyController,
                obscureText: _isObscuredRepeatNewKey,
                decoration: InputDecoration(
                  labelText: 'Repeat the new security key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuredRepeatNewKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleVisibilityRepeatNewKey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            // Close the dialog.

            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: () async {
            await _changeKey();
          },
          child: const Text('Change Key'),
        ),
      ],
    );
  }
}

/// Displays a dialog for changing the key
/// [context] is the BuildContext from which this function is called.
Future<void> changeKeyPopup(BuildContext context) async {
  final verificationKey = await KeyManager.getVerificationKey();

  const msg = 'Please enter the current security key, the new security key,'
      ' and then repeat the new security key.';
  const currentFieldKey = 'current_security_key';
  const newFieldKey = 'new_security_key';
  const newFieldKeyRepeat = 'new_security_key_repeat';

  final fields = [(
    fieldKey: currentFieldKey,
    fieldLabel: 'Current Security Key',
    validateFunc: (key) => verifySecurityKey(key as String, verificationKey),
    repeatOf: null,
  ),
  (fieldKey: newFieldKey,
  fieldLabel: 'New Security Key',
  validateFunc: (key) {
    if (key as String)
  }
  )
  ];

  final field = (
    fieldKey: inputKey,
    fieldLabel: 'Security Key',
    validateFunc: (key) => verifySecurityKey(key as String, verificationKey),
    repeatOf: null,
  );
  final securityKeyInput = SecretInputForm(
      title: 'Security Key',
      message: msg,
      textFields: [field],
      formKey: GlobalKey<FormBuilderState>(),
      onSubmit: (formDataMap) async {
        await KeyManager.setSecurityKey(formDataMap[inputKey].toString());
        debugPrint('Security key saved');
      });

  await Navigator.push(
      context, MaterialPageRoute(builder: (context) => securityKeyInput));

  await showDialog(
    context: context,
    builder: (context) {
      return const ChangeKeyDialog();
    },
  );
}