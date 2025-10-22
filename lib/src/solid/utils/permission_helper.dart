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
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/heading.dart';
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

const selectRecipientPermissionStr =
    'Select the recipient/s of file access permissions';
const selectFilePermissionStr = 'Select the list of file access permissions';
const grantPermissionStr = 'Granted file access permissions';
const selectPermissionMsg = 'Please select one or more file access permissions';
const selectRecipientTypeMsg = 'Please select a type of recipient';
const updatePermissionMsg =
    'Please login first to update file access permission';
const podNotInitMsg =
    'The owner of one or more WebIds you entered have not initialised their PODs yet! They need to login and setup their POD first.';
const successMsg = 'File access permissions granted successfully!';
const failureMsg =
    'Permission granting failed. Check console logs for details. Common issues: resource not found, invalid WebID format, or network connectivity.';

const warnBgColor = Color.fromARGB(255, 204, 99, 1);

// Widget getRecipientTypeWidget(
//   RecipientType recipientType, {
//   bool padLeft = true,
// }) {
//   assert(recipientType != RecipientType.none);
//   return Expanded(
//     child: Container(
//       padding: padLeft ? const EdgeInsets.only(left: 8.0) : null,
//       height: 50,
//       child: MarkdownTooltip(
//         message: recipientToolTips[recipientType]!,
//         child: ElevatedButton(
//           onPressed: () async {
//             switch (recipientType) {
//               case RecipientType.individual:
//                 // Open dialog for WebId entry
//                 await indWebIdInputDialog(
//                   context,
//                   _updateIndWebIdInput,
//                   widget.dataFilesMap,
//                 );
//               case RecipientType.group:
//                 await groupWebIdInputDialog(
//                   context,
//                   formControllerGroupName,
//                   formControllerGroupWebIds,
//                   _updateGroupWebIdInput,
//                 );
//               default:
//                 setState(() {
//                   selectedRecipientType = recipientType;
//                   selectedRecipientDetails = '';
//                   finalWebIdList = [
//                     recipientType == RecipientType.public
//                         ? publicAgent.value
//                         : authenticatedAgent.value,
//                   ];
//                 });
//             }
//           },
//           child: Text(
//             recipientType.description,
//           ),
//         ),
//       ),
//     ),
//   );
// }

String getWelcomeStr(String? fileName) => fileName != null
    ? 'Share $fileName file with other PODs'
    : 'Share your data files with other PODs';

Widget getHeading(String text) => buildHeading(
      text,
      17.0,
      Colors.blueGrey,
      8,
    );

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

Widget getRecipientTypeButton(
  RecipientType recipientType, {
  required void Function() onPressed,
  EdgeInsetsGeometry? padding,
}) {
  assert(recipientType != RecipientType.none);
  return Expanded(
    child: Container(
      padding: padding,
      height: 50,
      child: MarkdownTooltip(
        message: recipientToolTips[recipientType]!,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(recipientType.description),
        ),
      ),
    ),
  );
}

Widget getResourcePathForm(TextEditingController formController) => Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        controller: formController,
        decoration: const InputDecoration(
          hintText:
              'Data file path (inside your data folder, Eg: personal/about.ttl)',
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Empty field' : null,
      ),
    );
