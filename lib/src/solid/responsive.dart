/// A responsive class to divide whether the screen is mobile, tablet, desktop.
///
/// Copyright (C) 2023 Software Innovation Institute, Australian National University
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Zheyuan Xu
///
library;

import 'package:flutter/material.dart';

/// The threshold for small mobile width.
const double smallMobileWidthThreshold = 500;

/// Threshold width for desktop devices.
const double desktopWidthThreshold = 1030;

/// A class that handles responsiveness based on screen size.
class Responsive extends StatelessWidget {
  /// Constructor for the responsive class.
  const Responsive({
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required this.largeDesktop,
    super.key,
  });

  /// The widget to be displayed on mobile screens.
  final Widget mobile;

  /// The widget to be displayed on tablet screens.
  final Widget tablet;

  /// The widget to be displayed on desktop screens.
  final Widget desktop;

  /// The widget to be displayed on large desktop screens.
  final Widget largeDesktop;

  /// Returns the screen width.
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Checks if the screen size is smaller than
  /// the small mobile width threshold.
  static bool isSmallMobile(BuildContext context) =>
      screenWidth(context) < smallMobileWidthThreshold;

  /// Checks if the screen size is mobile.
  static bool isMobile(BuildContext context) =>
      screenWidth(context) < desktopWidthThreshold;

  /// Checks if the screen size is desktop.
  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= desktopWidthThreshold;

  /// Checks if the screen size is large desktop.
  static bool isLargeDesktop(BuildContext context) =>
      screenWidth(context) >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopWidthThreshold) {
          return desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
