/// Dialog for changing the security key with WebID displayed prominently.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/widgets/secret_text_field.dart';

/// A [StatefulWidget] for user to change security key with improved UI and WebID display.

class SecurityKeyDialog extends StatefulWidget {
  /// Constructor.

  const SecurityKeyDialog({
    required this.webId,
    required this.title,
    required this.message,
    required this.inputFields,
    required this.formKey,
    required this.submitFunc,
    required this.child,
    super.key,
  });

  /// The WebID to display.

  final String? webId;

  /// Title of the dialog.

  final String title;

  /// Message to display.

  final String message;

  /// The input text fields.

  final List<
      ({
        String fieldKey,
        String fieldLabel,
        String? Function(String?) validateFunc,
      })> inputFields;

  /// Key of the form for data retrieval.

  final GlobalKey<FormBuilderState> formKey;

  /// The submit function.

  final Future<void> Function(Map<String, dynamic> formDataMap) submitFunc;

  /// The child widget.

  final Widget child;

  @override
  State<SecurityKeyDialog> createState() => _SecurityKeyDialogState();
}

class _SecurityKeyDialogState extends State<SecurityKeyDialog> {
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
    // Key of the form for data retrieval.

    final formKey = widget.formKey;

    // Create the input fields.

    final inputFieldWidgets = <Widget>[];

    for (final f in widget.inputFields) {
      inputFieldWidgets.add(
        Padding(
          padding: SecurityLayout.inputFieldSpacing,
          child: StatefulBuilder(
            builder: (context, setState) => SecretTextField(
              fieldKey: f.fieldKey,
              fieldLabel: f.fieldLabel,
              validateFunc: (val) {
                final r = f.validateFunc(val);

                setState(() {
                  _verifiedMap[f.fieldKey] = (r == null);
                });

                this.setState(() {
                  _canSubmit = !_verifiedMap.containsValue(false);
                });

                return r;
              },
            ),
          ),
        ),
      );
    }

    // Form.

    final form = FormBuilder(
      key: formKey,
      onChanged: () {
        // Save input and validate.

        formKey.currentState!.save();
        formKey.currentState!.validate(
          focusOnInvalid: false,
        );

        // Update state.

        setState(() {
          _canSubmit = !_verifiedMap.containsValue(false);
        });
      },
      autovalidateMode: AutovalidateMode.disabled,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) async {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            await _submit(context);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: inputFieldWidgets,
        ),
      ),
    );

    // Submit button.

    final submitButton = ElevatedButton(
      onPressed: _canSubmit ? () async => _submit(context) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: SecurityColors.primary,
        padding: SecurityLayout.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SecurityLayout.buttonRadius),
        ),
      ),
      child: Text(
        SecurityStrings.submit,
        style: SecurityTextStyles.button,
      ),
    );

    final cancelButton = TextButton(
      onPressed: () async => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget.child,
        ),
      ),
      style: TextButton.styleFrom(
        padding: SecurityLayout.buttonPadding,
      ),
      child: Text(
        SecurityStrings.cancel,
        style: TextStyle(
          fontSize: 14,
          color: SecurityColors.text,
        ),
      ),
    );

    // Card content.

    final cardContent = Container(
      width: SecurityLayout.dialogWidth,
      constraints: BoxConstraints(
        maxWidth: SecurityLayout.maxDialogWidth,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SecurityLayout.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section.

          Padding(
            padding: SecurityLayout.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title heading.

                Text(
                  widget.title,
                  style: SecurityTextStyles.heading,
                ),

                // Green divider under heading.

                Container(
                  height: SecurityLayout.dividerHeight,
                  color: SecurityColors.accent,
                  margin: SecurityLayout.dividerMargin,
                ),

                // "Currently logged in as:" label.

                Text(
                  SecurityStrings.webIdLabel,
                  style: SecurityTextStyles.label,
                ),

                // WebID on separate line.

                Padding(
                  padding: SecurityLayout.webIdPadding,
                  child: Text(
                    widget.webId ?? SecurityStrings.notLoggedIn,
                    style: SecurityTextStyles.webId.copyWith(
                      color: widget.webId != null
                          ? SecurityColors.primary
                          : Colors.red,
                    ),
                  ),
                ),

                // Instructions text.

                Text(
                  widget.message,
                  style: SecurityTextStyles.body,
                ),
              ],
            ),
          ),

          // Separator.

          Container(
            height: SecurityLayout.separatorHeight,
            color: Colors.grey.shade200,
          ),

          // Form with input fields.

          Padding(
            padding: SecurityLayout.formPadding,
            child: form,
          ),

          // Buttons.

          Padding(
            padding: SecurityLayout.buttonsPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cancelButton,
                SecurityLayout.horizontalGap,
                submitButton,
              ],
            ),
          ),
        ],
      ),
    );

    return cardContent;
  }
}
