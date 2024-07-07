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
      this.fileName,
      super.key});

  /// The child widget to return to when back button is pressed.
  final Widget child;

  /// The text appearing in the app bar.
  final String title;

  /// The text appearing in the app bar.
  final Color backgroundColor;

  /// The name of the file permission is being set to. This is a non required
  /// parameter. If not set there will be a text field to define the file name
  final String? fileName;

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

  /// Public permission check flag
  bool publicChecked = false;

  /// WebId textfield enable/disable flag
  bool webIdTextFieldEnabled = true;

  /// Form controller
  final formKey = GlobalKey<FormState>();

  /// WebId text controller
  final formControllerWebId = TextEditingController();

  /// Filename text controller
  final formControllerFileName = TextEditingController();

  /// Group name text controller
  final formControllerGroupName = TextEditingController();

  /// Group of webIds text controller
  final formControllerGroupWebIds = TextEditingController();

  /// Permission data map of a file
  Map<dynamic, dynamic> permDataMap = {};

  /// File name of the current permission data map
  String permDataFile = '';

  /// Selected recipient
  String selectedRecipient = '';

  /// Selected recipient details
  String selectedRecipientDetails = '';

  /// List of webIds for group permission
  List<dynamic>? finalWebIdList;

  /// Public button pressed flag
  bool publicBtnFocusFlag = false;

  /// Individual button pressed flag
  bool individualBtnFocusFlag = false;

  /// Group button pressed flag
  bool groupBtnFocusFlag = false;

  /// Small vertical spacing for the widget.
  final smallGapV = const SizedBox(height: 10.0);

  /// Large vertical spacing for the widget.
  final largeGapV = const SizedBox(height: 40.0);

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

  /// A dialog for adding an individual webId
  void indWebIdDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 50),
          title: const Text('WebID of the recipient'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Web ID text field
            TextFormField(
              controller: formControllerWebId,
              decoration: const InputDecoration(
                  hintText:
                      'Eg: https://pods.solidcommunity.au/john-doe/profile/card#me'),
            ),
          ]),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final receiverWebId = formControllerWebId.text.trim();

                // Check the web ID field is not empty and it is a true link
                if (receiverWebId.isNotEmpty &&
                    Uri.parse(receiverWebId.replaceAll('#me', '')).isAbsolute &&
                    await checkResourceStatus(receiverWebId) ==
                        ResourceStatus.exist) {
                  setState(() {
                    selectedRecipient = 'individual';
                    selectedRecipientDetails = receiverWebId;
                    finalWebIdList = [receiverWebId];
                  });
                  Navigator.of(context).pop();
                } else {
                  await _alert('Please enter a valid WebID');
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

  /// A dialog for adding a group of Web IDs
  void groupWebIdDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 50),
          title: const Text('Group of WebIDs'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Group name. Should be a single string
            TextFormField(
              controller: formControllerGroupName,
              decoration: const InputDecoration(
                  labelText: 'Group name',
                  hintText:
                      'Multiple words will be combined using the symbol -'),
            ),
            smallGapV,
            // List of Web IDs divided by semicolon
            TextFormField(
              controller: formControllerGroupWebIds,
              decoration: const InputDecoration(
                  labelText: 'List of WebIDs',
                  hintText: 'Divide multiple WebIDs using the semicolon (;)'),
            ),
          ]),
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
                    if (!(await checkResourceStatus(webId) ==
                            ResourceStatus.exist) ||
                        !Uri.parse(webId.replaceAll('#me', '')).isAbsolute) {
                      trueWebIdsFlag = false;
                    }
                  }

                  if (trueWebIdsFlag) {
                    setState(() {
                      selectedRecipient = 'group';
                      selectedRecipientDetails =
                          '$groupName with WebIDs $groupWebIds';
                      finalWebIdList = webIdList;
                    });
                    Navigator.of(context).pop();
                  } else {
                    await _alert(
                        'At least one of the Web IDs you entered is not valid');
                  }
                } else {
                  await _alert(
                      'Please enter a group name and a list of Web IDs');
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
                                        fileName: widget.fileName,
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
  Widget _buildPermPage(BuildContext context, [List<Object>? futureObjList]) {
    // Build the widget.

    // Check if future is set or not. If set display the permission map
    if (futureObjList != null) {
      permDataMap = futureObjList.first as Map;
      permDataFile = widget.fileName!;
    }

    // A small horizontal spacing for the widget.

    const smallGapH = SizedBox(width: 10.0);

    final welcomeHeading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.fileName != null
              ? 'Share ${widget.fileName} file with other PODs'
              : 'Share your data files with other PODs',
          style: const TextStyle(
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
                        if (widget.fileName == null) ...[
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
                        ],
                        largeGapV,
                        subHeading('Select the permission recipient'),
                        // CheckboxListTile(
                        //   title: const Text('Public'),
                        //   value: publicChecked,
                        //   onChanged: (newValue) {
                        //     setState(() {
                        //       publicChecked = newValue!;
                        //       webIdTextFieldEnabled = !newValue;
                        //       formControllerWebId.text = '';
                        //     });
                        //   },
                        //   controlAffinity: ListTileControlAffinity
                        //       .leading, //  <-- leading Checkbox
                        // ),
                        Container(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Text(
                                'Recipient/s: ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  selectedRecipientDetails.isNotEmpty
                                      ? '$selectedRecipient ($selectedRecipientDetails)'
                                      : selectedRecipient,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepOrangeAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.0),
                          height: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  child: ElevatedButton(
                                    autofocus: publicBtnFocusFlag,
                                    onPressed: () {
                                      setState(() {
                                        selectedRecipient = 'public';
                                        selectedRecipientDetails = '';
                                        // if (publicBtnFocusFlag) {
                                        //   selectedRecipient = '';
                                        //   publicBtnFocusFlag = false;
                                        // } else {
                                        //   selectedRecipient = 'public';
                                        //   publicBtnFocusFlag = true;
                                        // }
                                        //publicBtnFocusFlag =
                                        //   !publicBtnFocusFlag;
                                      });
                                    },
                                    child: const Text('Public'),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  height: 50,
                                  child: ElevatedButton(
                                    autofocus: individualBtnFocusFlag,
                                    onPressed: indWebIdDialog,
                                    child: const Text('Individual'),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.only(left: 8.0),
                                  height: 50,
                                  child: ElevatedButton(
                                    autofocus: groupBtnFocusFlag,
                                    onPressed: groupWebIdDialog,
                                    child: const Text('Group'),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),

                        // Padding(
                        //   padding: const EdgeInsets.all(8),
                        //   child: TextFormField(
                        //     enabled: webIdTextFieldEnabled,
                        //     controller: formControllerWebId,
                        //     decoration: const InputDecoration(
                        //         labelText: 'Individual',
                        //         hintText:
                        //             'Recipient\'s WebID (Eg: https://pods.solidcommunity.au/john-doe/profile/card#me)'),
                        //     validator: (value) {
                        //       if (value == null || value.isEmpty) {
                        //         return 'Empty field';
                        //       }
                        //       return null;
                        //     },
                        //   ),
                        // ),
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
                        smallGapV,
                        subHeading('Select the list of permissions'),
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
                                if (selectedRecipient.isNotEmpty) {
                                  if (readChecked ||
                                      writeChecked ||
                                      controlChecked ||
                                      appendChecked) {
                                    final dataFile = widget.fileName ??
                                        formControllerFileName.text;

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
                                        selectedRecipient,
                                        finalWebIdList as List,
                                        true,
                                        context,
                                        GrantPermissionUi(
                                          title: widget.title,
                                          backgroundColor:
                                              widget.backgroundColor,
                                          fileName: widget.fileName,
                                          child: widget.child,
                                        ));

                                    await Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GrantPermissionUi(
                                          title: widget.title,
                                          backgroundColor:
                                              widget.backgroundColor,
                                          fileName: widget.fileName,
                                          child: widget.child,
                                        ),
                                      ),
                                    );
                                  } else {
                                    await _alert(
                                        'Please select one or more permissions');
                                  }
                                } else {
                                  await _alert('Please select a recipient');
                                }
                              }
                            },
                          ),
                        ),
                        largeGapV,
                        subHeading('Granted permissions'),
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

  /// Sub heading build function
  Row subHeading(String headingStr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            headingStr,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build as a separate widget with the possibility of adding a FutureBuilder
    // in the Future
    if (widget.fileName != null) {
      return FutureBuilder(
        future: Future.wait(
            [readPermission(widget.fileName as String, true, context, widget)]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildPermPage(context, snapshot.data);
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    } else {
      return _buildPermPage(context);
    }
  }
}
