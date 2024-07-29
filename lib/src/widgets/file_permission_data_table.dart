/// A table displaying permission data for a given file.
///
// Time-stamp: <Sunday 2024-07-11 12:55:00 +1000 Anushka Vidange>
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

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/revoke_permission.dart';

/// Build the permission table widget. Function call requires the
/// following inputs
/// [context] is the BuildContext from which this function is called.
/// [permDataFile] is the name of the file for which the permission data is
/// displayed
/// [permDataMap] is the map of permission data for the [permDataFile]
/// [parentWidget] is the widget to return to after an action Eg: deletion of a
/// permission
///
Widget buildPermDataTable(BuildContext context, String permDataFile,
    Map<dynamic, dynamic> permDataMap, String ownerWebId, Widget parentWidget) {
  DataColumn buildDataColumn(String title, String tooltip) {
    return DataColumn(
        label: Expanded(
          child: Center(
            child: Text(
              title,
            ),
          ),
        ),
        tooltip: tooltip);
  }

  return DataTable(
    columns: [
      buildDataColumn('Receiver', 'WebID of the POD receiving permissions'),
      buildDataColumn('Receiver type', 'Type of the receiver'),
      buildDataColumn('Permissions', 'List of permissions given'),
      buildDataColumn('Actions', 'Delete permission'),
    ],
    rows: permDataMap.keys.map((index) {
      return DataRow(cells: [
        DataCell(Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          //width: cWidth,
          child: Column(
            children: <Widget>[
              SelectableText(
                (index.replaceAll('.ttl', '')) as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
        )),
        DataCell(
          Text(
            getRecipientType(
                    permDataMap[index][agentStr] as String, index as String)
                .type,
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
                              'Are you sure you want to remove the [${(permDataMap[index][permStr] as List).join(', ')}] permission/s from ${index.replaceAll('.ttl', '')}?'),
                          actions: [
                            // The "Yes" button
                            TextButton(
                                onPressed: () async {
                                  await revokePermission(
                                      permDataFile,
                                      true,
                                      permDataMap[index][permStr] as List,
                                      index,
                                      getRecipientType(
                                          permDataMap[index][agentStr]
                                              as String,
                                          index),
                                      context,
                                      parentWidget);

                                  if (!context.mounted) return;
                                  await Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => parentWidget,
                                    ),
                                  );
                                },
                                child: const Text('Yes')),
                            TextButton(
                                onPressed: () {
                                  // Close the dialog
                                  Navigator.of(ctx).pop();
                                },
                                child: const Text('No'))
                          ],
                        );
                      });
                }),
          )
        ] else ...[
          const DataCell(
            Text(''),
          ),
        ],
      ]);
    }).toList(),
  );
}
