/// A screen to retrieve all the webids of recipients of a user's Pod files before loading the webid input dialog.
///
// Time-stamp: <Monday 2025-07-28 12:29:01 +1000 Jess Moore>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
///
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/get_recipient_list.dart';
import 'package:solidpod/src/widgets/ind_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A screen that runs before opening the WebID input dialog, which
/// retrieves the list of files in the owner's pod.
/// Calling this class requires the following inputs:
/// [onSubmitFunction] is the function to be called on submit
///
class IndWebIdInputScreen extends StatefulWidget {
  /// Initialise widget variables.
  const IndWebIdInputScreen({
    required this.onSubmitFunction,
    this.dataFilesMap = const {},
    super.key,
  });

  /// Function run on Submit button press.
  final Function onSubmitFunction;

  /// Map of data files on a user's POD used to extract the
  /// user's recipient list by the WebIdTextInputScreen.
  /// If not provided, the file list must be read to obtain
  /// the user's recipient list used in the WebIdTextInputScreen.
  final Map<String, dynamic> dataFilesMap;

  @override
  State<IndWebIdInputScreen> createState() => _IndWebIdInputScreenState();
}

class _IndWebIdInputScreenState extends State<IndWebIdInputScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Future comprising the unique recipient WebId list of the user's Pod data.
  static Future<List<String>>? _asyncGetRecipList;

  /// List of unique recipient WebId list of the user's Pod data.
  List<String> uniqRecipWebIdList = [];

  @override
  void initState() {
    // Retrieve files and derive unique recipient WebId list.
    if (widget.dataFilesMap.isEmpty) {
      _asyncGetRecipList = getRecipientList(
        context,
        IndWebIdInputScreen(
          onSubmitFunction: widget.onSubmitFunction,
        ),
      );
    } else {
      // Extract unique recipient WebId list if file data provided.
      uniqRecipWebIdList = extractRecipWebIdList(widget.dataFilesMap);
    }
    super.initState();
  }

  // Load Individual WebId Text Input
  Widget _loadIndWebIdTextInput(
    Function onSubmitFunction, [
    List<String> uniqRecipWebIdList = const [],
  ]) {
    return Container(
      color: Colors.white,

      // Run get access lists fetching screen
      child: IndWebIdTextInput(
        onSubmitFunction: onSubmitFunction,
        uniqRecipWebIdList: uniqRecipWebIdList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: (widget.dataFilesMap.isNotEmpty)
            ? _loadIndWebIdTextInput(
                widget.onSubmitFunction,
                uniqRecipWebIdList,
              )
            : FutureBuilder(
                future: _asyncGetRecipList,
                builder: (context, snapshot) {
                  Widget returnVal;
                  if (snapshot.connectionState == ConnectionState.done) {
                    return snapshot.data == null ||
                            snapshot.data.toString() == 'null' ||
                            snapshot.data == []
                        // Load Individual WebId Input Dialog Screen without recipient list
                        ? returnVal =
                            _loadIndWebIdTextInput(widget.onSubmitFunction)
                        // Load Individual WebId Input Dialog Screen with recipient list
                        : returnVal = _loadIndWebIdTextInput(
                            widget.onSubmitFunction,
                            snapshot.data!,
                          );
                  } else {
                    returnVal = loadingScreen(normalLoadingScreenHeight);
                  }
                  return returnVal;
                },
              ),
      ),
    );
  }
}
