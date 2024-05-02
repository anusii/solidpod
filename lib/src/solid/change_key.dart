/// change key pop up widget
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
/// Authors: Kevin Wang
///
///
library;

import 'package:flutter/material.dart';

/// Change key dialog widget
class ChangeKeyDialog extends StatefulWidget {
  /// Constructor
  const ChangeKeyDialog({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChangeKeyDialogState createState() => _ChangeKeyDialogState();
}

class _ChangeKeyDialogState extends State<ChangeKeyDialog> {
  bool _isObscuredCurrentKey = true;
  bool _isObscuredNewKey = true;
  bool _isObscuredRepeatNewKey = true;

  final TextEditingController _currentKeyController = TextEditingController();
  final TextEditingController _newKeyController = TextEditingController();
  final TextEditingController _repeatKeyController = TextEditingController();

  void _toggleVisibilityCurrentKey() {
    setState(() {
      _isObscuredCurrentKey = !_isObscuredCurrentKey;
    });
  }

  void _toggleVisibilityNewKey() {
    setState(() {
      _isObscuredNewKey = !_isObscuredNewKey;
    });
  }

  void _toggleVisibilityRepeatNewKey() {
    setState(() {
      _isObscuredRepeatNewKey = !_isObscuredRepeatNewKey;
    });
  }

  void _changeKey() {
    if (_newKeyController.text == _repeatKeyController.text) {
      // TODO: Implement the logic for changing the key

      // Close the dialog on successful change.

      Navigator.of(context).pop();
    } else {
      // Show a warning message if the keys do not match.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The new keys do not match. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the size of the current screen.

    final size = MediaQuery.of(context).size;

    // Calculate the desired width and height.

    final width = size.width * 0.6;
    final height = size.height * 0.5;

    return AlertDialog(
      title: const Text('Change Encryption Key'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width,
          minHeight: height,
        ),
        child: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: _currentKeyController,
                obscureText: _isObscuredCurrentKey,
                decoration: InputDecoration(
                  labelText: 'Your current encryption key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuredCurrentKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleVisibilityCurrentKey,
                  ),
                ),
              ),
              TextField(
                controller: _newKeyController,
                obscureText: _isObscuredNewKey,
                decoration: InputDecoration(
                  labelText: 'New encryption key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuredNewKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleVisibilityNewKey,
                  ),
                ),
              ),
              TextField(
                controller: _repeatKeyController,
                obscureText: _isObscuredRepeatNewKey,
                decoration: InputDecoration(
                  labelText: 'Repeat new encryption key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuredRepeatNewKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleVisibilityRepeatNewKey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            // Close the dialog.

            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _changeKey,
          child: const Text('Change Key'),
        ),
      ],
    );
  }
}
