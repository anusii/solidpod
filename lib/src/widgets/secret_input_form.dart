/// A form to input secret text (e.g. password, security key etc.)
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

import 'package:solidpod/src/widgets/error_dialog.dart';
import 'package:solidpod/src/widgets/secret_text_field.dart';

/// A [StatefulWidget] for user to enter, validate and submit secret text.

class SecretInputForm extends StatefulWidget {
  /// Constructor

  const SecretInputForm(
      {required this.title,
      required this.message,
      required this.textFields,
      required this.formKey,
      required this.onSubmit,
      super.key});

  /// Title of the form
  final String title;

  /// Message of the form
  final String message;

  /// The text fields
  final List<
      ({
        String fieldKey,
        String fieldLabel,
        bool Function(String)? validateFunc,
        String? repeatOf,
      })> textFields;

  /// Key of the form for data retrieval
  final GlobalKey<FormBuilderState> formKey;

  /// The submit function
  final Future<void> Function(GlobalKey<FormBuilderState>) onSubmit;

  @override
  State<SecretInputForm> createState() => _SecretInputFormState();
}

class _SecretInputFormState extends State<SecretInputForm> {
  @override
  void initState() {
    super.initState();
    assert(widget.textFields.isNotEmpty);
    final fieldKeys = {for (final f in widget.textFields) f.fieldKey};

    for (final f in widget.textFields) {
      if (f.repeatOf != null) {
        assert(fieldKeys.contains(f.repeatOf));
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    print('on submit');
    final formData = widget.formKey.currentState?.value as Map;
    print(formData);
    //field.validateFunc(formData[inputKey])

    await widget.onSubmit(widget.formKey);
    await showErrDialog(context, 'The security key entered is incorrect!');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Key of the form for data retrieval
    final formKey = widget.formKey;

    // Small vertical and horizontal gaps

    const smallGapV = SizedBox(height: 10);
    const smallGapH = SizedBox(width: 10);

    final column = <Widget>[
      _createText(widget.title, fontSize: 20, fontWeight: FontWeight.w500),
      const Divider(color: Colors.grey),
      smallGapV,
      _createText(widget.message, fontSize: 17),
    ];

    for (final f in widget.textFields) {
      column.add(smallGapV);
      column.add(StatefulBuilder(
          builder: (context, setState) => SecretTextField(
              fieldKey: f.fieldKey,
              fieldLabel: f.fieldLabel,
              validateFunc: (val) {
                if (f.validateFunc != null && !f.validateFunc!(val)) {
                  return 'Incorrect ${f.fieldLabel}';
                }
                if (f.repeatOf != null &&
                    val != formKey.currentState!.fields[f.repeatOf!]?.value) {
                  return '${f.fieldLabel}s Do Not Match';
                }
                return null;
              })));
    }

    final form = FormBuilder(
        key: formKey,
        onChanged: () => formKey.currentState!.save(),
        autovalidateMode: AutovalidateMode.always,
        child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) async {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                await _submit(context);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: column,
            )));

    // The submit button

    final submitButton = ElevatedButton(
      onPressed: () async => _submit(context),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      child: _createText('Submit', fontSize: 15, color: Colors.white),
    );

    // The Cancel button

    final cancelButton = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: _createText('Cancel', fontSize: 15),
    );

    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              form,
              smallGapV,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [submitButton, smallGapH, cancelButton],
              ),
            ])));
  }
}

// Create a Text widget
Text _createText(String str,
    {required double fontSize,
    FontWeight? fontWeight,
    Color? color = Colors.black}) {
  return Text(str,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ));
}
