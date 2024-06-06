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
        bool Function(String)? verifyFunc,
        String? repeatOf,
      })> textFields;

  /// Key of the form for data retrieval
  final GlobalKey<FormBuilderState> formKey;

  /// The submit function
  final Future<void> Function(BuildContext, GlobalKey<FormBuilderState>)
      onSubmit;

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
      // only one of verifyFunc and repeat is null (XOR)
      assert((f.verifyFunc == null) ^ (f.repeatOf == null));

      if (f.repeatOf != null) {
        assert(fieldKeys.contains(f.repeatOf));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Key of the form for data retrieval
    final formKey = widget.formKey;

    // Small vertical and horizontal gaps

    const smallGapV = SizedBox(height: 10);
    const smallGapH = SizedBox(width: 10);

    final column = <Widget>[
      _createText(widget.title, fontSize: 20),
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
              verifyFunc: f.verifyFunc != null
                  ? (val) =>
                      f.verifyFunc!(val) ? null : 'Incorrect ${f.fieldLabel}'
                  : (val) =>
                      val == formKey.currentState!.fields[f.repeatOf!]?.value
                          ? null
                          : '${f.fieldLabel}s do not match')));
    }

    final form = FormBuilder(
        key: formKey,
        onChanged: () {
          formKey.currentState!.save();
        },
        autovalidateMode: AutovalidateMode.always,
        child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) async {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                await widget.onSubmit(context, formKey);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: column,
            )));

    // The OK button

    final okButton = ElevatedButton(
      child: _createText('OK', fontSize: 15, weighted: false),
      onPressed: () async {
        await widget.onSubmit(context, formKey);
      },
    );

    // The Cancel button

    final cancelButton = ElevatedButton(
      child: _createText('Cancel', fontSize: 15, weighted: false),
      onPressed: () => Navigator.pop(context),
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
                children: [okButton, smallGapH, cancelButton],
              ),
            ])));
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
