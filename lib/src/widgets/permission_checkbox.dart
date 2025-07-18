/// A checkbox widget for access modes.
///
// Time-stamp: <Friday 2025-07-18 13:49:31 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
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
    message: '${accessMode.description}',
    child: CheckboxListTile(
      title: Text('${accessMode.mode}'),
      value: checkboxChecked,
      onChanged: (newValue) {
        updateCheckBox(newValue, accessMode);
      },
      controlAffinity: ListTileControlAffinity.leading, //  <-- leading Checkbox
    ),
  );
}
