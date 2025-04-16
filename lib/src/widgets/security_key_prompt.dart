/// Security key prompt with WebID displayed prominently.
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

/// A [StatefulWidget] for user to enter security key with improved UI and WebID display.

class SecurityKeyPrompt extends StatefulWidget {
  /// Constructor.

  const SecurityKeyPrompt({
    required this.webId,
    required this.inputField,
    required this.formKey,
    required this.submitFunc,
    required this.child,
    super.key,
  });

  /// The WebID to display.

  final String? webId;

  /// The input text field.

  final ({
    String fieldKey,
    String fieldLabel,
    String? Function(String?) validateFunc,
  }) inputField;

  /// Key of the form for data retrieval.

  final GlobalKey<FormBuilderState> formKey;

  /// The submit function.

  final Future<void> Function(Map<String, dynamic> formDataMap) submitFunc;

  /// The child widget.

  final Widget child;

  @override
  State<SecurityKeyPrompt> createState() => _SecurityKeyPromptState();
}

class _SecurityKeyPromptState extends State<SecurityKeyPrompt> {
  bool _isVerified = false;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submit(BuildContext context) async {
    final formData = widget.formKey.currentState?.value as Map<String, dynamic>;

    if (!_canSubmit) {
      return;
    }

    if (formData[widget.inputField.fieldKey] == null) {
      debugPrint('${widget.inputField.fieldKey} is null');
      return;
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

    // Input field widget.

    final inputFieldWidget = StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SecretTextField(
          fieldKey: widget.inputField.fieldKey,
          fieldLabel: widget.inputField.fieldLabel,
          validateFunc: (val) {
            final r = widget.inputField.validateFunc(val);

            setState(() {
              _isVerified = (r == null);
            });

            this.setState(() {
              _canSubmit = _isVerified;
            });

            return r;
          },
        ),
      ),
    );

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
          _canSubmit = _isVerified;
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
        child: inputFieldWidget,
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
          // Header section
          Padding(
            padding: SecurityLayout.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Key heading
                const Text(
                  'Security Key',
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
                  SecurityStrings.securityKeyPrompt,
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

          // Form with input field.
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

    return Scaffold(
      backgroundColor: SecurityColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: cardContent,
        ),
      ),
    );
  }
}
