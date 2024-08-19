/// A dialog to input Group of WebIDs.
///
// Time-stamp: <Sunday 2024-07-11 12:28:00 +1000 Anushka Vidange>
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

/// A dialog for adding an individual webId. Function call requires the
/// following inputs
/// [context] is the BuildContext from which this function is called.
/// [formControllerWebId] is the controller for the webid input
/// [onSubmitFuncion] is the function to be called on submit
///
Future<dynamic> indWebIdInputDialog(
  BuildContext context,
  TextEditingController formControllerWebId,
  Function onSubmitFuncion,
) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 50),
        title: const Text('WebID of the recipient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Web ID text field
            TextFormField(
              controller: formControllerWebId,
              decoration: const InputDecoration(
                hintText:
                    'Eg: https://pods.solidcommunity.au/john-doe/profile/card#me',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              final receiverWebId = formControllerWebId.text.trim();

              // Check the web ID field is not empty and it is a true link
              if (receiverWebId.isNotEmpty &&
                  Uri.parse(receiverWebId.replaceAll('#me', '')).isAbsolute &&
                  await checkResourceStatus(receiverWebId) ==
                      ResourceStatus.exist) {
                onSubmitFuncion(receiverWebId);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              } else {
                if (!context.mounted) return;
                await alert(context, 'Please enter a valid WebID');
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
