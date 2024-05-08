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
/// Authors: Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/utils/misc.dart'
    show getAppNameVersion, logoutPod;

/// A pop up widget for user to logout

class LogoutDialog extends StatefulWidget {
  /// Constructor
  const LogoutDialog({required this.child, super.key});

  /// The child widget after logging out
  final Widget child;

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  Widget _build(BuildContext context, String title) {
    return AlertDialog(
      title: const Text('Notice'),
      content: Text('Logging out $title?'),
      actions: [
        ElevatedButton(
            child: const Text('OK'),
            onPressed: () async {
              if (await logoutPod()) {
                await Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => widget.child));
              } else {
                Navigator.pop(context);
                await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text('Logging out failed'),
                            content: Text(
                                'Unable to logging out the $title, please try again later'),
                            actions: [
                              ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Dismiss'))
                            ]));
              }
            }),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String name, String version})>(
        future: getAppNameVersion(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final appName = snapshot.data?.name;
            final title = appName!.isNotEmpty
                ? appName[0].toUpperCase() + appName.substring(1)
                : '';
            return _build(context, title);
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

/// Display a pop up dialog for logging out
Future<void> logoutPopup(BuildContext context, Widget child) async {
  await showDialog(
    context: context,
    builder: (context) => LogoutDialog(child: child),
  );
}
