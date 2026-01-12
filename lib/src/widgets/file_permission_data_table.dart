/// A table displaying permission data for a given file.
///
// Time-stamp: <Sunday 2024-07-11 12:55:00 +1000 Anushka Vidange>
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
///
/// Authors: Anushka Vidanage, Jess Moore

library;

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/revoke_permission.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';

/// Build the permission table widget. Function call requires the
/// following inputs
/// [context] is the BuildContext from which this function is called.
/// [permDataResource] is the name of the file or directory for which the
/// permission data is displayed
/// [isFile] is the flag to define whether the resource is a file or not
/// [permDataMap] is the map of permission data for the [permDataResource]
/// [parentWidget] is the widget to return to after an action Eg: deletion of a
/// permission
/// [onDeleteFuncion] is the function to be called on delete
///
Widget buildPermDataTable({
  required BuildContext context,
  required String permDataResource,
  required bool isFile,
  required Map<dynamic, dynamic> permDataMap,
  required String ownerWebId,
  required Widget parentWidget,
  required Function onDeleteFuncion,
  bool isExternalRes = false,
}) {
  DataColumn buildDataColumn(String title, String tooltip) {
    return DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            title,
          ),
        ),
      ),
      tooltip: tooltip,
    );
  }

  // Make wide permission table horizontally scrollable
  // Shows when content exceeds display width
  return DataTable(
    columns: [
      buildDataColumn(
        'Receiver',
        'WebID of the POD receiving permissions',
      ),
      buildDataColumn('Receiver type', 'Type of the receiver'),
      buildDataColumn('Permissions', 'List of permissions given'),
      buildDataColumn('Actions', 'Delete permission'),
    ],
    rows: permDataMap.keys.map((index) {
      return DataRow(
        cells: [
          DataCell(
            Container(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              //width: cWidth,
              child: Column(
                children: <Widget>[
                  SelectableText(
                    (index.replaceAll('.ttl', '')) as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          DataCell(
            Text(
              getRecipientType(
                permDataMap[index][agentStr] as String,
                index as String,
              ).description,
            ),
          ),
          DataCell(
            Text(
              (permDataMap[index][permStr] as List).join(', '),
            ),
          ),
          if (ownerWebId != index) ...[
            DataCell(
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 24.0,
                  color: Colors.red,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Please Confirm'),
                        content: Text(
                          'Are you sure you want to remove the [${(permDataMap[index][permStr] as List).join(', ')}] permission/s from ${index.replaceAll('.ttl', '')}?',
                        ),
                        actions: [
                          // The "Yes" button
                          TextButton(
                            onPressed: () async {
                              await revokePermission(
                                fileName: permDataResource,
                                isFile: isFile,
                                permissionList:
                                    permDataMap[index][permStr] as List,
                                removerIndOrGroupWebId: index,
                                ownerWebId: ownerWebId,
                                recipientType: getRecipientType(
                                  permDataMap[index][agentStr] as String,
                                  index,
                                ),
                                isExternalRes: isExternalRes,
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
                              await onDeleteFuncion(
                                permDataResource,
                                isFile: isFile,
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
              ),
            ),
          ] else ...[
            const DataCell(
              Text(''),
            ),
          ],
        ],
      );
    }).toList(),
  );
}
