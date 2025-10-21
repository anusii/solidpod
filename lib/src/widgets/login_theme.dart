/// Theme for SolidLogin widget.
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
/// Authors: Graham Williams, Anushka Vidanage, Ashley Tang, Dawei Chen

library;

import 'package:flutter/material.dart';

/// Theme configuration for a single mode (light or dark).

class SolidLoginThemeMode {
  const SolidLoginThemeMode({
    this.backgroundColor = Colors.white,
    this.cardColor = Colors.white,
    this.shadowColor = Colors.black45,
    this.titleColor = Colors.black,
    this.textColor = Colors.black,
    this.hintColor = Colors.grey,
    this.dividerColor = Colors.grey,
    this.inputBorderColor = Colors.grey,
    this.versionTextColor = Colors.grey,
  });

  /// Background color of the login panel.

  final Color backgroundColor;

  /// Card color for the login panel.

  final Color cardColor;

  /// Shadow color for the login panel card.

  final Color shadowColor;

  /// Color for the title text.

  final Color titleColor;

  /// Color for regular text.

  final Color textColor;

  /// Color for hint text in input fields.

  final Color hintColor;

  /// Color for dividers
  final Color dividerColor;

  /// Color for input field borders.

  final Color inputBorderColor;

  /// Color for the version text.

  final Color versionTextColor;
}

/// Theme configuration for the SolidLogin widget.

class SolidLoginTheme {
  const SolidLoginTheme({
    this.lightTheme = const SolidLoginThemeMode(),
    this.darkTheme = const SolidLoginThemeMode(
      backgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      shadowColor: Colors.black87,
      titleColor: Colors.white,
      textColor: Colors.white,
    ),
  });

  /// Theme configuration for light mode.

  final SolidLoginThemeMode lightTheme;

  /// Theme configuration for dark mode.

  final SolidLoginThemeMode darkTheme;
}
