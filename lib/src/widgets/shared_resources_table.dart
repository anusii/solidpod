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

import 'package:solidpod/src/solid/read_external_pod.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/api/common_permission.dart';

/// Build the permission table widget. Function call requires the
/// following inputs
/// [context] is the BuildContext from which this function is called.
/// [sharedResMap] is the map containing data of shared resources.
/// [parentWidget] is the widget to return to after an action Eg: deletion of a
/// permission
///
Widget buildSharedResourcesTable(BuildContext context,
    Map<dynamic, dynamic> sharedResMap, Widget parentWidget) {
  final cWidth = MediaQuery.of(context).size.width * 0.18;
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

  DataCell buildDataCell(String content) {
    return DataCell(SizedBox(
      width: cWidth,
      child: Column(
        children: <Widget>[
          SelectableText(
            content,
          )
        ],
      ),
    ));
  }

  return Row(
    children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMaxHeight: double.infinity,
            horizontalMargin: 10,
            columnSpacing: 10,
            columns: [
              buildDataColumn(
                  'Resource URL', 'WebID of the POD receiving permissions'),
              buildDataColumn('Shared on', 'Shared date and time'),
              buildDataColumn('Owner', 'Resource owner WebID'),
              buildDataColumn('Granter', 'Permission granter WebID'),
              buildDataColumn('Permissions', 'List of permissions given'),
              buildDataColumn('View', 'View file'),
            ],
            rows: sharedResMap.keys.map((index) {
              return DataRow(cells: [
                DataCell(Container(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  width: cWidth,
                  child: SelectableText(
                    index as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
                DataCell(
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          getDateTime(sharedResMap[index]
                              [PermissionLogLiteral.logtime] as String),
                        ),
                      ),
                    ],
                  ),
                ),
                buildDataCell(
                    sharedResMap[index][PermissionLogLiteral.owner] as String),
                buildDataCell(sharedResMap[index][PermissionLogLiteral.granter]
                    as String),
                buildDataCell(sharedResMap[index]
                    [PermissionLogLiteral.permissions] as String),
                DataCell(
                  IconButton(
                      icon: const Icon(
                        Icons.visibility,
                        size: 24.0,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () async {
                        // Get file content
                        final fileContent =
                            await readExternalPod(index, context, parentWidget);

                        if (fileContent != null) {
                          if (!context.mounted) return;
                          await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    title: const Text('File content'),
                                    content: Stack(
                                      alignment: Alignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: double.infinity,
                                          height: 300,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Text(fileContent as String),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            // Close the dialog
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Ok'))
                                    ],
                                  ));
                        } else {
                          if (!context.mounted) return;
                          await alert(
                              context, 'The file $index could not be found!');
                        }
                      }),
                )
              ]);
            }).toList(),
          ),
        ),
      ),
    ],
  );
}
