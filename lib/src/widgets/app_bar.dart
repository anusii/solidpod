/// A default app bar.
///
// Time-stamp: <Sunday 2024-07-11 12:55:00 +1000 Anushka Vidange>
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
///
/// Authors: Anushka Vidanage, Ashley Tang

library;

import 'package:flutter/material.dart';

/// A default app bar that is used when user does not define an app bar for
/// the UI
PreferredSizeWidget defaultAppBar(
  BuildContext context,
  String title,
  Color backgroundColor,
  Widget child, {
  VoidCallback? onNavigateBack,
  bool Function()? getResult,
}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () {
        // Call the callback if provided.

        onNavigateBack?.call();

        if (getResult != null) {
          // Pop with result from callback.

          Navigator.pop(context, getResult());
        } else {
          // Use the original pushReplacement behaviour.

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => child),
          );
        }
      },
    ),
    backgroundColor: backgroundColor,
    title: Text(title),
  );
}
