/// A method to show animation page in the process of loading.
///
// Time-stamp: <Tuesday 2024-01-02 13:19:25 +1100 Zheyuan Xu>
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

// The following are the constant default values, mostly for colors
// of loading animation widget.

const _darkBlue = Color.fromARGB(255, 7, 87, 153);
const _darkGreen = Color.fromARGB(255, 64, 163, 81);
const _lightBlue = Color(0xFF61B2CE);
const _darkCopper = Color(0xFFBE4E0E);
const _titleAsh = Color(0xFF30384D);

/// The list contains a series of custom color variables.

List<Color> _defaultPodColors = const [
  _darkBlue,
  _darkGreen,
  _darkCopper,
  _titleAsh,
  _lightBlue,
];

/// An asynchronous utility designed to display a custom animation dialog.
/// [context] locates the widget in the widget tree and display the dialog accordingly.
/// [animationIndex] determines the type of animation.
/// This index is used to select from a predefined list of animations (Indicator.values).
/// [alertMsg] is the message text displayed within the dialog.
/// [showPathBackground] is a boolean flag to decide whether to show a background for
/// the animation path or not.

Future<void> showAnimationDialog(
  BuildContext context,
  int animationIndex,
  String alertMsg,
  bool showPathBackground,
  VoidCallback updateStateCallback,
) {
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(50),
        child: Center(
          child: SizedBox(
            width: 150,
            height: 280,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LoadingIndicator(
                    indicatorType: Indicator.values[animationIndex],
                    colors: _defaultPodColors,
                    strokeWidth: 100.0,
                    pathBackgroundColor: showPathBackground
                        ? const Color.fromARGB(59, 0, 0, 0)
                        : null,
                  ),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    child: Text(
                      alertMsg,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      updateStateCallback();
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
