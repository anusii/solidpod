/// A configuration for snackbar notifications.
///
// Time-stamp: <Wednesday 2025-04-30 15:52:42 +1000 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

/// Configuration for snackbar notifications.

class SnackbarConfig {
  /// Creates a configuration for controlling the appearance and behavior of snackbars.
  ///
  /// The [textColor] sets the color of the main text content.
  /// The [backgroundColor] sets the background color, defaulting to theme-based colors if null.
  /// The [actionTextColor] sets the color of action button text.
  /// The [duration] determines how long the snackbar will be displayed.
  /// The [borderRadius] controls the roundness of the snackbar's corners.

  const SnackbarConfig({
    this.textColor = Colors.black,
    this.backgroundColor,
    this.actionTextColor = Colors.black,
    this.duration = const Duration(seconds: 3),
    this.borderRadius = 10.0,
  });

  /// Text color for snackbar content.
  ///
  final Color textColor;

  /// Background color for snackbar.
  /// If null, will default to theme-based colors.

  final Color? backgroundColor;

  /// Text color for action buttons in snackbar.

  final Color actionTextColor;

  /// Duration to show the snackbar.

  final Duration duration;

  /// Border radius for snackbar corners.

  final double borderRadius;
}
