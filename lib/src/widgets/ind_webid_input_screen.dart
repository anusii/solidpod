/// A screen to retrieve all the webids of recipients of a user's Pod files before loading the webid input dialog.
///
// Time-stamp: <Monday 2025-07-28 12:29:01 +1000 Jess Moore>
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
///
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/get_recipient_list.dart';
import 'package:solidpod/src/widgets/ind_webid_input.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A screen that runs before opening the WebID input dialog, which
/// retrieves the list of files in the owner's pod.
///
/// Parameters:
/// - [onSubmitFunction] is the function to be called on submit
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
  /// Future comprising the unique recipient WebId list of the user's Pod data.
  static Future<List<String>>? _asyncGetRecipList;

  /// List of unique recipient WebId list of the user's Pod data.
  List<String> uniqRecipWebIdList = [];

  @override
  void initState() {
    // Retrieve files and derive unique recipient WebId list.
    if (widget.dataFilesMap.isEmpty) {
      _asyncGetRecipList = getRecipientList();
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
    return IndWebIdTextInput(
      onSubmitFunction: onSubmitFunction,
      uniqRecipWebIdList: uniqRecipWebIdList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return (widget.dataFilesMap.isNotEmpty)
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
          );
  }
}
