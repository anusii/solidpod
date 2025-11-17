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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
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

const warnBgColor = Color.fromARGB(255, 204, 99, 1);

/// Small vertical spacing for the widget.
const smallGapV = SizedBox(height: 10.0);

/// Large vertical spacing for the widget.
const largeGapV = SizedBox(height: 40.0);

const relevantRecipientTypes = [
  RecipientType.public,
  RecipientType.authUser,
  RecipientType.individual,
  RecipientType.group,
];

String getWelcomeStr(String? fileName) => fileName != null
    ? 'Share $fileName resource with other PODs'
    : 'Share your data resources with other PODs';

Widget getHeading(String text) => buildHeading(
      text,
      17.0,
      Colors.blueGrey,
      8,
    );

EdgeInsetsGeometry? getPadding(RecipientType rtype) =>
    rtype == RecipientType.public ? null : const EdgeInsets.only(left: 8.0);

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

Widget getButton(
  String text, {
  required void Function() onPressed,
}) =>
    Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );

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

Widget getResourceForm({
  required TextEditingController formController,
  required bool isFile,
  required void Function(bool) onResourceTypeChange,
}) =>
    Padding(
      padding: const EdgeInsets.all(8),
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

Widget getRecipientText(RecipientType recipientType, String recipientDetails) =>
    Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text(
            'Recipient/s: ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              '${recipientType.type}${recipientDetails.isEmpty ? "" : " ($recipientDetails)"}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                // 20251008 gjw Choose blue rather than
                // orange which looks red. The red looks
                // like it is an error. Blue is more
                // neutral.
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );

Scrollbar getScrollbar({
  required ScrollController controller,
  required Axis direction,
  required Widget child,
}) =>
    Scrollbar(
      // 20250722 jm:
      // For scrollbar visibility before scrolling,
      // set to true, or set property to true
      // in parent app MaterialApp(theme: ThemeData(scrollbarTheme: scrollbarTheme: ScrollbarThemeData(
      // thumbVisibility: WidgetStateProperty.all(true)))
      thumbVisibility: true, // show before user starts scrolling
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: direction,
        child: child,
      ),
    );

Scrollbar getFormScrollbar(ScrollController controller, Widget permDataTable) =>
    getScrollbar(
      controller: controller,
      direction: Axis.horizontal,
      child: Column(
        children: [
          Row(
            children: [
              permDataTable,
              // Hspace to avoid vertical scrollbar overlap with table
              ScrollbarLayout.horizontalGap,
            ],
          ),
          // Vspace to avoid horizontal scrollbar overlap of table
          ScrollbarLayout.verticalGap,
        ],
      ),
    );

Scrollbar getPageScrollbar(ScrollController controller, Widget form) =>
    getScrollbar(
      controller: controller,
      direction: Axis.vertical,
      child: Column(
        children: [
          smallGapV,
          form,
        ],
      ),
    );

Container getButtonContainer({required List<Widget> buttons}) => Container(
      padding: const EdgeInsets.all(8.0),
      height: 100,
      child: Row(
        children:
            // av 20250526:
            // Public and Authenticated users buttons are
            // disabled in this function at the moment because
            // providing public or authenticated permissions to
            // external resources is not yet implemented in
            // [grantPermission()] function.
            buttons,
      ),
    );

// ElevatedButton getRetrieveButton(
//   BuildContext context,
//   String fileName,
//   bool isFile, {
//   required Future<void> Function(
//     String, {
//     bool isFile,
//   }) onRetrieve,
// }) =>
//     ElevatedButton(
//       child: const Text('Retrieve permissions'),
//       onPressed: () async {
//         if (fileName.isEmpty) {
//           await alert(context, 'Please enter a file name');
//         } else {
//           await onRetrieve(fileName, isFile: isFile);
//         }
//       },
//     );

Form getForm({
  required Key formKey,
  required Widget welcomeHeading,
  required List<Widget> children,
}) =>
    Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            welcomeHeading,
            smallGapV,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ],
        ),
      ),
    );
