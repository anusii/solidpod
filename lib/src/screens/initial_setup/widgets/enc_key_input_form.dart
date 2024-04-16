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

// ignore_for_file: public_member_api_docs, prefer_const_constructors_in_immutables, sort_constructors_first, always_put_required_named_parameters_first, use_super_parameters

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';

class EncKeyInputForm extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;

  EncKeyInputForm({Key? key, required this.formKey}) : super(key: key);

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
            'We require a password to secure your data:',
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
              labelText: 'PASSWORD',
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
              labelText: 'RETYPE PASSWORD',
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
                  return 'Passwords do not match';
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
