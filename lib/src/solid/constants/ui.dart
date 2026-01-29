/// Constants used for UI elements across the package.
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
/// Authors: Ashley Tang, Jess Moore

library;

import 'package:flutter/material.dart';

// Standard colours for actions and results.

class ActionColors {
  /// Green colour used for success

  static const success = Colors.green;

  // Red colour used for error/failure

  static const error = Colors.red;

  // Colour used for warning

  static const warning = Color.fromARGB(255, 204, 99, 1);

  // Red colour used for delete action

  static const delete = Colors.red;
}

/// Colours used across security dialogs and prompts.

class SecurityColors {
  /// Primary colour (Forest Green) used for headings and important elements.

  static const primary = Color(0xFF2E7D32);

  /// Primary colour for dark mode (lighter green for better contrast).

  static const primaryDark = Color(0xFF66BB6A);

  /// Accent colour (Lighter Green) used for dividers and secondary elements.

  static const accent = Color(0xFF4CAF50);

  /// Accent colour for dark mode.

  static const accentDark = Color(0xFF81C784);

  /// Background colour (Light Grey) used for dialog backgrounds.

  static const background = Color(0xFFF5F5F5);

  /// Background colour for dark mode.

  static const backgroundDark = Color(0xFF1E1E1E);

  /// Text colour (Dark Grey) used for main text content.

  static const text = Color(0xFF212121);

  /// Text colour for dark mode.

  static const textDark = Color(0xFFE0E0E0);

  /// Grey colour used for labels and secondary text.

  static const labelGrey = Colors.grey;

  /// Label colour for dark mode.

  static const labelGreyDark = Color(0xFF9E9E9E);

  /// Card background colour for light mode.

  static const cardBackground = Colors.white;

  /// Card background colour for dark mode.

  static const cardBackgroundDark = Color(0xFF2D2D2D);

  /// Separator colour for light mode.

  static const separator = Color(0xFFE0E0E0);

  /// Separator colour for dark mode.

  static const separatorDark = Color(0xFF424242);
}

/// Helper class to obtain theme-aware colours for security UI components.
///
/// This class provides methods that return appropriate colours based on the
/// current theme brightness (light or dark mode).

class SecurityThemeColors {
  /// Returns the primary colour based on the current theme.

  static Color primary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? SecurityColors.primaryDark : SecurityColors.primary;
  }

  /// Returns the accent colour based on the current theme.

  static Color accent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? SecurityColors.accentDark : SecurityColors.accent;
  }

  /// Returns the background colour based on the current theme.

  static Color background(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? SecurityColors.backgroundDark : SecurityColors.background;
  }

  /// Returns the text colour based on the current theme.

  static Color text(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? SecurityColors.textDark : SecurityColors.text;
  }

  /// Returns the label grey colour based on the current theme.

  static Color labelGrey(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? SecurityColors.labelGreyDark : SecurityColors.labelGrey;
  }

  /// Returns the card background colour based on the current theme.

  static Color cardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? SecurityColors.cardBackgroundDark
        : SecurityColors.cardBackground;
  }

  /// Returns the separator colour based on the current theme.

  static Color separator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? SecurityColors.separatorDark : SecurityColors.separator;
  }
}

/// Text styles used across security dialogs and prompts.

class SecurityTextStyles {
  /// Style for main headings (e.g. "Security Key").

  static const heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: SecurityColors.primary,
  );

  /// Style for regular text content.

  static const body = TextStyle(
    fontSize: 15,
    color: SecurityColors.text,
  );

  /// Style for the WebID display.

  static const webId = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Style for the "Currently logged in as:" label.

  static const label = TextStyle(
    fontSize: 13,
    color: SecurityColors.labelGrey,
  );

  /// Style for button text.

  static const button = TextStyle(
    fontSize: 14,
    color: Colors.white,
  );
}

/// Helper class to obtain theme-aware text styles for security UI components.

class SecurityThemeTextStyles {
  /// Returns the heading style based on the current theme.

  static TextStyle heading(BuildContext context) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: SecurityThemeColors.primary(context),
    );
  }

  /// Returns the body text style based on the current theme.

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      color: SecurityThemeColors.text(context),
    );
  }

  /// Returns the WebID style based on the current theme.

  static TextStyle webId(BuildContext context, {bool isLoggedIn = true}) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isLoggedIn ? SecurityThemeColors.primary(context) : Colors.red,
    );
  }

  /// Returns the label style based on the current theme.

  static TextStyle label(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      color: SecurityThemeColors.labelGrey(context),
    );
  }

  /// Returns the button text style.

  static const button = TextStyle(
    fontSize: 14,
    color: Colors.white,
  );

  /// Returns the cancel button style based on the current theme.

  static TextStyle cancelButton(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: SecurityThemeColors.text(context),
    );
  }
}

/// Layout constants used across security dialogs and prompts.

class SecurityLayout {
  /// Horizontal gap between elements.

  static const horizontalGap = SizedBox(width: 16);

  /// Standard padding for dialog content.

  static const contentPadding = EdgeInsets.all(20);

  /// Padding for form sections.

  static const formPadding = EdgeInsets.fromLTRB(20, 20, 20, 8);

  /// Padding for button sections.

  static const buttonsPadding = EdgeInsets.fromLTRB(20, 8, 20, 20);

  /// Margin for green divider under heading.

  static const dividerMargin = EdgeInsets.only(top: 4, bottom: 14);

  /// Padding for WebID display.

  static const webIdPadding = EdgeInsets.only(top: 4, bottom: 20);

  /// Input field spacing.

  static const inputFieldSpacing = EdgeInsets.only(bottom: 16);

  /// Button padding.

  static const buttonPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 10);

  /// Standard width for security dialogs.

  static const dialogWidth = 480.0;

  /// Maximum width constraint for security dialogs.

  static const maxDialogWidth = 500.0;

  /// Border radius for cards and buttons.

  static const borderRadius = 8.0;

  /// Border radius for buttons.

  static const buttonRadius = 6.0;

  /// Height for divider lines.

  static const dividerHeight = 1.5;

  /// Height for separator lines.

  static const separatorHeight = 1.0;
}

/// Common text strings used across security dialogs and prompts.

class SecurityStrings {
  /// Label for the WebID display.

  static const webIdLabel = 'Currently logged in as:';

  /// Label for not logged in state.

  static const notLoggedIn = 'Not logged in';

  /// Security key input prompt.

  static const securityKeyPrompt =
      'Please enter the security key you previously provided for securing your data.';

  /// Submit button text.

  static const submit = 'Submit';

  /// Cancel button text.

  static const cancel = 'Cancel';
}

/// Layout constants for scrollbars.

class ScrollbarLayout {
  /// Vertical gap between edge widget and scrollbar to avoid
  /// horizontal scrollbar overlapping bottom edge of wrapped
  /// content.

  static const verticalGap = SizedBox(height: 30);

  /// Horizontal gap between edge widget and scrollbar to avoid
  /// vertical scrollbar overlapping the right edge of wrapped
  /// content
  ///
  static const horizontalGap = SizedBox(width: 10);
}

/// Normal height for data loading screens
const double normalLoadingScreenHeight = 200.0;

/// Colours used across dropdown dialogs and prompts.

class DropdownColors {
  /// Primary colour (Forest Green) used for dropdown elements

  static const primary = Color(0xFF2E7D32);

  /// Accent colour (Lighter Green) used for dividers and secondary elements.

  static const accent = Color(0xFF4CAF50);
}

/// Layout constants used for WebId dialogs

class WebIdLayout {
  /// Vertical gap between paragraphs

  static const paraVertGap = SizedBox(height: 10);

  /// Standard padding for dialog content.

  static const contentPadding = EdgeInsets.symmetric(horizontal: 50);

  /// Standard width for security dialogs.

  static const dialogWidth = 480.0;

  /// Height of dropdown suggestion box.

  static const dropdownHeight = 120.0;

  /// Elevation of dropdown suggestion cards.

  static double dropdownElevation = 5;

  /// Padding of dropdown suggestion list.

  static const listPadding = EdgeInsets.fromLTRB(0, 5, 0, 5);
}

/// Layout constants used for Grant Permission Form Dialog

class GrantPermFormLayout {
  /// Vertical gap between paragraphs

  static const paraVertGap = SizedBox(height: 10);

  /// Standard padding for dialog content.

  static const contentPadding = EdgeInsets.symmetric(horizontal: 50);

  /// Standard width for security dialogs.

  static const dialogWidth = 480.0;

  /// Height of dropdown suggestion box.

  static const dropdownHeight = 120.0;

  /// Elevation of dropdown suggestion cards.

  static double dropdownElevation = 5;

  /// Padding of dropdown suggestion list.

  static const listPadding = EdgeInsets.fromLTRB(0, 5, 0, 5);
}
