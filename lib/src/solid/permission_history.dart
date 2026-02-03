/// Table listing permission history of a resource.
///
// Time-stamp: <Sunday 2026-02-01 20:11:30 +1100 Graham Williams>
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/models/log_record.dart';

/// A [StatefulWidget] for listing the permission history of a resource.
///
/// Parameters:
/// - [resourceName] - The filename or file url of the resource.
/// - [permHistory] is the [List<LogRecord>] comprising permission history for the [resourceName].
///

class PermissionHistory extends StatefulWidget {
  /// The name of the file or directory for which permissions are being
  /// shown.

  final String resourceName;

  /// Map of access permission data being displayed for [resourceName].

  final List<LogRecord> permHistory;

  /// Layout constraints

  final BoxConstraints constraints;

  const PermissionHistory({
    super.key,
    required this.resourceName,
    required this.permHistory,
    required this.constraints,
  });

  @override
  State<PermissionHistory> createState() => _PermissionHistoryState();
}

class _PermissionHistoryState extends State<PermissionHistory> {
  /// Searched/sorted logs
  List<LogRecord> _permHistory = [];

  /// Aspect ratio (width / height) for gridview
  /// cards to display log items
  late double cardAspectRatio = 2.0;

  /// Boolean describing whether window is narrow
  late bool isNarrow;

  /// Scroll controller for single child scroll view
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    //  By default _permissions is the full list of permissions
    _permHistory = widget.permHistory;

    // Create scroll controller
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Derive whether window is narrow
    isNarrow = WindowSize().isNarrowWindow(widget.constraints);
    // Calculate the aspect radio for grid cards
    cardAspectRatio =
        ListItemSize().calculateCardAspectRatio(widget.constraints);

    return Expanded(
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Aspect ratio calculated from LayoutBuilder box constraints
          crossAxisCount: 1,
          childAspectRatio: cardAspectRatio,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: _permHistory.length, //widget.permDataMap.length,
        itemBuilder: (context, index) => Card(
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: MarkdownTooltip(
                message: _permHistory[index].toolTip,
                child: ListTile(
                  // Leading icon denoting agreement of access terms
                  leading: SizedBox(
                    width: ListIconSize.width,
                    child: Center(
                      child: Ink(
                        padding: const EdgeInsets.all(8),
                        decoration: listIconShape,
                        child: Icon(
                          _permHistory[index].permissionType == 'grant'
                              ? Icons.person_add
                              : Icons.person_remove,
                        ),
                        // 20260201 jesscmoore Alternatives tried:
                        // insert_drive_file, list, lock and lock_open, mode_edit,my_library_books, note, notes, person_add, person_remove, playlist_add, playlist_remove, public, public_off, post_add, receipt, receipt_long, recent_actors,
                      ),
                    ),
                  ),
                  // Permission item title

                  title: Text(
                    '${_permHistory[index].dateTime}: '
                    '${_permHistory[index].recipientName} '
                    '${_permHistory[index].permissionTypeLabel} '
                    '${_permHistory[index].permissionList} '
                    'access',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Granter: ${_permHistory[index].granterName}',
                    maxLines: 3, // Limit lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
