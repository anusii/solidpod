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
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/read_external_pod.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/widgets/file_explorer.dart';

/// Build the permission table widget. Function call requires the
/// following inputs
/// [context] is the BuildContext from which this function is called.
/// [sharedResMap] is the map containing data of shared resources.
/// [parentWidget] is the widget to return to after an action Eg: deletion of a
/// permission
///
Widget buildSharedResourcesTable(
  BuildContext context,
  Map<dynamic, dynamic> sharedResMap,
  Widget parentWidget,
) {
  final cWidth = MediaQuery.of(context).size.width * 0.18;
  DataColumn buildDataColumn(String title, String tooltip) {
    return DataColumn(
      label: Expanded(child: Center(child: Text(title))),
      tooltip: tooltip,
    );
  }

  DataCell buildDataCell(String content) {
    return DataCell(
      SizedBox(
        width: cWidth,
        child: Column(children: <Widget>[SelectableText(content)]),
      ),
    );
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
                'Resource URL',
                'WebID of the POD receiving permissions',
              ),
              buildDataColumn('Shared on', 'Shared date and time'),
              buildDataColumn('Owner', 'Resource owner WebID'),
              buildDataColumn('Granter', 'Permission granter WebID'),
              buildDataColumn('Permissions', 'List of permissions given'),
              buildDataColumn('View/Open', 'View file'),
            ],
            rows: sharedResMap.keys.map((index) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                      width: cWidth,
                      child: SelectableText(
                        index as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            getDateTime(
                              sharedResMap[index][PermissionLogLiteral.logtime]
                                  as String,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildDataCell(
                    sharedResMap[index][PermissionLogLiteral.owner] as String,
                  ),
                  buildDataCell(
                    sharedResMap[index][PermissionLogLiteral.granter] as String,
                  ),
                  buildDataCell(
                    sharedResMap[index][PermissionLogLiteral.permissions]
                        as String,
                  ),
                  DataCell(
                    isDir(index)
                        ? IconButton(
                            icon: const Icon(
                              Icons.folder_open_outlined,
                              size: 24.0,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () async {
                              if (!sharedResMap[index]
                                      [PermissionLogLiteral.permissions]
                                  .contains('read')) {
                                await alert(
                                  context,
                                  'You do not have read permission to this resource!',
                                );
                              } else {
                                bool isEditable = [
                                  AccessMode.write.mode,
                                  AccessMode.control.mode,
                                ].any(
                                  (mode) => sharedResMap[index]
                                          [PermissionLogLiteral.permissions]
                                      .contains(mode.toLowerCase()),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FileExplorerScreen(
                                      folderPath: index,
                                      isEditable: isEditable,
                                      ownerWebId: sharedResMap[index]
                                              [PermissionLogLiteral.owner]
                                          as String,
                                      child: parentWidget,
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              size: 24.0,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () async {
                              try {
                                // Get file content
                                final fileContent = await readExternalPod(
                                  index,
                                );

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
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Text(fileContent),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          // Close the dialog
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Ok'),
                                      ),
                                    ],
                                  ),
                                );
                              } on Object catch (e, trace) {
                                debugPrint(e.toString());
                                debugPrint(trace.toString());
                                if (!context.mounted) return;
                                await alert(
                                  context,
                                  'The file $index could not be found!',
                                );
                              }
                            },
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}
