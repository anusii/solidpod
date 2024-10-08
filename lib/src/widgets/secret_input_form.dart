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

  const SecretInputForm({
    required this.title,
    required this.message,
    required this.inputFields,
    required this.formKey,
    required this.submitFunc,
    required this.child,
    super.key,
  });

  /// Title of the form
  final String title;

  /// Message of the form
  final String message;

  /// The input text fields
  final List<
      ({
        String fieldKey,
        String fieldLabel,
        String? Function(String?) validateFunc,
      })> inputFields;

  /// Key of the form for data retrieval
  final GlobalKey<FormBuilderState> formKey;

  /// The submit function
  final Future<void> Function(Map<String, dynamic> formDataMap) submitFunc;

  /// The child widget
  final Widget child;

  @override
  State<SecretInputForm> createState() => _SecretInputFormState();
}

class _SecretInputFormState extends State<SecretInputForm> {
  Map<String, bool> _verifiedMap = {};
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    assert(widget.inputFields.isNotEmpty);
    final fieldKeys = {for (final f in widget.inputFields) f.fieldKey};
    assert(fieldKeys.length == widget.inputFields.length);
    _verifiedMap = {for (final k in fieldKeys) k: false};
  }

  Future<void> _submit(BuildContext context) async {
    final formData = widget.formKey.currentState?.value as Map<String, dynamic>;

    if (!_canSubmit) {
      // debugPrint('_verifidMap: $_verifiedMap');
      return;
    }
    for (final f in widget.inputFields) {
      if (formData[f.fieldKey] == null) {
        debugPrint('${f.fieldKey} is null');
        return;
      }
    }

    try {
      await widget.submitFunc(formData);
    } on Exception catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Key of the form for data retrieval
    final formKey = widget.formKey;

    // Vertical and horizontal gaps

    const smallGapH = SizedBox(width: 10);
    const smallGapV = SizedBox(width: 10);
    const medGapV = SizedBox(height: 20);

    final column = <Widget>[
      _createText(widget.title, fontSize: 20, fontWeight: FontWeight.w500),
      const Divider(color: Colors.grey),
      smallGapV,
      _createText(widget.message, fontSize: 17),
      medGapV,
    ];

    for (final f in widget.inputFields) {
      column.add(smallGapV);
      column.add(
        StatefulBuilder(
          builder: (context, setState) => SecretTextField(
            fieldKey: f.fieldKey,
            fieldLabel: f.fieldLabel,
            validateFunc: (val) {
              final r = f.validateFunc(val);

              setState(() {
                _verifiedMap[f.fieldKey] = (r == null);
              });

              return r;
            },
          ),
        ),
      );
    }

    final form = FormBuilder(
      key: formKey,
      onChanged: () {
        // Save input and validate them

        formKey.currentState!.save();
        formKey.currentState!.validate(
          focusOnInvalid: false, // allow update new key even if it is valid
        );

        // Update state
        setState(() {
          _canSubmit = !_verifiedMap.containsValue(false);
        });

        // debugPrint('${formKey.currentState?.value as Map}');
        // debugPrint('onChange(): _verifiedMap = $_verifiedMap');
        // debugPrint('onChange(): _canSubmit =  $_canSubmit');
      },
      autovalidateMode: AutovalidateMode.disabled, // called in onChanged()
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
        ),
      ),
    );

    // The submit button

    final submitButton = ElevatedButton(
      onPressed:
          // Disable the button (set onPressed: null) if _canSubmit = false
          _canSubmit ? () async => _submit(context) : null,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      child: _createText('Submit', fontSize: 15, color: Colors.white),
    );

    // The Cancel button

    final cancelButton = ElevatedButton(
      onPressed: () async => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget.child,
        ),
      ),
      child: _createText('Cancel', fontSize: 15),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            form,
            medGapV,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [submitButton, smallGapH, cancelButton],
            ),
          ],
        ),
      ),
    );
  }
}

// Create a Text widget
Text _createText(
  String str, {
  required double fontSize,
  FontWeight? fontWeight,
  Color? color = Colors.black,
}) {
  return Text(
    str,
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    ),
  );
}
