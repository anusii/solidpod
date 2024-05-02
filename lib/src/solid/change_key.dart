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

import 'package:flutter/material.dart';

class ChangeKeyDialog extends StatefulWidget {
  @override
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Encryption Key'),
      content: SingleChildScrollView(
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
                    _isObscuredNewKey ? Icons.visibility_off : Icons.visibility,
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
      actions: <Widget>[
        ElevatedButton(
          child: Text('Change Key'),
          onPressed: () {
            // TODO: Implement change key logic
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
