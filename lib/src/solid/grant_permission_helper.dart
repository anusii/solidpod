/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Wednesday 2025-10-08 15:39:39 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
///
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang, Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart' show SharingPageLayout;

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/widgets/permission_checkbox.dart';

const recipientToolTips = <RecipientType, String>{
  RecipientType.public: '''
 **Public:** This file will be publicly
 accessible so that even users without a
 Data Vault can access the file.
 ''',
  RecipientType.authUser: '''
**Users:** The file will be available to
any user who has registered a Data
Vault. When they have logged into their
Data Vault they will be able to access
the file.
''',
  RecipientType.individual: '''
**Individual:** The file will be available
only to the identified individual user. A
WebID is required to identify the
individual who is gratned access to the
file.
''',
  RecipientType.group: '''
**Group:** A collection of WebIDs can be
provided so that as a group they can
access the file.
''',
};

// const selectRecipientPermissionStr =
//    'Select the recipient/s of file access permissions';
// const selectFilePermissionStr = 'Select the list of file access permissions';
// const grantPermissionStr = 'Granted file access permissions';
// const selectPermissionMsg = 'Please select one or more file access permissions';
// const selectRecipientTypeMsg = 'Please select a type of recipient';
const updatePermissionMsg =
    'Please login first to update file access permission';
const podNotInitMsg =
    'The owner of one or more WebIds you entered have not initialised their PODs yet! They need to login and setup their POD first.';
const noAclMsg = 'Resource does not have a corresponding ACL file.\n'
    'If the ACL is inherited, provide parent directory as the resource name!';
const successMsg = 'File access permissions granted successfully!';
const failureMsg =
    'Permission granting failed. Check console logs for details. Common issues: resource not found, invalid WebID format, or network connectivity.';

String getFailureMsg(String fileName) =>
    '❌ [GrantPermissionUI] Permission granting failed for file: $fileName';

String getRecipientMsg(List<dynamic>? finalWebIdList) =>
    '🎯 [GrantPermissionUI] Recipients: $finalWebIdList';

String getPermissionMsg(List<String> permissionList) =>
    '🔐 [GrantPermissionUI] Permissions: $permissionList';

String getExceptionMsg(Object e) =>
    '💥 [GrantPermissionUI] Exception in grantPermission: $e';

String getStackTraceMsg(StackTrace stackTrace) =>
    '📚 [GrantPermissionUI] Stack trace: $stackTrace';

void debugPrintException(Object e, StackTrace stackTrace) {
  debugPrint(getExceptionMsg(e));
  debugPrint(getStackTraceMsg(stackTrace));
}

void debugPrintFailure(
  String fileName,
  List<dynamic>? finalWebIdList,
  List<String> permissionList,
) {
  debugPrint(getFailureMsg(fileName));
  debugPrint(getRecipientMsg(finalWebIdList));
  debugPrint(getPermissionMsg(permissionList));
}

/// Relevant recipients types for resource sharing by the resource owner.
const ownerRecipientTypes = [
  RecipientType.public,
  RecipientType.authUser,
  RecipientType.individual,
  RecipientType.group,
];

/// Relevant recipient types for resource sharing by the resource granter (ie. an entity with control access).
const granterRecipientTypes = [
  RecipientType.individual,
  RecipientType.group,
];

/// Get title of sharing page
String makeSharingTitleStr({
  String? fileName,
  bool isFile = false,
}) =>
    fileName != null
        ? isFile
            ? 'Share $fileName'
            : 'Share $fileName folder'
        : 'Share your data with other user\'s PODs';

List<Widget> getPermissionCheckBoxes(
  List<AccessMode> accessModes, {
  required Map<AccessMode, bool> modeSwitches,
  required Function onUpdate,
}) =>
    [
      for (final mode in AccessMode.getAllModes())
        if (accessModes.contains(mode))
          permissionCheckbox(mode, modeSwitches[mode]!, onUpdate),
    ];

Widget getResourceForm({
  required TextEditingController formController,
  required bool isFile,
  required void Function(bool) onResourceTypeChange,
}) =>
    Padding(
      padding: SharingPageLayout.inputPadding,
      child: Column(
        children: [
          TextFormField(
            controller: formController,
            decoration: const InputDecoration(
              hintText:
                  'Data file path (inside your data folder, Eg: personal/about.ttl)',
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Empty field' : null,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text(
              'Is a File?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isFile ? 'Yes' : 'No',
            ),
            value: isFile,
            onChanged: onResourceTypeChange,
            thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) =>
                  states.contains(WidgetState.selected) ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
