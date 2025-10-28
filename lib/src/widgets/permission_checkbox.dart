/// A checkbox widget for access modes.
///
// Time-stamp: <Saturday 2025-07-19 10:31:43 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
///
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/web_acl.dart';

/// Checkbox widget to display different access mode selections. Function call
/// requires the following inputs
/// [accessMode] is the AccessMode instance for the checkbox
/// [checkboxChecked] is the boolean controller for the checkbox press
/// [updateCheckBox] is the function to update the checkbox data when pressed
///

MarkdownTooltip permissionCheckbox(
  AccessMode accessMode,
  bool checkboxChecked,
  Function updateCheckBox,
) {
  return MarkdownTooltip(
    message: accessMode.description,
    child: CheckboxListTile(
      title: Text(accessMode.mode),
      value: checkboxChecked,
      onChanged: (newValue) {
        updateCheckBox(newValue, accessMode);
      },
      controlAffinity: ListTileControlAffinity.leading, //  <-- leading Checkbox
    ),
  );
}
