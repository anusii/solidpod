/// Button widget for POD apps.
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

class PodButton extends StatelessWidget {
  const PodButton({
    required this.text,
    required this.background,
    required this.foreground,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
  final VoidCallback onPressed;

  // Define a common style for the text of the two buttons, GET POD and LOGIN.

  final buttonTextStyle = const TextStyle(
    fontSize: 16.0,
    letterSpacing: 2.0,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return MarkdownTooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,

          // Add a solid border to make buttons more visible.
          side: BorderSide(color: Colors.grey.shade400),

          // Apply rounded corners consistent with card style.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

          // Increase vertical padding.
          padding: const EdgeInsets.symmetric(vertical: 12),

          // Ensure a minimum size of 48px in height as per guidelines.
          minimumSize: const Size(88, 48),
        ),
        child: Text(text, style: buttonTextStyle),
      ),
    );
  }
}
