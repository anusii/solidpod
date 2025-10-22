/// Helper utilities for SolidLogin widget.
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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/widgets/login_theme.dart';

// Screen size support functions to identify narrow and very narrow screens. The
// width dictates whether the Login panel is laid out on the right with the app
// image on the left, or is on top of the app image.

const int narrowScreenLimit = 1175;
const int veryNarrowScreenLimit = 750;

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

bool isNarrowScreen(BuildContext context) =>
    screenWidth(context) < narrowScreenLimit;

bool isVeryNarrowScreen(BuildContext context) =>
    screenWidth(context) < veryNarrowScreenLimit;

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

/// Return a [MarkdownTooltip] for Solid server text input

MarkdownTooltip getSolidServerTooltip(
  TextEditingController webIdController,
  SolidLoginThemeMode themeMode,
) =>
    MarkdownTooltip(
      message: defaultServerTooltip,
      child: TextFormField(
        controller: webIdController,
        style: TextStyle(color: themeMode.textColor),
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Solid Server',
          hintText: 'Solid server URL (or WebID)',
          hintStyle: TextStyle(color: themeMode.hintColor),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: themeMode.inputBorderColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: themeMode.inputBorderColor),
          ),
        ),
      ),
    );

/// Return a [MarkdownTooltip] for the theme toggle button

MarkdownTooltip getThemeToggleTooltip(
  bool isDarkMode, {
  required void Function() onPressed,
}) =>
    MarkdownTooltip(
      message: 'Switch to ${isDarkMode ? "light" : "dark"} mode',
      child: IconButton(
        icon: Icon(
          isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
          color: isDarkMode ? Colors.amber : Colors.blueGrey,
        ),
        onPressed: onPressed,
      ),
    );
