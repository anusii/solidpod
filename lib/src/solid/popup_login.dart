/// pop up login button
///
/// Copyright (C) 2023, Software Innovation Institute, ANU.
///
/// License: http://www.apache.org/licenses/LICENSE-2.0
///
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/authenticate.dart';
import 'package:solidpod/src/solid/common_func.dart' show initPodsIfRequired;
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
          return loadingScreen(200);
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
