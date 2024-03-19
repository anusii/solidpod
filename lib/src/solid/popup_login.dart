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
import 'package:solidpod/src/screens/view_data/view_keys.dart';
import 'package:solidpod/src/solid/authenticate.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A widget to pop up the login prompt if the user is not logged in

class PopupLogin extends StatefulWidget {
  /// Constructor for the PopupLogin

  const PopupLogin({
    required this.appName,
    required this.child,
    this.webId = 'https://pods.solidcommunity.au',
    super.key,
  });

  /// The URI of the user's webID used to identify the Solid server to
  /// authenticate against.
  /// Currently this is not a required argument here and is set
  /// by default.
  final String webId;

  /// Name of the app
  final String appName;

  /// The child widget to be ridirected to after logging in.
  final Widget child;

  @override
  State<PopupLogin> createState() => _PopupLoginState();
}

class _PopupLoginState extends State<PopupLogin> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static Future<dynamic>? _asyncLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: FutureBuilder(
          future: _asyncLogin,
          builder: (context, snapshot) {
            Widget returnVal;
            if (snapshot.connectionState == ConnectionState.done) {
              returnVal = _loadedScreen(snapshot.data as List);
            } else {
              returnVal = loadingScreen(200);
            }
            return returnVal;
          }),
    );
  }

  @override
  void initState() {
    _asyncLogin = solidAuthenticate(widget.webId, context);
    super.initState();
  }

  Widget _loadedScreen(List<dynamic> loginData) {
    return ShowKeys(
      appName: widget.appName,
      child: widget.child,
    );
  }
}
