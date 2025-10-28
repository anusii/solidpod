/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Wednesday 2025-10-08 15:39:39 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/chk_exists_and_has_acl.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/heading.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';
import 'package:solidpod/src/widgets/app_bar.dart';
import 'package:solidpod/src/widgets/file_permission_data_table.dart';
import 'package:solidpod/src/widgets/group_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/ind_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';
import 'package:solidpod/src/widgets/permission_checkbox.dart';

/// A widget for the granting access permission to data.

class GrantPermissionUi extends StatefulWidget {
  /// Initialise widget variables.

  const GrantPermissionUi({
    required this.child,
    this.title = 'Demonstrating data sharing functionality',
    this.backgroundColor = const Color.fromARGB(255, 210, 210, 210),
    this.showAppBar = true,
    this.isExternalRes = false,
    this.accessModeList = const ['read', 'write', 'append', 'control'],
    this.recipientTypeList = const ['public', 'indi', 'auth', 'group'],
    this.externalWebId,
    this.resourceName,
    this.isFile,
    this.dataFilesMap = const {},
    this.customAppBar,
    this.onPermissionGranted,
    this.onNavigateBack,
    super.key,
  });

  /// The child widget to return to when back button is pressed and/or when
  /// page is reloaded after a permission is granted or revoked.
  final Widget child;

  /// The text appearing in the app bar.
  final String title;

  /// The text appearing in the app bar.
  final Color backgroundColor;

  /// The boolean to decide whether to display an app bar or not.
  final bool showAppBar;

  /// The boolean to decide whether the resources is from an external POD or not
  final bool isExternalRes;

  /// The list of access modes to be displayed. By default all four types of
  /// access mode are listed.
  final List<String> accessModeList;

  /// The list of types of recipients receiving permission to access the resource. By default all four
  /// types of recipient are listed.
  final List<String> recipientTypeList;

  /// String to assign the external webId of the resource owner. Must be set
  /// if [isExternalRes] is set to true.
  final String? externalWebId;

  /// The name of the file or directory permission is being set to. This is a
  /// non required parameter. If not set there will be a text field to define
  /// the file name. If [resourceName] is set to true this must be set and the
  /// value should be the url of the resource.
  final String? resourceName;

  /// A flag to determine whether the given resource is a file or not. This is
  /// a non required parameter. If not set there will be a toggle to define this.
  /// If [isExternalRes] is set to true this must be set and the value should
  /// be the url of the resource
  final bool? isFile;

  /// Map of data files on a user's POD used to extract the
  /// user's recipient list by the WebIdTextInputScreen.
  /// If not provided, the WebIdTextInputScreen will read the
  /// user's files in their app data folder on their Pod to
  /// fetch the ACLs needed to derive the user's recipient list.
  final Map<String, dynamic> dataFilesMap;

  /// App specific app bar
  final PreferredSizeWidget? customAppBar;

  /// Callback function called when permissions are granted successfully.

  final VoidCallback? onPermissionGranted;

  /// Callback function called when navigating back from the screen.

  final VoidCallback? onNavigateBack;

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

  /// Flag to check whether page is initialised.

  bool pageInitialied = false;

  /// Define access mode list
  List<AccessMode> acessModeList = [];

  /// Define recipient type list
  List<RecipientType> recipientTypeList = [];

  /// Form controller
  final formKey = GlobalKey<FormState>();

  /// Filename text controller
  final formControllerFileName = TextEditingController();

  /// Group name text controller
  final formControllerGroupName = TextEditingController();

  /// Group of webIds text controller
  final formControllerGroupWebIds = TextEditingController();

  /// Permission data map of a file
  Map<dynamic, dynamic> permDataMap = {};

  /// Owner WebId
  String ownerWebId = '';

  /// File name of the current permission data map
  String permDataFile = '';

  /// Selected recipient
  RecipientType selectedRecipientType = RecipientType.none;

  /// Selected recipient details
  String selectedRecipientDetails = '';

  /// List of webIds for group permission
  List<dynamic>? finalWebIdList;

  /// Selected list of permissions
  List<String> selectedPermList = [];

  /// Flag to track if permissions were granted successfully.

  bool permissionsGrantedSuccessfully = false;

  /// Small vertical spacing for the widget.
  final smallGapV = const SizedBox(height: 10.0);

  /// Large vertical spacing for the widget.
  final largeGapV = const SizedBox(height: 40.0);

  /// Pod data list retreived as a Future
  late Future<List<dynamic>> podDataList;

  /// A flag to identify if the resource is a file or not
  bool isFile = true;

  /// Runs multiple asynchronous functions to get the data from
  /// POD server if necessary.
  Future<List<dynamic>> loadPodData() async {
    final SolidFunctionCallStatus response;
    if (context.mounted) {
      response = await chkExistsAndHasAcl(
        fileName: widget.resourceName as String,
        isFile: isFile,
        context: context,
        child: widget,
      );
    } else {
      response = SolidFunctionCallStatus.contextNotMounted;
    }

    if (response == SolidFunctionCallStatus.aclFound) {
      final Map<dynamic, dynamic> result = await readPermission(
        fileName: widget.resourceName as String,
        isFile: isFile,
        isExternalRes: widget.isExternalRes,
      );

      final webId = widget.isExternalRes
          ? widget.externalWebId
          : await AuthDataManager.getWebId();
      return [result, webId];
    } else if (response == SolidFunctionCallStatus.notLoggedIn) {
      await _alert(
        'Please login first to retrieve permission',
      );
      return [];
    } else if (response == SolidFunctionCallStatus.noAclFound) {
      await _alert(
        'Resource does not have a corresponding ACL file.\n'
        'If the ACL is inherited, provide parent directory as the resource name!',
      );
      return [];
    } else {
      await _alert('Unknown error');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Load future
    if (widget.resourceName != null) {
      podDataList = loadPodData();
    }

    // Load access mode list to be displayed
    for (final accessModeStr in widget.accessModeList) {
      acessModeList.add(getAccessMode(accessModeStr));
    }

    // Load recipient list to be displayed
    for (final recTypeStr in widget.recipientTypeList) {
      recipientTypeList.add(getRecType(recTypeStr));
    }
  }

  // Get new permission and update the permission map
  Future<void> _updatePermissions(String fileName, {bool isFile = true}) async {
    final SolidFunctionCallStatus response = await chkExistsAndHasAcl(
      fileName: fileName,
      isFile: isFile,
      context: context,
      child: widget,
    );
    if (response == SolidFunctionCallStatus.aclFound) {
      final Map<dynamic, dynamic> permissionMap = await readPermission(
        fileName: widget.resourceName as String,
        isFile: isFile,
        isExternalRes: widget.isExternalRes,
      );

      final webId = widget.isExternalRes
          ? widget.externalWebId
          : await AuthDataManager.getWebId();

      if (permissionMap.isEmpty) {
        await _alert(
          'We could not find a resource by the name $fileName',
        );
      } else {
        _updatePermTable(
          permissionMap,
          webId as String,
          fileName,
        );
      }
    } else if (response == SolidFunctionCallStatus.notLoggedIn) {
      await _alert(
        'Please login first to retrieve permission',
      );
    } else if (response == SolidFunctionCallStatus.noAclFound) {
      await _alert(
        'Resource does not have a corresponding ACL file.\n'
        'If the ACL is inherited, provide parent directory as the resource name!',
      );
    }
  }

  // Update permission table with new data
  void _updatePermTable(
    Map<dynamic, dynamic> newPermMap,
    String webId,
    String fileName,
  ) {
    setState(() {
      permDataMap = newPermMap;
      permDataFile = fileName;
      ownerWebId = webId;
    });
  }

  // Update checkbox tick data.

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
      selectedRecipientType = RecipientType.individual;
      selectedRecipientDetails = receiverWebId;
      finalWebIdList = [receiverWebId];
    });
  }

  // Update group of webids input data
  void _updateGroupWebIdInput(String groupName, List<dynamic> webIdList) {
    setState(() {
      selectedRecipientType = RecipientType.group;
      selectedRecipientDetails =
          '$groupName with WebIDs ${webIdList.join(', ')}';
      finalWebIdList = webIdList;
    });
  }

  Future<void> _alert(String msg) async => alert(context, msg);

  /// Build the main widget
  Widget _buildPermPage(BuildContext context, [List<Object?>? futureObjList]) {
    /// Controller for vertical page scrolling
    final pageScrollController = ScrollController();

    /// Controller for horizontal permissions table scrolling
    final tableScrollController = ScrollController();

    // Check if future is set or not. If set display the permission map
    if (futureObjList != null && pageInitialied == false) {
      permDataMap = futureObjList.first as Map;
      ownerWebId = futureObjList[1] as String;
      permDataFile = widget.resourceName!;
      pageInitialied = true;
    }

    final welcomeHeadingStr = widget.resourceName != null
        ? 'Share ${widget.resourceName} file with other PODs'
        : 'Share your data files/directories with other PODs';

    return Scaffold(
      appBar: (!widget.showAppBar)
          ? null
          : (widget.customAppBar != null)
              ? widget.customAppBar
              : defaultAppBar(
                  context,
                  widget.title,
                  widget.backgroundColor,
                  widget.child,
                  onNavigateBack: () {
                    widget.onNavigateBack?.call();
                  },
                  getResult: () => permissionsGrantedSuccessfully,
                ),
      // Make Grant Permission UI vertically scrollable
      // Shows when content exceeds display height
      body: Scrollbar(
        thumbVisibility: true, // show before user starts scrolling
        controller: pageScrollController,
        child: SingleChildScrollView(
          controller: pageScrollController,
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
                          if (widget.resourceName == null) ...[
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: formControllerFileName,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Resource path (inside your data folder Eg: personal/about.ttl)',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Empty field';
                                      }
                                      return null;
                                    },
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
                                    onChanged: (bool value) {
                                      setState(() {
                                        isFile = value;
                                      });
                                    },
                                    thumbColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                      (Set<WidgetState> states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return Colors.green;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            smallGapV,
                            ElevatedButton(
                              child: const Text('Retrieve permissions'),
                              onPressed: () async {
                                final fileName = formControllerFileName.text;

                                if (fileName.isEmpty) {
                                  await _alert('Please enter a file name');
                                } else {
                                  await _updatePermissions(
                                    fileName,
                                    isFile: isFile,
                                  );
                                }
                              },
                            ),
                          ],
                          largeGapV,
                          buildHeading(
                            'Select the recipient/s of file access permissions',
                            17.0,
                            Colors.blueGrey,
                            8,
                          ),
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
                                        ? '${selectedRecipientType.type} ($selectedRecipientDetails)'
                                        : selectedRecipientType.type,
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
                          ),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            height: 100,
                            child: Row(
                              children: [
                                // av 20250526:
                                // Public and Authenticated users buttons are
                                // disabled in this function at the moment because
                                // providing public or authenticated permissions to
                                // external resources is not yet implemented in
                                // [grantPermission()] function.
                                if (!widget.isExternalRes) ...[
                                  if (recipientTypeList
                                      .contains(RecipientType.public)) ...[
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: MarkdownTooltip(
                                          message: '''

                                        **Public:** This file will be publicly
                                        accessible so that even users without a
                                        Data Vault can access the file.

                                        ''',
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedRecipientType =
                                                    RecipientType.public;
                                                selectedRecipientDetails = '';
                                                finalWebIdList = [
                                                  publicAgent.value,
                                                ];
                                              });
                                            },
                                            child:
                                                Text(RecipientType.public.type),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (recipientTypeList
                                      .contains(RecipientType.authUser)) ...[
                                    Expanded(
                                      child: Container(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        height: 50,
                                        child: MarkdownTooltip(
                                          message: '''

                                        **Users:** The file will be available to
                                        any user who has registered a Data
                                        Vault. When they have logged into their
                                        Data Vault they will be able to access
                                        the file.

                                        ''',
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedRecipientType =
                                                    RecipientType.authUser;
                                                selectedRecipientDetails = '';
                                                finalWebIdList = [
                                                  authenticatedAgent.value,
                                                ];
                                              });
                                            },
                                            child: Text(
                                              RecipientType.authUser.type,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                                if (recipientTypeList
                                    .contains(RecipientType.individual)) ...[
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      height: 50,
                                      child: MarkdownTooltip(
                                        message: '''

                                      **Individual:** The file will be available
                                      only to the identified individual user. A
                                      WebID is required to identify the
                                      individual who is gratned access to the
                                      file.

                                      ''',
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // Open dialog for WebId entry
                                            await indWebIdInputDialog(
                                              context,
                                              _updateIndWebIdInput,
                                              widget.dataFilesMap,
                                            );
                                          },
                                          child: Text(
                                            RecipientType.individual.type,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (recipientTypeList
                                    .contains(RecipientType.group)) ...[
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      height: 50,
                                      child: MarkdownTooltip(
                                        message: '''

                                      **Group:** A collection of WebIDs can be
                                      provided so that as a group they can
                                      access the file.

                                      ''',
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await groupWebIdInputDialog(
                                              context,
                                              formControllerGroupName,
                                              formControllerGroupWebIds,
                                              _updateGroupWebIdInput,
                                            );
                                          },
                                          child: Text(RecipientType.group.type),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          smallGapV,
                          buildHeading(
                            'Select the list of file access permissions',
                            17.0,
                            Colors.blueGrey,
                            8,
                          ),
                          if (acessModeList.contains(AccessMode.read)) ...[
                            permissionCheckbox(
                              AccessMode.read,
                              readChecked,
                              _updateCheckbox,
                            ),
                          ],
                          if (acessModeList.contains(AccessMode.write)) ...[
                            permissionCheckbox(
                              AccessMode.write,
                              writeChecked,
                              _updateCheckbox,
                            ),
                          ],
                          if (acessModeList.contains(AccessMode.control)) ...[
                            permissionCheckbox(
                              AccessMode.control,
                              controlChecked,
                              _updateCheckbox,
                            ),
                          ],
                          if (acessModeList.contains(AccessMode.append)) ...[
                            permissionCheckbox(
                              AccessMode.append,
                              appendChecked,
                              _updateCheckbox,
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: ElevatedButton(
                              child: const Text('Grant Permission'),
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  if (selectedRecipientType.type.isNotEmpty) {
                                    if (selectedPermList.isNotEmpty) {
                                      final dataFile = widget.resourceName ??
                                          formControllerFileName.text;

                                      final isFileFlag =
                                          widget.isFile ?? isFile;

                                      SolidFunctionCallStatus? result;
                                      try {
                                        result = await grantPermission(
                                          dataFile,
                                          isFileFlag,
                                          selectedPermList,
                                          selectedRecipientType,
                                          finalWebIdList as List,
                                          ownerWebId,
                                          context,
                                          widget.child,
                                          isExternalRes: widget.isExternalRes,
                                          groupName: selectedRecipientType ==
                                                  RecipientType.group
                                              ? formControllerGroupName.text
                                                  .trim()
                                              : null,
                                        ) as SolidFunctionCallStatus?;
                                      } on Object catch (e, stackTrace) {
                                        debugPrint(
                                          '💥 [GrantPermissionUI] Exception in grantPermission: $e',
                                        );
                                        debugPrint(
                                          '📚 [GrantPermissionUI] Stack trace: $stackTrace',
                                        );
                                        result = SolidFunctionCallStatus.fail;
                                      }

                                      if (result ==
                                          SolidFunctionCallStatus.success) {
                                        if (!context.mounted) return;
                                        showSnackBar(
                                          context,
                                          'File access permissions granted successfully!',
                                          Colors.green,
                                        );
                                        await _updatePermissions(
                                          dataFile,
                                          isFile: isFileFlag,
                                        );

                                        // Mark permissions as granted successfully for callback tracking
                                        setState(() {
                                          permissionsGrantedSuccessfully = true;
                                        });

                                        // Trigger the onPermissionGranted callback if provided
                                        widget.onPermissionGranted?.call();
                                      } else if (result ==
                                          SolidFunctionCallStatus.fail) {
                                        if (!context.mounted) return;

                                        // More detailed error message with troubleshooting tips
                                        showSnackBar(
                                          context,
                                          'Permission granting failed. Check console logs for details. Common issues: resource not found, invalid WebID format, or network connectivity.',
                                          Colors.red,
                                        );

                                        // Also log to console for debugging
                                        debugPrint(
                                          '❌ [GrantPermissionUI] Permission granting failed for file: $dataFile',
                                        );
                                        debugPrint(
                                          '🎯 [GrantPermissionUI] Recipients: $finalWebIdList',
                                        );
                                        debugPrint(
                                          '🔐 [GrantPermissionUI] Permissions: $selectedPermList',
                                        );
                                      } else if (result ==
                                          SolidFunctionCallStatus
                                              .notInitialised) {
                                        if (!context.mounted) return;
                                        showSnackBar(
                                          context,
                                          'The owner of one or more WebIds you entered have not initialised their PODs yet! They need to login and setup their POD first.',
                                          const Color.fromARGB(255, 204, 99, 1),
                                        );
                                      } else {
                                        await _alert(
                                          'Please login first to update file access permission',
                                        );
                                      }
                                    } else {
                                      await _alert(
                                        'Please select one or more file access permissions',
                                      );
                                    }
                                  } else {
                                    await _alert(
                                      'Please select a type of recipient',
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          largeGapV,
                          buildHeading(
                            'Granted file access permissions',
                            17.0,
                            Colors.blueGrey,
                            8,
                          ),
                          Scrollbar(
                            // 20250722 jm:
                            // For scrollbar visibility before scrolling,
                            // set to true, or set property to true
                            // in parent app MaterialApp(theme: ThemeData(scrollbarTheme: scrollbarTheme: ScrollbarThemeData(
                            // thumbVisibility: WidgetStateProperty.all(true)))
                            thumbVisibility:
                                true, // show before user starts scrolling
                            controller: tableScrollController,
                            child: SingleChildScrollView(
                              controller: tableScrollController,
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      buildPermDataTable(
                                        context: context,
                                        permDataResource: permDataFile,
                                        isFile: widget.isFile ?? isFile,
                                        permDataMap: permDataMap,
                                        ownerWebId: ownerWebId,
                                        parentWidget: widget.child,
                                        onDeleteFuncion: _updatePermissions,
                                        isExternalRes: widget.isExternalRes,
                                      ),
                                      // Hspace to avoid vertical scrollbar overlap with table
                                      ScrollbarLayout.horizontalGap,
                                    ],
                                  ),
                                  // Vspace to avoid horizontal scrollbar overlap of table
                                  ScrollbarLayout.verticalGap,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build as a separate widget with the possibility of adding a FutureBuilder
    // in the Future

    if (widget.resourceName != null) {
      return FutureBuilder(
        future: podDataList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.first == SolidFunctionCallStatus.notLoggedIn) {
              return widget.child;
            } else {
              return _buildPermPage(context, snapshot.data);
            }
          } else {
            return Scaffold(body: loadingScreen(normalLoadingScreenHeight));
          }
        },
      );
    } else {
      return _buildPermPage(context);
    }
  }
}

/// Return recipient type based on a given String value
RecipientType getRecType(String recTypeStr) {
  switch (recTypeStr.toLowerCase()) {
    case 'public':
      return RecipientType.public;
    case 'indi':
      return RecipientType.individual;
    case 'auth':
      return RecipientType.authUser;
    case 'group':
      return RecipientType.group;
    default:
      throw Exception('Wrong recipient type given'
          '\nRecipient: $recTypeStr');
  }
}
