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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/models/permission.dart';
import 'package:solidpod/src/solid/revoke_permission_button.dart';
import 'package:solidpod/src/solid/utils/permission_helper.dart';

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

  /// Layout constraints

  final BoxConstraints constraints;

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
    required this.constraints,
  });

  @override
  State<PermissionTable> createState() => _PermissionTableState();
}

class _PermissionTableState extends State<PermissionTable> {
  /// Searched/sorted notes
  List<Permission> _permissions = [];

  /// Aspect ratio (width / height) for gridview
  /// cards to display note items
  late double cardAspectRatio = 2.0;

  /// Boolean describing whether window is narrow
  late bool isNarrow;

  /// Scroll controller for single child scroll view
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

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

    //  By default _permissions is the full list of permissions
    _permissions = permMapToList(widget.permDataMap);

    return Expanded(
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Aspect ratio calculated from LayoutBuilder box constraints
          crossAxisCount: 1,
          childAspectRatio: cardAspectRatio,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: _permissions.length, //widget.permDataMap.length,
        itemBuilder: (context, index) => Card(
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: MarkdownTooltip(
                message: _permissions[index].toolTip,
                child: ListTile(
                  // Leading icon denoting agreement of access terms
                  leading: SizedBox(
                    width: ListIconSize.width,
                    child: Center(
                      child: Ink(
                        padding: const EdgeInsets.all(8),
                        decoration: listIconShape,
                        child: const Icon(Icons.handshake),
                      ),
                    ),
                  ),
                  // Permission item title
                  title: Text(
                    _permissions[index].recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Recipient type: ${_permissions[index].recipientType} \n'
                    'WebId: ${_permissions[index].recipientWebId} \n'
                    'Permissions: ${_permissions[index].permList.join(', ')}',
                    maxLines: 4, // Limit to 4 lines
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show revoke button for recipientWebId != ownerWebId
                  trailing: (widget.ownerWebId !=
                          _permissions[index].recipientWebId)
                      ? SizedBox(
                          height: ListIconSize.height,
                          width: ListIconSize.twoIconWidth,
                          child: RevokePermissionButton(
                            resourceName: widget.resourceName,
                            permDataMap: widget.permDataMap,
                            receiverWebId: _permissions[index].recipientWebId,
                            ownerWebId: widget.ownerWebId,
                            granterWebId: widget.granterWebId,
                            isFile: widget.isFile,
                            isExternalRes: widget.isExternalRes,
                            updatePermissionsFunction:
                                widget.updatePermissionsFunction,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
