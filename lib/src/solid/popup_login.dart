/// pop up login button
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
/// Authors: Kevin Wang, Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/authenticate.dart';
import 'package:solidpod/src/solid/common_func.dart' show initPodsIfRequired;
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A widget to pop up the login prompt if the user is not logged in

class SolidPopupLogin extends StatefulWidget {
  /// Constructor for the PopupLogin

  const SolidPopupLogin({
    this.webId = 'https://pods.solidcommunity.au',
    super.key,
  });

  /// The URI of the user's webID used to identify the Solid server to
  /// authenticate against.
  /// Currently this is not a required argument here and is set
  /// by default.

  final String webId;

  @override
  State<SolidPopupLogin> createState() => _SolidPopupLoginState();
}

class _SolidPopupLoginState extends State<SolidPopupLogin> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Login and initialise PODs if required
  Future<bool> _loginAndInitPods(String webId, BuildContext context) async {
    try {
      await solidAuthenticate(webId, context);
      if (context.mounted) await initPodsIfRequired(context);
      return true;
    } on Object catch (e) {
      debugPrint('solidAuthenticate() failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: FutureBuilder(
        future: _loginAndInitPods(widget.webId, context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _loadedScreen(snapshot.data!);
          }
          return loadingScreen(normalLoadingScreenHeight);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _loadedScreen(bool loginStatus) {
    final dialogTitle = loginStatus ? 'Success!' : 'Failed!';
    final dialogContent = loginStatus
        ? 'You have successfully logged in and/or initialised your PODs'
        : 'You have cancelled the login';
    return AlertDialog(
      title: Text(dialogTitle),
      content: Text(
        dialogContent,
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('OK'),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
