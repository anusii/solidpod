/// Initial loading widget set up page.
///
// Time-stamp: <Friday 2024-02-16 11:06:48 +1100 Graham Williams>
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
/// Authors: Zheyuan Xu, Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_screen_body.dart';

/// Numeric variables used in initial setup page.

const double normalLoadingScreenHeight = 200.0;

/// A [StatefulWidget] for the initial setup screen of an application, handling the initial configuration and resource allocation.
///
/// This widget serves as the main interface for the initial setup process of the application. It takes in essential parameters
/// for authentication and setup, and manages the state and UI flow for setting up the application's initial environment.

class InitialSetupScreen extends StatefulWidget {
  /// Parameters for initla setup screen

  const InitialSetupScreen(
      {required this.authData,
      required this.webId,
      required this.appName,
      required this.resCheckList,
      required this.child,
      super.key});

  /// Validated authentication data returing from the Solid server.
  /// Includes Access token, Refresh token, logout URL, RSA info, Client info, etc.

  final Map<dynamic, dynamic> authData;

  /// The authenticated user specific URI.

  final String webId;

  /// Name of the app that the user is authenticating into

  final String appName;

  /// A dynamic list of missing resources from the user's POD

  final List<dynamic> resCheckList;

  /// The child widget after logging in.

  final Widget child;

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  Widget _loadedScreen(List<dynamic> resCheckList, String webId,
      String logoutUrl, Map<dynamic, dynamic> authData) {
    final resNeedToCreate = resCheckList.last as Map;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
              child: InitialSetupScreenBody(
            resNeedToCreate: resNeedToCreate,
            authData: authData,
            webId: webId,
            appName: widget.appName,
            child: widget.child,
          ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authData = widget.authData;
    final webId = widget.webId;
    final logoutUrl = authData['logoutUrl'] as String;

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
          child:
              _loadedScreen(widget.resCheckList, webId, logoutUrl, authData)),
    );
  }
}
