/// A button for sharing a resource.
///
// Time-stamp: <Sunday 2026-01-18 17:06:10 +1100 Graham Williams>
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

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';
import 'package:solidpod/src/solid/select_recipients.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/is_phone.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';
import 'package:solidpod/src/widgets/group_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/ind_webid_input_dialog.dart';

/// Sharing (grant permission) form dialog function
///
/// A [StatefulWidget] for creating a grant permission form
/// dialog to get recipient and access modes to grant for the
/// provided [resourceName]
///
/// Parameters:
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externally owned.
/// - [accessModeList] - List of access mode options to show.
/// - [recipientTypeList] - List of recipient type options to show.
/// - [isFile] - Boolean flag describing whether the resource is a file. If false, the resource is assumed to be a directory.
/// - [updatePermissionsFunction] is the function to be called to refresh the permission table.
/// - [updatePermissionGrantedFunction] - is the function to be called
/// when permissions are granted successfully
/// - [onPermissionGranted] - Callback function called when permissions are granted successfully.

class GrantPermissionForm extends StatefulWidget {
  /// String to assign the webId of the resource owner.

  final String ownerWebId;

  /// String to assign the external webId of the resource granter.

  final String granterWebId;

  /// The name of the file or directory that access is being granted for.

  final String resourceName;

  final bool isExternalRes;

  /// A flag to determine whether the given resource is a file or not.

  final bool isFile;

  /// The list of access modes to show in form. By default
  /// all four types of access mode are listed.

  final List<String> accessModeList;

  /// The list of types of recipients to show in form. By default
  /// all four types of recipient are listed.

  final List<String> recipientTypeList;

  /// Map of data files on a user's POD used to extract the
  /// user's recipient list by the WebIdTextInputScreen.
  /// If not provided, the WebIdTextInputScreen will read the
  /// user's files in their app data folder on their Pod to
  /// fetch the ACLs needed to derive the user's recipient list.

  final Map<String, dynamic> dataFilesMap;

  /// Function run to update permissions table

  final Function updatePermissionsFunction;

  /// Function when permissions are granted successfully

  final Function updatePermissionGrantedFunction;

  /// Callback function called when permissions are granted successfully.

  final VoidCallback? onPermissionGranted;

  const GrantPermissionForm({
    super.key,
    required this.updatePermissionsFunction,
    required this.resourceName,
    required this.ownerWebId,
    required this.granterWebId,
    this.accessModeList = const ['read', 'write', 'append', 'control'],
    this.recipientTypeList = const ['public', 'indi', 'auth', 'group'],
    required this.isExternalRes,
    required this.isFile,
    required this.updatePermissionGrantedFunction,
    this.dataFilesMap = const {},
    this.onPermissionGranted,
  });

  @override
  State<GrantPermissionForm> createState() => _GrantPermissionFormState();
}

class _GrantPermissionFormState extends State<GrantPermissionForm> {
  /// Owner WebId

  late final String _ownerWebId;

  /// Granter WebId

  late final String _granterWebId;

  /// Selected resource being shared

  late final String _resourceName;

  /// Selected recipient

  RecipientType selectedRecipientType = RecipientType.none;

  /// Selected recipient details

  String selectedRecipientDetails = '';

  /// List of webIds for group permission

  List<dynamic> finalWebIdList = [];

  /// Selected list of permissions

  List<String> selectedPermList = [];

  /// Group name text controller

  final groupNameController = TextEditingController();

  /// Group of webIds text controller

  final groupWebIdsController = TextEditingController();

  /// Flag to track if permissions were granted successfully.

  bool permissionsGrantedSuccessfully = false;

  /// read permission checked flag

  bool readChecked = false;

  /// write permission checked flag

  bool writeChecked = false;

  /// control permission checked flag

  bool controlChecked = false;

  /// append permission checked flag

  bool appendChecked = false;

  /// Public permission check flag

  bool publicChecked = false;

  /// Define access mode list

  List<AccessMode> accessModeList = [];

  @override
  void initState() {
    super.initState();

    _resourceName = widget.resourceName;
    _ownerWebId = widget.ownerWebId;
    _granterWebId = widget.granterWebId;

    // Load access mode list to be displayed
    for (final accessModeStr in widget.accessModeList) {
      accessModeList.add(getAccessMode(accessModeStr));
    }
  }

  @override
  void dispose() {
    groupNameController.dispose(); // Dispose group name editing controller
    groupWebIdsController.dispose(); // Dispose group webids editing controller
    super.dispose();
  }

  /// Private function to call alert dialog in share resource button
  /// context. This provides an alert dialog over the top of the
  /// grant permission form dialog.
  Future<void> _alert(String msg) async => alert(context, msg);

  /// Private function to show snackbar in share resource button context
  Future<void> _showSnackBar(
    String msg,
    Color bgColor, {
    Duration duration = const Duration(seconds: 4),
  }) async =>
      showSnackBar(context, msg, bgColor, duration: duration);

  /// Update selected webid list with individual recipient webid
  /// [receiverWebId].
  void updateIndWebIdInput(
    String receiverWebId,
  ) =>
      setState(() {
        selectedRecipientType = RecipientType.individual;
        selectedRecipientDetails = receiverWebId;
        finalWebIdList = [receiverWebId];
      });

  /// Update selected webid list with list of webids in
  /// recipient group [webIdList] and their group name
  /// [groupName].

  void updateGroupWebIdInput(
    String groupName,
    List<dynamic> webIdList,
  ) =>
      setState(() {
        selectedRecipientType = RecipientType.group;
        selectedRecipientDetails =
            '$groupName with WebIDs ${webIdList.join(', ')}';
        finalWebIdList = webIdList;
      });

  /// Update checked status of access mode boxes to show
  /// selected access modes.
  void updateCheckbox(bool newValue, AccessMode accessMode) => setState(() {
        switch (accessMode) {
          case AccessMode.read:
            readChecked = newValue;
          case AccessMode.write:
            writeChecked = newValue;
          case AccessMode.control:
            controlChecked = newValue;
          case AccessMode.append:
            appendChecked = newValue;
        }
        if (newValue) {
          selectedPermList.add(accessMode.mode);
        } else {
          selectedPermList.remove(accessMode.mode);
        }
      });

  /// Define button click actions for each recipient type button

  /// Set recipients to public
  void _setRecipientsToPublic() => setState(() {
        selectedRecipientType = RecipientType.public;
        selectedRecipientDetails = '';
        finalWebIdList = [publicAgent.value];
      });

  /// Set recipients to authorised users
  void _setRecipientsToAuthUsers() => setState(() {
        selectedRecipientType = RecipientType.authUser;
        selectedRecipientDetails = '';
        finalWebIdList = [authenticatedAgent.value];
      });

  /// Select individual recipient
  void _setRecipientsToIndividual() async => await indWebIdInputDialog(
        context,
        updateIndWebIdInput,
        widget.dataFilesMap,
      );

  /// Select a group of recipients
  void _setRecipientsToGroup() async => await groupWebIdInputDialog(
        context,
        groupNameController,
        groupWebIdsController,
        updateGroupWebIdInput,
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: GrantPermFormLayout.contentPadding,
      title: const Text('Share resource'),
      content: SizedBox(
        // Use full width on phones, else use a preset narrower width
        width:
            (!isPhone()) ? GrantPermFormLayout.dialogWidth : double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getHeading(
              'Select the recipient/s of file access permissions',
            ),
            // List selected recipient webids or recipient
            // type (public/auth)
            // TODO: convert to stless widget
            showSelectedRecipients(
              selectedRecipientType,
              selectedRecipientDetails,
            ),

            // Show Select Recipient Buttons
            SelectRecipients(
              isExternalRes: widget.isExternalRes,
              recipientTypeList: widget.recipientTypeList,
              setPublicFunction: _setRecipientsToPublic,
              setAuthUsersFunction: _setRecipientsToAuthUsers,
              setIndividualFunction: _setRecipientsToIndividual,
              setGroupFunction: _setRecipientsToGroup,
              updateIndWebIdFunction: updateIndWebIdInput,
              updateGroupWebIdFunction: updateGroupWebIdInput,
            ),

            smallGapV,
            getHeading(
              'Select the list of file access permissions',
            ),
            // Show access mode checkboxes and update
            // selection status on click
            ...getPermissionCheckBoxes(
              accessModeList,
              modeSwitches: {
                AccessMode.read: readChecked,
                AccessMode.write: writeChecked,
                AccessMode.control: controlChecked,
                AccessMode.append: appendChecked,
              },
              onUpdate: updateCheckbox,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            // Grant Permission and update permission map
            // used by permission table

            if (selectedRecipientType.type.isNotEmpty) {
              if (selectedPermList.isNotEmpty) {
                SolidFunctionCallStatus result;
                try {
                  // Update ACL and permission logs to grant permission
                  result = await grantPermission(
                    fileName: _resourceName,
                    isFile: widget.isFile,
                    permissionList: selectedPermList,
                    recipientType: selectedRecipientType,
                    recipientWebIdList: finalWebIdList,
                    ownerWebId: _ownerWebId,
                    granterWebId: _granterWebId,
                    isExternalRes: widget.isExternalRes,
                    groupName: selectedRecipientType == RecipientType.group
                        ? groupNameController.text.trim()
                        : null,
                  );

                  // Close grant permission dialog
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                } on Object catch (e, stackTrace) {
                  result = SolidFunctionCallStatus.fail;
                  debugPrintException(e, stackTrace);
                }

                if (result == SolidFunctionCallStatus.success) {
                  _showSnackBar(successMsg, Colors.green);
                  // Update permissions table
                  await widget.updatePermissionsFunction(
                    _resourceName,
                    isFile: widget.isFile,
                    isExternalRes: widget.isExternalRes,
                  );

                  // Mark permissions as granted successfully for callback tracking
                  await widget.updatePermissionGrantedFunction();

                  // Trigger the onPermissionGranted callback if provided
                  widget.onPermissionGranted?.call();
                } else if (result == SolidFunctionCallStatus.fail) {
                  // More detailed error message with troubleshooting tips
                  _showSnackBar(failureMsg, Colors.red);

                  // Also log to console for debugging
                  debugPrintFailure(
                    _resourceName,
                    finalWebIdList,
                    selectedPermList,
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
              await _alert('Please select a type of recipient');
            }
          },
          child: const Text('Grant Permission'),
        ),
        TextButton(
          onPressed: () {
            // Close dialog
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
