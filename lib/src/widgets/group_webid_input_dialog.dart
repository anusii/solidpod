/// A dialog to input individual WebID.
///
// Time-stamp: <Sunday 2024-07-11 12:23:00 +1000 Anushka Vidange>
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
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/alert.dart';

/// A dialog for adding a group of Web IDs. Function call requires the following
/// inputs
/// [context] is the BuildContext from which this function is called.
/// [formControllerGroupName] is the controller for the group name input
/// [formControllerGroupWebIds] is the controller for the list of webids input
/// [onSubmitFuncion] is the function to be called on submit
///
Future<dynamic> groupWebIdInputDialog(
  BuildContext context,
  TextEditingController formControllerGroupName,
  TextEditingController formControllerGroupWebIds,
  Function onSubmitFuncion,
) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 50),
        title: const Text('Group of WebIDs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group name. Should be a single string
            TextFormField(
              controller: formControllerGroupName,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'Multiple words will be combined using the symbol -',
              ),
            ),
            const SizedBox(height: 10.0),
            // List of Web IDs divided by semicolon
            TextFormField(
              controller: formControllerGroupWebIds,
              decoration: const InputDecoration(
                labelText: 'List of WebIDs',
                hintText: 'Divide multiple WebIDs using the semicolon (;)',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              // Check if all the input entries are correct
              final groupName = formControllerGroupName.text.trim();
              final groupWebIds = formControllerGroupWebIds.text.trim();

              // Check if both fields are not empty
              if (groupName.isNotEmpty && groupWebIds.isNotEmpty) {
                final webIdList = groupWebIds.split(';');

                // Check if all the webIds are true links
                var trueWebIdsFlag = true;
                for (final webId in webIdList) {
                  if (!Uri.parse(webId.replaceAll('#me', '')).isAbsolute ||
                      !(await checkResourceStatus(webId) ==
                          ResourceStatus.exist)) {
                    trueWebIdsFlag = false;
                  }
                }

                if (trueWebIdsFlag) {
                  onSubmitFuncion(groupName, webIdList);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                } else {
                  if (!context.mounted) return;
                  await alert(
                    context,
                    'At least one of the Web IDs you entered is not valid',
                  );
                }
              } else {
                if (!context.mounted) return;
                await alert(
                  context,
                  'Please enter a group name and a list of Web IDs',
                );
              }
            },
            child: const Text('Ok'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
