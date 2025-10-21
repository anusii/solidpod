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

/// Colours used across security dialogs and prompts.

class SecurityColors {
  /// Primary colour (Forest Green) used for headings and important elements.

  static const primary = Color(0xFF2E7D32);

  /// Accent colour (Lighter Green) used for dividers and secondary elements.

  static const accent = Color(0xFF4CAF50);

  /// Background colour (Light Grey) used for dialog backgrounds.

  static const background = Color(0xFFF5F5F5);

  /// Text colour (Dark Grey) used for main text content.

  static const text = Color(0xFF212121);

  /// Grey colour used for labels and secondary text.

  static const labelGrey = Colors.grey;
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

/// Button styles used in the Solid Login widget.

// Colours for highlighted buttons.
//
// Do these need to be highligheted. By default the package should not highlight
// them but if an app developer wants to then we should support that. (gjw
// 20250422)
//
// The original alternatives were Color(0xFF00BCD4) and Colors.white for
// register and Color(0xFF4CAF50) abd Colors.white for login. I find the colours
// a bit distracting as a user. (gjw 20250422)

const Color defaultButtonBackground = Colors.white;
const Color defaultButtonForeground = Colors.black;

const Color registerButtonBackground = defaultButtonBackground;
const Color registerButtonForeground = defaultButtonForeground;
const Color loginButtonBackground = defaultButtonBackground;
const Color loginButtonForeground = defaultButtonForeground;

const String defaultLoginButtonText = 'Login';
const String defaultRegisterButtonText = 'Register';
const String defaultInfoButtonText = 'Info';
const String defaultContinueButtonText = 'Continue';
const String defaultChangeKeyButtonText = 'Change Key';

const String defaultServerTooltip = '''

**Solid Server:** This text field contains the Solid server you will connect to
where your data is hosted. It is also used as the base of the URI (Uniform
Resource Identifier) that will be used for your WebID. A WebID is a
decentralized identity that allows you to have a globally unique identifier for
your data store.

''';

const String defaultLoginTooltip = '''

**Login:** Tap here to log in to a Solid server to access you private data. You
will be connected to the specified Solid server and you can then log in with
your username and password. This app does not know your username/password. The
app will will use a token from the server to establish your secure conenction.

''';
const String defaultRegisterTooltip = '''

**Register:** Tap here to connect to your Solid server to register for an
account. Once you have an account you will be able to save data onto your host
server. You can connect to a Solid server of your choice, including your own, a
free community supported server, a commercial server, or a government run
server.

''';

const String defaultInfoTooltip = '''

**Support:** Tap here to be taken to the app help and support documentation.

''';

const String defaultContinueTooltip = '''

**Continue:** Tap here to continue on to the app without logging into your Solid
server. The app will generally be able to save data locally or else prompt to
log in to a Solid server when needed. No data will be shared beyond you local
device until you connect to a SOlid server hosting your data.

''';

class ContinueButtonStyle {
  const ContinueButtonStyle({
    this.text = defaultContinueButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultContinueTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class ChangeKeyButtonStyle {
  const ChangeKeyButtonStyle({
    this.text = defaultChangeKeyButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
  });
  final String text;
  final Color background;
  final Color foreground;
}

class LoginButtonStyle {
  const LoginButtonStyle({
    this.text = defaultLoginButtonText,
    this.background = loginButtonBackground,
    this.foreground = loginButtonForeground,
    this.tooltip = defaultLoginTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class RegisterButtonStyle {
  const RegisterButtonStyle({
    this.text = defaultRegisterButtonText,
    this.background = registerButtonBackground,
    this.foreground = registerButtonForeground,
    this.tooltip = defaultRegisterTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class InfoButtonStyle {
  const InfoButtonStyle({
    this.text = defaultInfoButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultInfoTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}
