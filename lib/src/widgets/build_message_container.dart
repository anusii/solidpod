/// A widget to show message container box.
///
// Time-stamp: <Sunday 2024-01-07 08:36:42 +1100 Graham Williams>
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
/// Authors: Graham Williams
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A utility class providing asset paths for the application.

class AssetsPath {
  static const String help = 'assets/types/help.svg';
  static const String failure = 'assets/types/failure.svg';
  static const String success = 'assets/types/success.svg';
  static const String warning = 'assets/types/warning.svg';
  static const String back = 'assets/types/back.svg';
  static const String bubbles = 'assets/types/bubbles.svg';
}

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
    return const Color(0xffFCA652);
  } else if (contentType == 'help') {
    /// help will show `QUESTION MARK`
    return const Color(0xff3282B8);
  } else {
    return const Color.fromARGB(255, 252, 144, 82);
  }
}

/// Returns the appropriate SVG asset path based on the specified content type.

String assetSVG(String contentType) {
  if (contentType == 'failure') {
    /// failure will show `CROSS`
    return AssetsPath.failure;
  } else if (contentType == 'success') {
    /// success will show `CHECK`
    return AssetsPath.success;
  } else if (contentType == 'warning') {
    /// warning will show `EXCLAMATION`
    return AssetsPath.warning;
  } else if (contentType == 'help') {
    /// help will show `QUESTION MARK`
    return AssetsPath.help;
  } else {
    return AssetsPath.failure;
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
  /// if you want to use this in materialBanner
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
  // screen dimensions
  final isMobile = size.width <= 730;
  final isTablet = size.width > 730 && size.width <= 1050;

  /// for reflecting different color shades in the SnackBar
  final hsl = HSLColor.fromColor(getContentColour(msgType));
  final hslDark = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0));

  var horizontalPadding = 0.0;
  var leftSpace = size.width * 0.12;
  final rightSpace = size.width * 0.12;

  if (isMobile) {
    horizontalPadding = size.width * 0.01;
  } else if (isTablet) {
    leftSpace = size.width * 0.05;
    horizontalPadding = size.width * 0.03;
  } else {
    leftSpace = size.width * 0.05;
    horizontalPadding = size.width * 0.04;
  }

  return Container(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
    ),
    height: !isMobile
        ? !isTablet
            ? size.height * (1500.0 / size.width) * getWidgetHeight(msg)
            : size.height * (1000.0 / size.width) * getWidgetHeight(msg)
        : size.height * (650.0 / size.width) * getWidgetHeight(msg),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // background container
        Container(
          width: size.width,
          decoration: BoxDecoration(
            color: getContentColour(msgType),
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        /// SVGs in body
        Positioned(
          bottom: 0,
          left: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
            ),
            child: SvgPicture.asset(
              AssetsPath.bubbles,
              height: size.height * 0.06,
              width: size.width * 0.05,
              colorFilter: ColorFilter.mode(hslDark.toColor(), BlendMode.srcIn),
            ),
          ),
        ),

        Positioned(
          top: -size.height * 0.02,
          left: !isRTL
              ? leftSpace - (isMobile ? size.width * 0.075 : size.width * 0.035)
              : null,
          right: isRTL
              ? rightSpace -
                  (isMobile ? size.width * 0.075 : size.width * 0.035)
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                AssetsPath.back,
                height: size.height * 0.06,
                colorFilter:
                    ColorFilter.mode(hslDark.toColor(), BlendMode.srcIn),
              ),
              Positioned(
                top: size.height * 0.015,
                child: SvgPicture.asset(
                  assetSVG(msgType),
                  height: size.height * 0.022,
                ),
              )
            ],
          ),
        ),

        Positioned.fill(
          left: isRTL ? size.width * 0.03 : leftSpace,
          right: isRTL ? rightSpace : size.width * 0.03,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height * 0.02,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: !isMobile
                            ? size.height * 0.03
                            : size.height * 0.025,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: size.height * 0.005,
              ),

              /// `message` body text parameter
              Expanded(
                child: Text(
                  msg,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: size.height * 0.022,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: size.height * 0.015,
              ),
            ],
          ),
        )
      ],
    ),
  );
}
