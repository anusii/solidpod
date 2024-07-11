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

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/heading.dart';
import 'package:solidpod/src/widgets/file_permission_data_table.dart';
import 'package:solidpod/src/widgets/group_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/ind_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/permission_checkbox.dart';

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
  RecipientType selectedRecipient = RecipientType.none;

  /// Selected recipient details
  String selectedRecipientDetails = '';

  /// List of webIds for group permission
  List<dynamic>? finalWebIdList;

  /// Selected list of permissions
  List<String> selectedPermList = [];

  /// Small vertical spacing for the widget.
  final smallGapV = const SizedBox(height: 10.0);

  /// Large vertical spacing for the widget.
  final largeGapV = const SizedBox(height: 40.0);

  @override
  void initState() {
    super.initState();
  }

  // Update permission map with new data
  void _updatePermMap(Map<dynamic, dynamic> newPermMap, String fileName) {
    setState(() {
      permDataMap = newPermMap;
      permDataFile = fileName;
    });
  }

  // Update checkbox ticking data
  void _updateCheckbox(bool newValue, AccessMode accessMode) {
    setState(() {
      if (accessMode == AccessMode.read) {
        readChecked = newValue;
      }
      if (accessMode == AccessMode.write) {
        writeChecked = newValue;
      }
      if (accessMode == AccessMode.control) {
        controlChecked = newValue;
      }
      if (accessMode == AccessMode.append) {
        appendChecked = newValue;
      }
      if (newValue) {
        selectedPermList.add(accessMode.mode);
      } else {
        selectedPermList.remove(accessMode.mode);
      }
    });
  }

  // Update individual webid input data
  void _updateIndWebIdInput(String receiverWebId) {
    setState(() {
      selectedRecipient = RecipientType.individual;
      selectedRecipientDetails = receiverWebId;
      finalWebIdList = [receiverWebId];
    });
  }

  // Update group of webids input data
  void _updateGroupWebIdInput(String groupName, List<dynamic> webIdList) {
    setState(() {
      selectedRecipient = RecipientType.group;
      selectedRecipientDetails =
          '$groupName with WebIDs ${webIdList.join(', ')}';
      finalWebIdList = webIdList;
    });
  }

  Future<void> _alert(String msg) async => alert(context, msg);

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

    final welcomeHeadingStr = widget.fileName != null
        ? 'Share ${widget.fileName} file with other PODs'
        : 'Share your data files with other PODs';

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
                    buildHeading(welcomeHeadingStr, 22),
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
                        buildHeading('Select the permission recipient', 17.0,
                            Colors.blueGrey, 8),
                        Container(
                          padding: const EdgeInsets.all(8.0),
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
                                      ? '${selectedRecipient.type} ($selectedRecipientDetails)'
                                      : selectedRecipient.type,
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
                          padding: const EdgeInsets.all(8.0),
                          height: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedRecipient =
                                            RecipientType.public;
                                        selectedRecipientDetails = '';
                                        finalWebIdList = [publicAgent.value];
                                      });
                                    },
                                    child: Text(RecipientType.public.type),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedRecipient =
                                            RecipientType.authUser;
                                        selectedRecipientDetails = '';
                                        finalWebIdList = [
                                          authenticatedAgent.value
                                        ];
                                      });
                                    },
                                    child: Text(RecipientType.authUser.type),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await indWebIdInputDialog(
                                          context,
                                          formControllerWebId,
                                          _updateIndWebIdInput);
                                    },
                                    child: Text(RecipientType.individual.type),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await groupWebIdInputDialog(
                                          context,
                                          formControllerGroupName,
                                          formControllerGroupWebIds,
                                          _updateGroupWebIdInput);
                                    },
                                    child: Text(RecipientType.group.type),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        smallGapV,
                        buildHeading('Select the list of permissions', 17.0,
                            Colors.blueGrey, 8),
                        permissionCheckbox(
                            AccessMode.read, readChecked, _updateCheckbox),
                        permissionCheckbox(
                            AccessMode.write, writeChecked, _updateCheckbox),
                        permissionCheckbox(AccessMode.control, controlChecked,
                            _updateCheckbox),
                        permissionCheckbox(
                            AccessMode.append, appendChecked, _updateCheckbox),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ElevatedButton(
                            child: const Text('Grant Permission'),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (selectedRecipient.type.isNotEmpty) {
                                  if (selectedPermList.isNotEmpty) {
                                    final dataFile = widget.fileName ??
                                        formControllerFileName.text;

                                    await grantPermission(
                                      dataFile,
                                      true,
                                      selectedPermList,
                                      selectedRecipient,
                                      finalWebIdList as List,
                                      true,
                                      context,
                                      GrantPermissionUi(
                                        title: widget.title,
                                        backgroundColor: widget.backgroundColor,
                                        fileName: widget.fileName,
                                        child: widget.child,
                                      ),
                                      //groupName,
                                      selectedRecipient ==
                                              RecipientType.group.type
                                          ? formControllerGroupName.text.trim()
                                          : null,
                                    );

                                    if (!context.mounted) return;
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
                        buildHeading(
                            'Granted permissions', 17.0, Colors.blueGrey, 8),
                        buildPermDataTable(
                            context,
                            permDataFile,
                            permDataMap,
                            GrantPermissionUi(
                              title: widget.title,
                              backgroundColor: widget.backgroundColor,
                              fileName: widget.fileName,
                              child: widget.child,
                            )),
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
