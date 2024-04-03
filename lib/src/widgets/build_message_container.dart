/// A widget to show message container box.
///
// Time-stamp: <Tuesday 2024-04-02 21:30:12 +1100 Graham Williams>
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
/// Authors: Where did this code come from ???
// ignore_for_file: public_member_api_docs

library;

import 'package:flutter/material.dart';

/// The `Languages` class provides a collection of language codes.

class Languages {
  static const List<String> codes = [
    'ar',
    'ar',
    'ar',
    'ar',
    'ar',
    'ar',
    'ar',
    'he',
    'fa',
    'ar',
    'ku',
    'pa',
    'sd',
    'ur',
    'he',
  ];
}

/// Returns a color based on the given content type.
///
/// This function selects a color corresponding to various content types.

Color getContentColour(String contentType) {
  if (contentType == 'failure') {
    /// failure will show `CROSS`
    return const Color(0xffc72c41);
  } else if (contentType == 'success') {
    /// success will show `CHECK`
    return const Color(0xff2D6A4F);
  } else if (contentType == 'warning') {
    /// warning will show `EXCLAMATION`
    return const Color(0xffa0a0a0); //Color(0xffFCA652);
  } else if (contentType == 'help') {
    /// help will show `QUESTION MARK`
    return const Color(0xff3282B8);
  } else {
    return const Color.fromARGB(255, 252, 144, 82);
  }
}

/// Calculates the height of a widget based on the length of the provided content.
///
/// This function determines the height of a widget by evaluating the length of
/// the string [content]. It returns different height values as a `double`
/// depending on the number of characters in [content]. The function categorizes
/// the content length into four ranges and assigns a specific height for each range.

double getWidgetHeight(String content) {
  if (content.length < 200) {
    return 0.125;
  } else if (content.length < 400) {
    return 0.190;
  } else if (content.length < 600) {
    return 0.250;
  } else {
    return 0.300;
  }
}

/// Builds a custom message box widget with adaptive layout and dynamic styling.
///
/// This widget creates a Container that displays a message box. The layout and styling
/// of the message box are adjusted based on the device's screen size (mobile, tablet,
/// or desktop) and the local language direction (RTL or LTR). It also uses dynamic
/// coloring based on the message type to enhance user experience.

Container buildMsgBox(
    BuildContext context, String msgType, String title, String msg) {
  // Zheyuan might need to use isRTL in the future
  // ignore: unused_local_variable
  var isRTL = false;

  final size = MediaQuery.of(context).size;
  final loc = Localizations.maybeLocaleOf(context);
  final localeLanguageCode = loc?.languageCode;

  if (localeLanguageCode != null) {
    for (final code in Languages.codes) {
      if (localeLanguageCode.toLowerCase() == code.toLowerCase()) {
        isRTL = true;
      }
    }
  }

  // Determine device type for layout adjustments
  final isMobile = size.width <= 730;
  final isTablet = size.width > 730 && size.width <= 1050;

  // Minimal horizontal padding for all devices
  final horizontalPadding =
      size.width * 0.01; // Adjust this value to increase or decrease padding

  return Container(
    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
    height: !isMobile
        ? !isTablet
            ? size.height * (1500.0 / size.width) * getWidgetHeight(msg)
            : size.height * (1000.0 / size.width) * getWidgetHeight(msg)
        : size.height * (650.0 / size.width) * getWidgetHeight(msg),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: size.width,
          decoration: BoxDecoration(
            color: getContentColour(msgType),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Positioned.fill(
          // Apply minimal padding equally on both sides
          left: horizontalPadding,
          right: horizontalPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.02),
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize:
                        !isMobile ? size.height * 0.03 : size.height * 0.025,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.005),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    msg,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: size.height * 0.020,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.015),
            ],
          ),
        )
      ],
    ),
  );
}
