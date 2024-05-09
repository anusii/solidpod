/// Contains functions for generating bodies of different ttl files.
///
// Time-stamp: <Tuesday 2024-04-02 21:34:27 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';

/// EncKeyInputForm is a [StatefulWidget] that represents the form for entering the encryption key.
class EncKeyInputForm extends StatefulWidget {
  /// Initialising the [StatefulWidget] with the [formKey].

  const EncKeyInputForm({required this.formKey, super.key});

  /// The key for the form.
  final GlobalKey<FormBuilderState> formKey;

  @override
  // ignore: library_private_types_in_public_api
  _EncKeyInputFormState createState() => _EncKeyInputFormState();
}

class _EncKeyInputFormState extends State<EncKeyInputForm> {
  bool _showPassword = false;
  bool _showRetypePassword = false;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: widget.formKey,
      onChanged: () {
        widget.formKey.currentState!.save();
        debugPrint(widget.formKey.currentState!.value.toString());
      },
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'We require a security key to protect your data:',
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
            name: 'password',
            obscureText:
                // Controls whether the password is shown or hidden.

                !_showPassword,
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
                icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off),
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
            ]),
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: 'repassword',
            obscureText: !_showRetypePassword,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'RETYPE SECURITY KEY',
              labelStyle: const TextStyle(
                color: Colors.blue,
                letterSpacing: 1.5,
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
              ),
              suffixIcon: IconButton(
                icon: Icon(_showRetypePassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _showRetypePassword = !_showRetypePassword;
                  });
                },
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              (val) {
                if (val !=
                    widget.formKey.currentState!.fields['password']?.value) {
                  return 'Security keys do not match';
                }
                return null;
              },
            ]),
          ),
          const SizedBox(height: 30),
          const Text(
            publicKeyMsg,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          FormBuilderCheckbox(
            name: 'providepermission',
            initialValue: false,
            onChanged: (val) {
              if (val != null) {
                debugPrint('Permission granted: $val');
              }
            },
            title: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text:
                        'I acknowledge that the resources identified below will be created. ',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            validator: FormBuilderValidators.equal(
              true,
              errorText: 'You must provide permission to continue',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
