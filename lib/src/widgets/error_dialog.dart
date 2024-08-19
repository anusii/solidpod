/// Shows a Widget as Error Dialog.
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

/// Displays an error dialog with a non-dismissible alert.
///
/// This function creates and displays an error dialog box in the Flutter application.
/// It is designed to be non-dismissible, meaning that the user must explicitly acknowledge
/// the error by tapping the 'OK' button to close the dialog. The error message to be displayed
/// is passed as a parameter to this function.

Future<void> showErrDialog(BuildContext context, String errMsg) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (context) {
      return AlertDialog(
        title: const Text('ERROR!'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(errMsg),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
