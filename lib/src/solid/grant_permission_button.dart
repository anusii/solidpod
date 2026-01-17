/// A button for granting permission.
///
// Time-stamp: <Friday 2026-01-16 23:06:26 +1100 Graham Williams>
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
/// Authors: Jess Moore, Anushka Vidanage, Dawei Chen, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';

/// A [StatefulWidget] for the grant permission button. Updates owner's
/// ACL for resource, updates owner, granter, recipient logs,
/// and calls updatePermissions() to refresh permission table data.
///
/// Parameters:
/// - [formKey] - Key of the grant permission form.
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [fileNameController] - The [TextEditingController] for the filename
/// field.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externall owned.
/// - [selectedPermList] - is the list of permissions to be granted to the
/// [finalWebIdList].
/// - [selectedRecipientType] - is the type of the recipient of recipients in the
/// [finalWebIdList].
/// - [finalWebIdList] - is the list of webIds of the recipients
/// receiving access permissions to the file.
/// - [isFile] - Boolean flag describing whether the resource is a file. If false, the resource is assumed to be a directory.
/// - [groupName] - Optional name of the group permission.
/// - [updatePermissionsFunction] is the function to be called to refresh the permission table.
///
/// - [onPermissionGranted] - Callback function called when permissions are granted successfully.

class GrantPermissionButton extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fileNameController;

  /// String to assign the webId of the resource owner.

  final String ownerWebId;

  /// String to assign the external webId of the resource granter.

  final String granterWebId;

  /// The name of the file or directory that access is being granted for.

  final String? resourceName;

  final bool isExternalRes;

  final RecipientType selectedRecipientType;
  final List<String> selectedPermList;

  /// List of webIds for group permission

  final List<dynamic> finalWebIdList;

  /// Optional name of the group permission.

  final String? groupName;

  /// A flag to determine whether the given resource is a file or not.

  final bool isFile;

  /// Function run to update permissions table

  final Function updatePermissionsFunction;

  /// Callback function called when permissions are granted successfully.

  final VoidCallback? onPermissionGranted;

  const GrantPermissionButton({
    super.key,
    required this.formKey,
    required this.fileNameController,
    required this.selectedRecipientType,
    required this.selectedPermList,
    required this.finalWebIdList,
    required this.updatePermissionsFunction,
    this.resourceName,
    required this.ownerWebId,
    required this.granterWebId,
    required this.isExternalRes,
    required this.isFile,
    this.groupName,
    this.onPermissionGranted,
  });

  @override
  State<GrantPermissionButton> createState() => _GrantPermissionButtonState();
}

class _GrantPermissionButtonState extends State<GrantPermissionButton> {
  /// Form controller

  late final GlobalKey<FormState> _formKey;

  /// Filename text controller

  late final TextEditingController _fileNameController;

  /// Selected resource - assigned once on first Grant button press

  String? dataFile;

  /// A flag to identify if the resource is a file or not

  bool isFile = true;

  /// Flag to track if permissions were granted successfully.

  bool permissionsGrantedSuccessfully = false;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey;
    _fileNameController = widget.fileNameController;
  }

  bool _getIsFile() => widget.resourceName != null ? widget.isFile : isFile;

  /// Private function to call alert dialog in grant permission button context
  Future<void> _alert(String msg) async => alert(context, msg);

  /// Private function to show snackbar in grant permission button context
  Future<void> _showSnackBar(
    String msg,
    Color bgColor, {
    Duration duration = const Duration(seconds: 4),
  }) async =>
      showSnackBar(context, msg, bgColor, duration: duration);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            if (widget.selectedRecipientType.type.isNotEmpty) {
              if (widget.resourceName != null) {
                if (widget.selectedPermList.isNotEmpty) {
                  // Assign dataFile if null (first Grant press)
                  dataFile ??= widget.resourceName ?? _fileNameController.text;

                  debugPrint('GrantPermissionButton: dataFile: $dataFile');
                  debugPrint(
                    'GrantPermissionButton: owner: ${widget.ownerWebId}',
                  );
                  debugPrint(
                    'GrantPermissionButton: granter: ${widget.granterWebId}',
                  );
                  SolidFunctionCallStatus result;
                  try {
                    // Update ACL and permission logs to grant permission
                    result = await grantPermission(
                      fileName: dataFile!,
                      isFile: _getIsFile(),
                      permissionList: widget.selectedPermList,
                      recipientType: widget.selectedRecipientType,
                      recipientWebIdList: widget.finalWebIdList,
                      ownerWebId: widget.ownerWebId,
                      granterWebId: widget.granterWebId,
                      isExternalRes: widget.isExternalRes,
                      groupName: widget.groupName,
                    );
                  } on Object catch (e, stackTrace) {
                    result = SolidFunctionCallStatus.fail;
                    debugPrintException(e, stackTrace);
                  }

                  if (result == SolidFunctionCallStatus.success) {
                    _showSnackBar(successMsg, Colors.green);
                    // Update permissions table
                    await widget.updatePermissionsFunction(
                      dataFile,
                      isFile: _getIsFile(),
                      isExternalRes: widget.isExternalRes,
                    );

                    // Mark permissions as granted successfully for callback tracking
                    setState(() => permissionsGrantedSuccessfully = true);

                    // Trigger the onPermissionGranted callback if provided
                    widget.onPermissionGranted?.call();
                  } else if (result == SolidFunctionCallStatus.fail) {
                    // More detailed error message with troubleshooting tips
                    _showSnackBar(failureMsg, Colors.red);

                    // Also log to console for debugging
                    debugPrintFailure(
                      dataFile!,
                      widget.finalWebIdList,
                      widget.selectedPermList,
                    );
                  } else if (result == SolidFunctionCallStatus.notInitialised) {
                    _showSnackBar(podNotInitMsg, warnBgColor);
                  } else {
                    await _alert(updatePermissionMsg);
                  }
                } else {
                  await _alert(
                    'Please select one or more file access permissions',
                  );
                }
              } else {
                await _alert(
                  'Please select one or more recipients',
                );
              }
            } else {
              await _alert('Please select a type of recipient');
            }
          }
        },
        child: const Text('Grant Permission'),
      ),
    );
  }
}
