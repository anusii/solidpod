/// A button for revoking permission.
///
// Time-stamp: <Saturday 2026-01-17 16:21:26 +1100 Graham Williams>
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
import 'package:solidpod/src/solid/revoke_permission.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';

/// A [StatefulWidget] for the revoke permission icon button. Updates
/// owner's ACL for resource, updates owner, granter, recipient logs,
/// and calls updatePermissions() to refresh permission table data.
///
/// Parameters:
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [permDataMap] is the map of permission data for the [resourceName]
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externally owned.
/// - [receiverWebId] - WebId with access to the resource, one of ownerWebId, granterWebId or recipientWebId.
/// - [isFile] - Boolean flag describing whether the resource is a file. If false, the resource is assumed to be a directory.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [updatePermissionsFunction] is the function to be called to refresh the permission table.
///

class RevokePermissionButton extends StatefulWidget {
  /// The name of the file or directory for which permissions are being
  /// shown.

  final String resourceName;

  /// Map of access permission data being displayed for [resourceName].

  final Map<dynamic, dynamic> permDataMap;

  /// WebId with access to resource.

  final String receiverWebId;

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

  const RevokePermissionButton({
    super.key,
    required this.resourceName,
    required this.permDataMap,
    required this.receiverWebId,
    required this.ownerWebId,
    required this.granterWebId,
    required this.updatePermissionsFunction,
    required this.isFile,
    this.isExternalRes = false,
  });

  @override
  State<RevokePermissionButton> createState() => _RevokePermissionButtonState();
}

class _RevokePermissionButtonState extends State<RevokePermissionButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete, size: 24.0, color: Colors.red),
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Please Confirm'),
              content: Text(
                'Are you sure you want to remove the [${(widget.permDataMap[widget.receiverWebId][permStr] as List).join(', ')}] permission/s from ${widget.receiverWebId.replaceAll('.ttl', '')}?',
              ),
              actions: [
                // The "Yes" button
                TextButton(
                  onPressed: () async {
                    await revokePermission(
                      fileName: widget.resourceName,
                      isFile: widget.isFile,
                      permissionList:
                          widget.permDataMap[widget.receiverWebId][permStr]
                              as List,
                      recipientIndOrGroupWebId: widget.receiverWebId,
                      ownerWebId: widget.ownerWebId,
                      granterWebId: widget.granterWebId,
                      recipientType: getRecipientType(
                        widget.permDataMap[widget.receiverWebId][agentStr]
                            as String,
                        widget.receiverWebId,
                      ),
                      isExternalRes: widget.isExternalRes,
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (ctx.mounted) {
                      showSnackBar(
                        context,
                        'Permission revoked successfully!',
                        Colors.red,
                      );
                    }
                    await widget.updatePermissionsFunction(
                      widget.resourceName,
                      isFile: widget.isFile,
                    );
                  },
                  child: const Text('Yes'),
                ),
                TextButton(
                  onPressed: () {
                    // Close the dialog
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('No'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
