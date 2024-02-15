/// Initial loaded widget set up page.
///
// Time-stamp: <Monday 2024-01-08 12:10:52 +1100 Graham Williams>
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
import 'package:solidpod/src/screens/initial_setup_desktop.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

// Numeric variables used in initial setup page.

const double normalLoadingScreenHeight = 200.0;

/// A [StatefulWidget] for the initial setup screen of an application, handling the initial configuration and resource allocation.
///
/// This widget serves as the main interface for the initial setup process of the application. It takes in essential parameters
/// for authentication and setup, and manages the state and UI flow for setting up the application's initial environment.

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen(
      {required this.authData,
      required this.webId,
      required this.appName,
      super.key});

  final Map<dynamic, dynamic> authData;
  final String webId;
  final String appName;

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static Future<dynamic>? _asyncDataFetch;

  @override
  void initState() {
    final authData = widget.authData;
    final appName = widget.appName;

    final defaultFolders = generateDefaultFolders(appName);
    final defaultFiles = generateDefaultFiles(appName);

    _asyncDataFetch =
        initialStructureTest(authData, appName, defaultFolders, defaultFiles);
    super.initState();
  }

  Widget _loadedScreen(List<dynamic> resNotExist, String webId,
      String logoutUrl, Map<dynamic, dynamic> authData) {
    final resNeedToCreate = resNotExist.last as Map;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
              child: InitialSetupDesktop(
                  resNeedToCreate: resNeedToCreate,
                  authData: authData,
                  webId: webId,
                  appName: widget.appName))
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
        child: FutureBuilder(
            future: _asyncDataFetch,
            builder: (context, snapshot) {
              Widget returnVal;
              if (snapshot.connectionState == ConnectionState.done) {
                returnVal = _loadedScreen(
                    snapshot.data! as List, webId, logoutUrl, authData);
              } else {
                returnVal = loadingScreen(normalLoadingScreenHeight);
              }
              return returnVal;
            }),
      ),
    );
  }
}
