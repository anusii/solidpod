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
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';

/// A form widget for inputing encryption key
///
/// A developer may change this to include any other input data they want to
/// gather from a POD user. Eg: Name, Gender

FormBuilder encKeyInputForm(GlobalKey<FormBuilderState> formKey,
    bool showPassword, void Function(dynamic val) onChangedVal) {
  return FormBuilder(
    key: formKey,
    onChanged: () {
      formKey.currentState!.save();
      debugPrint(formKey.currentState!.value.toString());
    },
    autovalidateMode: AutovalidateMode.disabled,
    skipDisabled: true,
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
        const Divider(
          color: Colors.grey,
        ),
        const SizedBox(
          height: 20,
        ),
        const Text(
          requiredPwdMsg,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        FormBuilderTextField(
          name: 'password',
          obscureText: showPassword,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'PASSWORD',
            labelStyle: TextStyle(
              color: darkBlue,
              letterSpacing: 1.5,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
            //errorText: 'error',
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        FormBuilderTextField(
          name: 'repassword',
          obscureText: showPassword,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'RETYPE PASSWORD',
            labelStyle: TextStyle(
              color: darkBlue,
              letterSpacing: 1.5,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
            //errorText: 'error',
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            (val) {
              if (val != formKey.currentState!.fields['password']?.value) {
                return 'Passwords do not match';
              }
              return null;
            },
          ]),
        ),
        const SizedBox(
          height: 30,
        ),
        const Text(
          publicKeyMsg,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        FormBuilderCheckbox(
          name: 'providepermission',
          initialValue: false,
          onChanged: onChangedVal,
          title: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text:
                      'I also note that the resources identified below will be created. ',
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
        const SizedBox(
          height: 20,
        ),
      ],
    ),
  );
}
