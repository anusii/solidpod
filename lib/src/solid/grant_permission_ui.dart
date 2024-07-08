/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Sunday 2024-06-24 11:26:00 +1000 Anushka Vidange>
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
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/revoke_permission.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// A widget for the demonstration screen of the application.

class GrantPermissionUi extends StatefulWidget {
  /// Initialise widget variables.

  const GrantPermissionUi(
      {required this.child,
      this.title = 'Demonstrating data sharing functionality',
      this.backgroundColor = const Color.fromARGB(255, 210, 210, 210),
      super.key});

  /// The child widget to return to when back button is pressed.
  final Widget child;

  /// The text appearing in the app bar.
  final String title;

  /// The text appearing in the app bar.
  final Color backgroundColor;

  @override
  GrantPermissionUiState createState() => GrantPermissionUiState();
}

/// Class to build a UI for granting permission to a given file
class GrantPermissionUiState extends State<GrantPermissionUi>
    with SingleTickerProviderStateMixin {
  /// read permission checked flag
  bool readChecked = false;

  /// write permission checked flag
  bool writeChecked = false;

  /// control permission checked flag
  bool controlChecked = false;

  /// append permission checked flag
  bool appendChecked = false;

  /// Form controller
  final formKey = GlobalKey<FormState>();

  /// WebId text controller
  final formControllerWebId = TextEditingController();

  /// Filename text controller
  final formControllerFileName = TextEditingController();

  /// Permission data map of a file
  Map<dynamic, dynamic> permDataMap = {};

  /// File name of the current permission data map
  String permDataFile = '';

  @override
  void initState() {
    super.initState();
  }

  // ignore: strict_raw_type
  void _updatePermMap(Map newPermMap, String fileName) {
    setState(() {
      permDataMap = newPermMap;
      permDataFile = fileName;
    });
  }

  Future<void> _alert(String msg) async => alert(context, msg);

  /// Build the permission table widget
  Widget _buildPermDataTable() {
    return DataTable(
      columns: const [
        DataColumn(
            label: Expanded(
              child: Center(
                child: Text(
                  'Receiver',
                ),
              ),
            ),
            tooltip: 'WebID of the POD receiving permissions'),
        DataColumn(
            label: Expanded(
              child: Center(
                child: Text(
                  'Receiver type',
                ),
              ),
            ),
            tooltip: 'Type of the receiver'),
        DataColumn(
            label: Expanded(
              child: Center(
                child: Text(
                  'Permissions',
                ),
              ),
            ),
            tooltip: 'List of permissions given'),
        DataColumn(
            label: Expanded(
              child: Center(
                child: Text(
                  'Actions',
                ),
              ),
            ),
            tooltip: 'Delete permission'),
      ],
      rows: permDataMap.keys.map((index) {
        return DataRow(cells: [
          DataCell(Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            //width: cWidth,
            child: Column(
              children: <Widget>[
                SelectableText(
                  index as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
          )),
          DataCell(
            Text(
              getAgentType(permDataMap[index][agentStr] as String, index),
            ),
          ),
          DataCell(
            Text(
              (permDataMap[index][permStr] as List).join(', '),
            ),
          ),
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
                              'Are you sure you want to remove the [${(permDataMap[index][permStr] as List).join(', ')}] permission/s from $index?'),
                          actions: [
                            // The "Yes" button
                            TextButton(
                                onPressed: () async {
                                  await revokePermission(
                                      permDataFile,
                                      true,
                                      permDataMap[index][permStr] as List,
                                      index,
                                      context,
                                      GrantPermissionUi(
                                        title: widget.title,
                                        backgroundColor: widget.backgroundColor,
                                        child: widget.child,
                                      ));

                                  await Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GrantPermissionUi(
                                        title: widget.title,
                                        backgroundColor: widget.backgroundColor,
                                        child: widget.child,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Yes')),
                            TextButton(
                                onPressed: () {
                                  // Close the dialog
                                  Navigator.of(context).pop();
                                },
                                child: const Text('No'))
                          ],
                        );
                      });
                }),
          )
        ]);
      }).toList(),
    );
  }

  /// Build the main widget
  Widget _build(BuildContext context) {
    // Build the widget.

    // Some vertical spacing for the widget.

    const smallGapV = SizedBox(height: 10.0);
    const largeGapV = SizedBox(height: 40.0);

    // A small horizontal spacing for the widget.

    const smallGapH = SizedBox(width: 10.0);

    const welcomeHeading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share your data files with other PODs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget.child),
          ),
        ),
        backgroundColor: widget.backgroundColor,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            smallGapV,
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
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextFormField(
                            controller: formControllerFileName,
                            decoration: const InputDecoration(
                                hintText:
                                    'Data file path (inside your data folder Eg: personal/about.ttl)'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Empty field';
                              }
                              return null;
                            },
                          ),
                        ),
                        smallGapH,
                        ElevatedButton(
                          child: const Text('Retreive permissions'),
                          onPressed: () async {
                            final fileName = formControllerFileName.text;

                            if (fileName.isEmpty) {
                              await _alert('Please enter a file name');
                            } else {
                              final permissionMap = await readPermission(
                                  fileName,
                                  true,
                                  context,
                                  GrantPermissionUi(child: widget.child));

                              if (permissionMap.isEmpty) {
                                await _alert(
                                    'We could not find a resource by the name $fileName');
                              } else {
                                _updatePermMap(permissionMap, fileName);
                              }
                            }
                          },
                        ),
                        smallGapH,
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextFormField(
                            controller: formControllerWebId,
                            decoration: const InputDecoration(
                                hintText:
                                    'Recipient\'s WebID (Eg: https://pods.solidcommunity.au/john-doe/profile/card#me)'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Empty field';
                              }
                              return null;
                            },
                          ),
                        ),
                        // av-2024062: do we need the following functionality in this page.
                        // commeting out for now until further discussion
                        // smallGapH,
                        // ElevatedButton(
                        //   child: const Text('Check Permission'),
                        //   onPressed: () {
                        //     final webId = formControllerWebId.text;

                        //     Map permControllerMap = {
                        //       'Read': readChecked,
                        //       'Write': writeChecked,
                        //       'Control': controlChecked,
                        //     };

                        // if (webId.isNotEmpty) {
                        //   if (filePermMap.containsKey(webId)) {
                        //     final permList = filePermMap[webId] as List;

                        //     if (permList.contains('Read') ||
                        //         permList.contains('read')) {
                        //       setState(() {
                        //         readChecked = true;
                        //       });
                        //     } else {
                        //       setState(() {
                        //         readChecked = false;
                        //       });
                        //     }
                        //     if (permList.contains('Write') ||
                        //         permList.contains('write')) {
                        //       setState(() {
                        //         writeChecked = true;
                        //       });
                        //     } else {
                        //       setState(() {
                        //         writeChecked = false;
                        //       });
                        //     }
                        //     if (permList.contains('Control') ||
                        //         permList.contains('control')) {
                        //       setState(() {
                        //         controlChecked = true;
                        //       });
                        //     } else {
                        //       setState(() {
                        //         controlChecked = false;
                        //       });
                        //     }
                        //   } else {
                        //     showDialog(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         title: const Text('INFO!'),
                        //         content: const Text(
                        //             'You have not provided any permissions for this webId.'),
                        //         actions: [
                        //           ElevatedButton(
                        //               onPressed: () {
                        //                 Navigator.pop(context);
                        //               },
                        //               child: const Text('OK'))
                        //         ],
                        //       ),
                        //     );
                        //   }
                        // } else {
                        //   showDialog(
                        //     context: context,
                        //     builder: (context) => AlertDialog(
                        //       title: const Text('ERROR!'),
                        //       content: const Text('Please enter a webID.'),
                        //       actions: [
                        //         ElevatedButton(
                        //             onPressed: () {
                        //               Navigator.pop(context);
                        //             },
                        //             child: const Text('OK'))
                        //       ],
                        //     ),
                        //   );
                        // }
                        //   },
                        // ),
                        smallGapH,
                        CheckboxListTile(
                          title: Text(
                              '${AccessMode.read.mode} (${AccessMode.read.description})'),
                          value: readChecked,
                          onChanged: (newValue) {
                            setState(() {
                              readChecked = newValue!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text(
                              '${AccessMode.write.mode} (${AccessMode.write.description})'),
                          value: writeChecked,
                          onChanged: (newValue) {
                            setState(() {
                              writeChecked = newValue!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text(
                              '${AccessMode.control.mode} (${AccessMode.control.description})'),
                          value: controlChecked,
                          onChanged: (newValue) {
                            setState(() {
                              controlChecked = newValue!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text(
                              '${AccessMode.append.mode} (${AccessMode.append.description})'),
                          value: appendChecked,
                          onChanged: (newValue) {
                            setState(() {
                              appendChecked = newValue!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ElevatedButton(
                            child: const Text('Grant Permission'),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (readChecked ||
                                    writeChecked ||
                                    controlChecked ||
                                    appendChecked) {
                                  final webId = formControllerWebId.text;
                                  final dataFile = formControllerFileName.text;

                                  // Check if webId is a true link
                                  if (Uri.parse(webId.replaceAll('#me', ''))
                                          .isAbsolute &&
                                      await checkResourceStatus(webId) ==
                                          ResourceStatus.exist) {
                                    final permList = [];
                                    if (readChecked) {
                                      permList.add('Read');
                                    }
                                    if (writeChecked) {
                                      permList.add('Write');
                                    }
                                    if (controlChecked) {
                                      permList.add('Control');
                                    }
                                    if (appendChecked) {
                                      permList.add('Append');
                                    }
                                    assert(permList.isNotEmpty);

                                    await grantPermission(
                                        dataFile,
                                        true,
                                        permList,
                                        webId,
                                        true,
                                        context,
                                        GrantPermissionUi(
                                          title: widget.title,
                                          backgroundColor:
                                              widget.backgroundColor,
                                          child: widget.child,
                                        ));

                                    await Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GrantPermissionUi(
                                          title: widget.title,
                                          backgroundColor:
                                              widget.backgroundColor,
                                          child: widget.child,
                                        ),
                                      ),
                                    );
                                  } else {
                                    await _alert(
                                        'The WebID you entered does not exist!');
                                  }
                                } else {
                                  await _alert(
                                      'Please select one or more permissions');
                                }
                              }
                            },
                          ),
                        ),
                        largeGapV,
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Granted permissions',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        _buildPermDataTable(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build as a separate widget with the possibility of adding a FutureBuilder
    // in the Future
    return _build(context);
  }
}
