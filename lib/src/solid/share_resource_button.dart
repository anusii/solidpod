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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
// import 'package:solidpod/src/solid/grant_permission_button.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/is_phone.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';
import 'package:solidpod/src/widgets/group_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/ind_webid_input_dialog.dart';

/// A [StatefulWidget] for sharing a resource, by either creating
/// an access permission for a new recipient or updating the access
/// permission of an existing recipient.
///
/// Parameters:
/// - [formKey] - Key of the grant permission form.
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [fileNameController] - The [TextEditingController] for the filename
/// field.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externally owned.
/// - [accessModeList] - List of access mode options to show.
/// - [recipientTypeList] - List of recipient type options to show.
/// - [selectedPermList] - is the list of permissions to be granted to the
/// [finalWebIdList].
/// - [selectedRecipientType] - is the type of the recipient of recipients in the
/// [finalWebIdList].
/// - [finalWebIdList] - is the list of webIds of the recipients
/// receiving access permissions to the file.
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

  // final RecipientType selectedRecipientType;
  // final List<String> selectedPermList;

  //   /// List of webIds for permission

  // final List<dynamic> finalWebIdList;

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
    // required this.selectedRecipientType,
    // required this.selectedPermList,
    // required this.finalWebIdList,
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

  /// Selected resource - assigned once on first Grant button press

  String? dataFile;

  /// A flag to identify if the resource is a file or not

  bool isFile = true;

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

  /// Define recipient type list

  List<RecipientType> recipientTypeList = [];

  // TODO: consider initialising form variables
  // so each form load shows with empty variables
  @override
  void initState() {
    super.initState();

    _fileNameController = widget.fileNameController;
    _ownerWebId = widget.ownerWebId;
    _granterWebId = widget.granterWebId;

    // Load access mode list to be displayed
    for (final accessModeStr in widget.accessModeList) {
      accessModeList.add(getAccessMode(accessModeStr));
    }

    // Load recipient type list to be displayed
    for (final recTypeStr in widget.recipientTypeList) {
      recipientTypeList.add(RecipientType.getInstanceByValue(recTypeStr));
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose(); // Dispose filename editing controller
    groupNameController.dispose(); // Dispose group name editing controller
    groupWebIdsController.dispose(); // Dispose group webids editing controller
    super.dispose();
  }

  bool _getIsFile() => widget.resourceName != null ? widget.isFile : isFile;

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

  /// Sharing (grant permission) form dialog function
  ///
  Future<void> _grantPermissionFormDialog(BuildContext context) async {
    debugPrint('recipientTypeList: ${recipientTypeList.toString()}');

    // 20260118 jesscmoore: if useful could update GrantPermissionUi()
    // variables by adding return variable result to showDialog(), and
    // then checking if result != null then call setState() to update
    // GrantPermissionUi(). updatePermissions() after grantPermission()
    // effectively does this.
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: GrantPermFormLayout.contentPadding,
          title: const Text('Share resource'),
          content: StatefulBuilder(
            builder: (BuildContext stfContext, StateSetter stfSetState) {
              /// Update selected webid list with individual recipient webid
              /// [receiverWebId].
              void updateIndWebIdInput(
                String receiverWebId,
              ) =>
                  stfSetState(() {
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
                  stfSetState(() {
                    selectedRecipientType = RecipientType.group;
                    selectedRecipientDetails =
                        '$groupName with WebIDs ${webIdList.join(', ')}';
                    finalWebIdList = webIdList;
                  });

              /// Define button click actions for each recipient type button
              /// and store in map variable with button click action function
              /// for each recipient type key
              final Map<RecipientType, void Function()> recipientTypeActions = {
                RecipientType.public: () => stfSetState(() {
                      selectedRecipientType = RecipientType.public;
                      selectedRecipientDetails = '';
                      finalWebIdList = [publicAgent.value];
                    }),
                RecipientType.authUser: () => stfSetState(() {
                      selectedRecipientType = RecipientType.authUser;
                      selectedRecipientDetails = '';
                      finalWebIdList = [authenticatedAgent.value];
                    }),
                RecipientType.individual: () async => await indWebIdInputDialog(
                      context,
                      updateIndWebIdInput,
                      widget.dataFilesMap,
                    ),
                RecipientType.group: () async => await groupWebIdInputDialog(
                      context,
                      groupNameController,
                      groupWebIdsController,
                      updateGroupWebIdInput,
                    ),
              };

              /// Update checked status of access mode boxes to show
              /// selected access modes.
              void updateCheckbox(bool newValue, AccessMode accessMode) =>
                  stfSetState(() {
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

              return SizedBox(
                // Use full width on phones, else use a preset narrower width
                width: (!isPhone())
                    ? GrantPermFormLayout.dialogWidth
                    : double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getHeading(
                      'Select the recipient/s of file access permissions',
                    ),
                    // FIXME: update widget name to be more meaningful
                    getRecipientText(
                      selectedRecipientType,
                      selectedRecipientDetails,
                    ),

                    // 20260109 jesscmoore Added capability for granters to share
                    // resources, as well as resource owners
                    getButtonContainer(
                      buttons: widget.isExternalRes
                          // Recipient type buttons for resource granter
                          ? [
                              for (final rtype in granterRecipientTypes)
                                if (recipientTypeList.contains(rtype))
                                  getRecipientTypeButton(
                                    rtype,
                                    onPressed: recipientTypeActions[rtype]!,
                                    padding: getPadding(rtype),
                                  ),
                            ]
                          // Recipient type buttons for resource owner
                          : [
                              for (final rtype in ownerRecipientTypes)
                                if (recipientTypeList.contains(rtype))
                                  Expanded(
                                    child: Container(
                                      padding: getPadding(rtype),
                                      height: 50,
                                      child: MarkdownTooltip(
                                        message: recipientToolTips[rtype]!,
                                        child: ElevatedButton(
                                          onPressed:
                                              recipientTypeActions[rtype]!,
                                          child: Text(rtype.description),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
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
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Grant Permission and update permission map
                // used by permission table
                if (selectedRecipientType.type.isNotEmpty) {
                  if (widget.resourceName != null) {
                    if (selectedPermList.isNotEmpty) {
                      // Assign dataFile if null (first Grant press)
                      dataFile ??=
                          widget.resourceName ?? _fileNameController.text;

                      SolidFunctionCallStatus result;
                      try {
                        // Update ACL and permission logs to grant permission
                        result = await grantPermission(
                          fileName: dataFile!,
                          isFile: _getIsFile(),
                          permissionList: selectedPermList,
                          recipientType: selectedRecipientType,
                          recipientWebIdList: finalWebIdList,
                          ownerWebId: _ownerWebId,
                          granterWebId: _granterWebId,
                          isExternalRes: widget.isExternalRes,
                          groupName:
                              selectedRecipientType == RecipientType.group
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
                          finalWebIdList,
                          selectedPermList,
                        );
                      } else if (result ==
                          SolidFunctionCallStatus.notInitialised) {
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.share,
        ),
        onPressed: () async {
          await _grantPermissionFormDialog(context);
        },
        label: const Text('Share Resource'),
      ),
    );
  }
}
