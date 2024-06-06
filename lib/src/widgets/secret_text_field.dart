/// A text field for inputting secret text (e.g. password, security key etc.)
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

/// A [StatefulWidget] for user to enter a secret text.

class SecretTextField extends StatefulWidget {
  /// Constructor.

  const SecretTextField(
      {required this.fieldKey,
      required this.fieldLabel,
      required this.verifyFunc,
      super.key});

  /// The key of this text field (to be used in a form)
  final String fieldKey;

  /// The label text
  final String fieldLabel;

  /// The verification function
  final String? Function(String) verifyFunc;

  @override
  State<SecretTextField> createState() => _SecretTextFieldState();
}

class _SecretTextFieldState extends State<SecretTextField> {
  bool _showSecret = false;

  @override
  Widget build(BuildContext context) {
    // // If the secret entered is verfied
    // var verified = false;

    // The label text style

    const style = TextStyle(
      color: Colors.blue,
      letterSpacing: 1.5,
      fontSize: 13.0,
      fontWeight: FontWeight.bold,
    );

    // The suffix icon

    final icon = IconButton(
      icon: Icon(_showSecret ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() {
        // Toggle the state to show/hide the secret.
        _showSecret = !_showSecret;
      }),
    );

    // The validator

    final secretValidator = FormBuilderValidators.compose([
      FormBuilderValidators.required(),
      (val) => widget.verifyFunc(val as String),
    ]);

    return FormBuilderTextField(
      name: widget.fieldKey,
      obscureText: !_showSecret,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: widget.fieldLabel.toUpperCase(),
        labelStyle: style,
        suffixIcon: icon,
      ),
      validator: secretValidator,
    );
  }
}
