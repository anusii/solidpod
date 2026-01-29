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

/// Thresholds for window size
class WindowSize {
  /// Small width threshold
  static const double smallWidthLimit = 600;

  /// Small height threshold
  static const double smallHeightLimit = 600;

  /// Boolean describing whether the parent widget
  /// is narrow. Derived from the box constraints
  /// found by LayoutBuilder().
  ///
  /// Arguments:
  /// - [constraints] - The box constraints of the parent widget where LayoutBuilder() called.
  bool isNarrowWindow(BoxConstraints constraints) {
    final bool isNarrow;
    if (constraints.maxWidth < WindowSize.smallWidthLimit) {
      isNarrow = true;
    } else {
      isNarrow = false;
    }

    return isNarrow;
  }
}

/// Approximate size for grid items used for
/// displaying text in list item.

class ListItemSize {
  /// Approximate height of compressed item
  /// in list
  /// when list item text is line wrapped
  /// in a narrow mobile phone size window.
  /// (Where each of note title, created date time,
  /// modified date time are line wrapped to
  /// two lines.)

  static const double compressedItemHeight =
      260; // (4 row subtitle) 190; (wrapped 4 row subtitle)

  /// Approximate height of uncompressed item
  /// in list
  /// when list item text is not line wrapped.

  static const double uncompressedItemHeight =
      138; // (4 row subtitle) 108; (3 row subtitle)

  /// Calculate card aspect ratio to use for
  /// gridview builder cards using the box
  /// constraints found by LayoutBuilder().
  ///
  /// Arguments:
  /// - [constraints] - The box constraints of the parent widget
  /// where LayoutBuilder() called.

  double calculateCardAspectRatio(BoxConstraints constraints) {
    /// Aspect ratio (width / height) for gridview
    /// cards to display note items
    final double cardAspectRatio;

    // Derive card aspect ratio (width / height)
    if (constraints.maxWidth < WindowSize.smallWidthLimit) {
      cardAspectRatio = constraints.maxWidth / compressedItemHeight;
    } else {
      cardAspectRatio = constraints.maxWidth / uncompressedItemHeight;
    }
    return cardAspectRatio;
  }
}

/// Class for icon sizing in list items

class ListIconSize {
  static const double width = 50;
  static const double height = 50;
  static const double twoIconWidth = (width * 2) + gap;
  static const double gap = 15;
}

/// Icon shape decoration for list items
ShapeDecoration listIconShape =
    const ShapeDecoration(color: Colors.grey, shape: CircleBorder());

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
