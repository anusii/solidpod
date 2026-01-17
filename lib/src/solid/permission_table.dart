/// Table listing permissions of a resource.
///
// Time-stamp: <Saturday 2026-01-17 17:25:26 +1100 Graham Williams>
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
/// Authors: Jess Moore, Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/revoke_permission_button.dart';

/// A [StatefulWidget] for listing the permissions of a resource.
///
/// Parameters:
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [permDataMap] is the map of permission data for the [resourceName]
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externally owned.
/// - [isFile] - Boolean flag describing whether the resource is a file. If false, the resource is assumed to be a directory.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [updatePermissionsFunction] is the function to be called to refresh the permission table.
/// - [parentWidget] is the widget to return to after an action Eg: deletion of a
/// permission
///

class PermissionTable extends StatefulWidget {
  /// The name of the file or directory for which permissions are being
  /// shown.

  final String resourceName;

  /// Map of access permission data being displayed for [resourceName].

  final Map<dynamic, dynamic> permDataMap;

  /// WebId of the resource owner.

  final String ownerWebId;

  /// WebId of the user granting/revoking access to the resource.

  final String granterWebId;

  /// A flag denoting whether resource is externally owned.

  final bool isExternalRes;

  /// A flag to determine whether the given resource is a file or not.

  final bool isFile;

  /// Function run to update permissions table

  final Function updatePermissionsFunction;

  /// Parent widget to return to.

  final Widget parentWidget;

  const PermissionTable({
    super.key,
    required this.resourceName,
    required this.permDataMap,
    required this.ownerWebId,
    required this.granterWebId,
    required this.updatePermissionsFunction,
    required this.parentWidget,
    required this.isFile,
    this.isExternalRes = false,
  });

  @override
  State<PermissionTable> createState() => _PermissionTableState();
}

class _PermissionTableState extends State<PermissionTable> {
  /// Controller for horizontal permissions table scrolling
  final tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  DataColumn buildDataColumn(String title, String tooltip) {
    return DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            title,
          ),
        ),
      ),
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make wide permission table horizontally scrollable
    // Shows when content exceeds display width
    return Scrollbar(
      // 20250722 jm:
      // For scrollbar visibility before scrolling,
      // set to true, or set property to true
      // in parent app MaterialApp(theme: ThemeData(scrollbarTheme: scrollbarTheme: ScrollbarThemeData(
      // thumbVisibility: WidgetStateProperty.all(true)))
      thumbVisibility: true, // show before user starts scrolling
      controller: tableScrollController,
      child: SingleChildScrollView(
        controller: tableScrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Row(
              children: [
                DataTable(
                  columns: [
                    buildDataColumn(
                      'Receiver',
                      'WebID of the permission recipient',
                    ),
                    buildDataColumn('Receiver type', 'Type of the receiver'),
                    buildDataColumn('Permissions', 'List of permissions given'),
                    buildDataColumn('Actions', 'Delete permission'),
                  ],
                  // receiverWebId is the webId of each individual with access to the file
                  rows: widget.permDataMap.keys.map((receiverWebId) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                            //width: cWidth,
                            child: Column(
                              children: <Widget>[
                                SelectableText(
                                  (receiverWebId.replaceAll('.ttl', ''))
                                      as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            getRecipientType(
                              widget.permDataMap[receiverWebId][agentStr]
                                  as String,
                              receiverWebId as String,
                            ).description,
                          ),
                        ),
                        DataCell(
                          Text(
                            (widget.permDataMap[receiverWebId][permStr] as List)
                                .join(', '),
                          ),
                        ),
                        // If recipient != owner, then show the delete permission button
                        if (widget.ownerWebId != receiverWebId) ...[
                          DataCell(
                            // Revoke permissions icon button
                            RevokePermissionButton(
                              resourceName: widget.resourceName,
                              permDataMap: widget.permDataMap,
                              receiverWebId: receiverWebId,
                              ownerWebId: widget.ownerWebId,
                              granterWebId: widget.granterWebId,
                              isFile: widget.isFile,
                              isExternalRes: widget.isExternalRes,
                              updatePermissionsFunction:
                                  widget.updatePermissionsFunction,
                            ),
                          ),
                        ] else ...[
                          const DataCell(
                            Text(''),
                          ),
                        ],
                      ],
                    );
                  }).toList(),
                ),
                // Hspace to avoid vertical scrollbar overlap with table
                ScrollbarLayout.horizontalGap,
              ],
            ),
            // Vspace to avoid horizontal scrollbar overlap of table
            ScrollbarLayout.verticalGap,
          ],
        ),
      ),
    );
  }
}
