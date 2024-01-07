/// Warning popup window.
///
// Time-stamp: <Sunday 2024-01-07 12:47:38 +1100 Graham Williams>
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

/// An asynchronous function used to display a warning dialog.
/// The [BuildContext] is necessary for rendering the dialog within
/// the widget tree, while the String parameter [content] allows
/// for custom text to be displayed within the dialog.

Future<dynamic> popupWarning(BuildContext context, String content) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Warning'),
        content: Text(
          content,
        ),
        actions: [
          ElevatedButton(
            child: const Text(
              'Ok',
            ),
            onPressed: () {
              // TODO 20240107 gjw ONE SOLUTION TO THE BSUY ANIMATION STAYING
              // AROUND WAS TO POP TWICE. THIS WORKS FOR THE FAILED LOGIN
              // AUTHENTICATION WHERE WE POP THE POPUP AND THEN POP THE
              // ANIMATION BACK TO THE ORIGINAL SOLID LOGIN WIDGET. DECIDED TO
              // NOT DISPLAY THIS POPUP BUT GO BACK DIRECTLY TO THE LOGIN
              // SCREEN.
              Navigator.pop(context);
              // Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
