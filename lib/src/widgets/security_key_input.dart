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
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:solidpod/src/solid/utils/key_helper.dart' show KeyManager;

/// A [StatefulWidget] for user to enter the security key for data
/// encryption. It is verified and saved to local secure storage
@Deprecated('''
[SecurityKeyInput] is deprecated.
See [getKeyFromUserIfRequired(context, child)] for alternatives.
''')
class SecurityKeyInput extends StatefulWidget {
  /// Constructor.

  const SecurityKeyInput(
      {required this.verifySecurityKeyFunc, required this.child, super.key});

  /// The verification function
  final bool Function(String) verifySecurityKeyFunc;

  /// The child widget
  final Widget child;

  @override
  State<SecurityKeyInput> createState() => _SecurityKeyInputState();
}

class _SecurityKeyInputState extends State<SecurityKeyInput> {
  bool _showKey = false;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    const inputKey = 'SecurityKey';
    const message = 'Please enter the security key'
        ' you previously provided to secure your data.';

    // If the security key entered is verfied

    var keyVerified = false;

    // Small vertical and horizontal gaps

    const smallGapV = SizedBox(height: 10);
    const smallGapH = SizedBox(width: 10);

    // The form text field

    final formTextField = FormBuilderTextField(
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
          icon: Icon(_showKey ? Icons.visibility : Icons.visibility_off),
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
          if (!widget.verifySecurityKeyFunc(val as String)) {
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

    // The form builder

    final formBuilder = FormBuilder(
        key: formKey,
        onChanged: () {
          formKey.currentState!.save();
        },
        autovalidateMode: AutovalidateMode.always,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) async {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              await _saveKey(context, formKey, inputKey, keyVerified);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _createText('Security Key', fontSize: 20),
              const Divider(color: Colors.grey),
              _createText(message, fontSize: 15),
              smallGapV,
              StatefulBuilder(
                builder: (context, setState) => formTextField,
              ),
            ],
          ),
        ));

    // The OK button

    final okButton = ElevatedButton(
      child: _createText('OK', fontSize: 12, weighted: false),
      onPressed: () async {
        await _saveKey(context, formKey, inputKey, keyVerified);
      },
    );

    // The Cancel button

    final cancelButton = ElevatedButton(
      child: _createText('Cancel', fontSize: 12, weighted: false),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => widget.child),
        );
      },
    );

    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              formBuilder,
              smallGapV,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [okButton, smallGapH, cancelButton],
              ),
            ])));
  }

  // Save the security key locally

  Future<void> _saveKey(
      BuildContext context,
      GlobalKey<FormBuilderState> formKey,
      String inputKey,
      bool keyVerified) async {
    if (keyVerified) {
      final formData = formKey.currentState?.value as Map;
      await KeyManager.setSecurityKey(formData[inputKey].toString());
      debugPrint('Security key saved');
      if (context.mounted) Navigator.pop(context);
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incorrect Security Key'),
          content: const Text('The security key entered is incorrect!'),
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
  }
}

// Create a Text widget
Text _createText(String str, {required double fontSize, bool weighted = true}) {
  return Text(str,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: weighted ? FontWeight.w500 : null,
      ));
}
