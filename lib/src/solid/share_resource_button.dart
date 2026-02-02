/// A button for sharing a resource.
///
// Time-stamp: <Saturday 2026-01-17 19:06:10 +1100 Graham Williams>
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
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart' show SharingPageLayout;

import 'package:solidpod/src/solid/grant_permission_form.dart';
import 'package:solidpod/src/solid/utils/alert.dart';

/// A [StatefulWidget] for sharing a resource, by either creating
/// an access permission for a new recipient or updating the access
/// permission of an existing recipient.
///
/// Parameters:
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [fileNameController] - The [TextEditingController] for the filename
/// field.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externally owned.
/// - [accessModeList] - List of access mode options to show.
/// - [recipientTypeList] - List of recipient type options to show.
/// - [isFile] - Boolean flag describing whether the resource is a file. If false, the resource is assumed to be a directory.
/// - [updatePermissionsFunction] is the function to be called to refresh the permission table.
///
/// - [onPermissionGranted] - Callback function called when permissions are granted successfully.

class ShareResourceButton extends StatefulWidget {
  final TextEditingController fileNameController;

  /// String to assign the webId of the resource owner.

  final String ownerWebId;

  /// String to assign the external webId of the resource granter.

  final String granterWebId;

  /// The name of the file or directory that access is being granted for.

  final String? resourceName;

  final bool isExternalRes;

  /// A flag to determine whether the given resource is a file or not.

  final bool isFile;

  /// The list of access modes to be displayed. By default all four types of
  /// access mode are listed.

  final List<String> accessModeList;

  /// The list of types of recipients receiving permission to access the resource. By default all four
  /// types of recipient are listed.

  final List<String> recipientTypeList;

  /// Map of data files on a user's POD used to extract the
  /// user's recipient list by the WebIdTextInputScreen.
  /// If not provided, the WebIdTextInputScreen will read the
  /// user's files in their app data folder on their Pod to
  /// fetch the ACLs needed to derive the user's recipient list.

  final Map<String, dynamic> dataFilesMap;

  /// Function run to update permissions table

  final Function updatePermissionsFunction;

  /// Callback function called when permissions are granted successfully.

  final VoidCallback? onPermissionGranted;

  const ShareResourceButton({
    super.key,
    required this.fileNameController,
    required this.updatePermissionsFunction,
    this.resourceName,
    required this.ownerWebId,
    required this.granterWebId,
    this.accessModeList = const ['read', 'write', 'append', 'control'],
    this.recipientTypeList = const ['public', 'indi', 'auth', 'group'],
    required this.isExternalRes,
    required this.isFile,
    this.dataFilesMap = const {},
    this.onPermissionGranted,
  });

  @override
  State<ShareResourceButton> createState() => _ShareResourceButtonState();
}

class _ShareResourceButtonState extends State<ShareResourceButton> {
  /// Filename text controller

  late final TextEditingController _fileNameController;

  /// Owner WebId

  late final String _ownerWebId;

  /// Granter WebId

  late final String _granterWebId;

  /// Selected resource - assigned on Share Resource button press

  String _resourceName = '';

  /// A flag to identify if the resource is a file or not

  bool isFile = true;

  /// Flag to track if permissions were granted successfully.

  bool permissionsGrantedSuccessfully = false;

  @override
  void initState() {
    super.initState();

    _fileNameController = widget.fileNameController;
    _ownerWebId = widget.ownerWebId;
    _granterWebId = widget.granterWebId;
  }

  @override
  void dispose() {
    _fileNameController.dispose(); // Dispose filename editing controller
    super.dispose();
  }

  /// Mark permissions as granted successfully for callback tracking
  Future<void> _updatePermissionGrantedStatus() async {
    setState(() => permissionsGrantedSuccessfully = true);
  }

  /// Private function to call alert dialog in share resource button
  /// context. This provides an alert dialog over the top of the
  /// grant permission form dialog.
  Future<void> _alert(String msg) async => alert(context, msg);

  // Resource is a file if resource selected in GrantPermissionUi()
  bool _getIsFile() => widget.resourceName != null ? widget.isFile : isFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SharingPageLayout.inputPadding,
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.share,
        ),
        onPressed: () async {
          // Assign dataFile if null (first Grant press)
          _resourceName = widget.resourceName ?? _fileNameController.text;

          if (_resourceName != '') {
            // Display GrantPermissionForm dialog to enter
            // recipient and access modes
            await showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return GrantPermissionForm(
                  resourceName: _resourceName,
                  accessModeList: widget.accessModeList,
                  recipientTypeList: widget.recipientTypeList,
                  updatePermissionsFunction: widget.updatePermissionsFunction,
                  ownerWebId: _ownerWebId,
                  granterWebId: _granterWebId,
                  isExternalRes: widget.isExternalRes,
                  isFile: _getIsFile(),
                  dataFilesMap: widget.dataFilesMap,
                  updatePermissionGrantedFunction:
                      _updatePermissionGrantedStatus,
                  onPermissionGranted: widget.onPermissionGranted,
                );
              },
            );
          } else {
            await _alert(
              'Please select one or more recipients',
            );
          }
        },
        label: const Text('Share Resource'),
      ),
    );
  }
}
