/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Sunday 2024-06-24 11:26:00 +1000 Anushka Vidange>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
///
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/shared_resources.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/heading.dart';
import 'package:solidpod/src/widgets/app_bar.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';
import 'package:solidpod/src/widgets/shared_resources_table.dart';

/// A widget for the demonstration screen of the application.

class SharedResourcesUi extends StatefulWidget {
  /// Initialise widget variables.

  const SharedResourcesUi({
    required this.child,
    this.title = 'Demonstrating retrieve shared data functionality',
    this.backgroundColor = const Color.fromARGB(255, 210, 210, 210),
    this.showAppBar = true,
    this.sourceWebId,
    this.fileName,
    this.customAppBar,
    super.key,
  });

  /// The child widget to return to when back button is pressed.
  final Widget child;

  /// The text appearing in the app bar.
  final String title;

  /// The text appearing in the app bar.
  final Color backgroundColor;

  /// The boolean to decide whether to display an app bar or not
  final bool showAppBar;

  /// The webId of the owner of a resource. This is a non required
  /// parameter. If not set UI will display all resources
  final String? sourceWebId;

  /// The name of the resource being shared. This is a non required
  /// parameter. If not set UI will display all resources
  final String? fileName;

  /// App specific app bar. If not set default app bar will be displayed.
  final PreferredSizeWidget? customAppBar;

  @override
  SharedResourcesUiState createState() => SharedResourcesUiState();
}

/// Class to build a UI for granting permission to a given file
class SharedResourcesUiState extends State<SharedResourcesUi>
    with SingleTickerProviderStateMixin {
  /// Permission data map of a file
  Map<dynamic, dynamic> permDataMap = {};

  /// Small vertical spacing for the widget.
  final smallGapV = const SizedBox(height: 10.0);

  /// Large vertical spacing for the widget.
  final largeGapV = const SizedBox(height: 40.0);

  @override
  void initState() {
    super.initState();
  }

  /// Build the main widget
  Widget _buildSharedResourcePage(
    BuildContext context,
    List<Object?>? futureObjList,
  ) {
    // Build the widget.

    var sharedResMap = {};
    if (futureObjList != null) {
      sharedResMap = futureObjList.first as Map;
    }

    const welcomeHeadingStr = 'Resources shared with you';

    var subHeadingStr = widget.fileName != null
        ? 'Filtered by the ${widget.fileName} file'
        : 'No filters';

    subHeadingStr = widget.sourceWebId != null
        ? subHeadingStr.contains('Filtered by')
            ? '$subHeadingStr and the WebID ${widget.sourceWebId}'
            : 'Filtered by the WebID ${widget.sourceWebId}'
        : subHeadingStr;

    return Scaffold(
      appBar: (!widget.showAppBar)
          ? null
          : (widget.customAppBar != null)
              ? widget.customAppBar
              : defaultAppBar(
                  context,
                  widget.title,
                  widget.backgroundColor,
                  widget.child,
                ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            smallGapV,
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  buildHeading(welcomeHeadingStr, 22),
                  smallGapV,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      largeGapV,
                      buildHeading(subHeadingStr, 17.0, Colors.blueGrey, 8),
                      buildSharedResourcesTable(
                        context,
                        sharedResMap,
                        widget.child,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build widget with a Future
    final fileName = widget.fileName != null ? widget.fileName as String : null;
    final sourceWebId =
        widget.sourceWebId != null ? widget.sourceWebId as String : null;
    return FutureBuilder(
      future: Future.wait([
        sharedResources(context, widget, fileName, sourceWebId),
        AuthDataManager.getWebId(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.first == SolidFunctionCallStatus.notLoggedIn) {
            return widget.child;
          } else {
            return _buildSharedResourcePage(context, snapshot.data);
          }
        } else {
          return Scaffold(body: loadingScreen(200));
        }
      },
    );
  }
}
