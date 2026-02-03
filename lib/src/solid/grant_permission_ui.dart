/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Thursday 2026-01-15 13:42:22 +1100 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang, Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/chk_exists_and_has_acl.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';
import 'package:solidpod/src/solid/models/log_record.dart';
import 'package:solidpod/src/solid/models/permission_details.dart';
import 'package:solidpod/src/solid/permission_history.dart';
import 'package:solidpod/src/solid/permission_table.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/share_resource_button.dart';
import 'package:solidpod/src/solid/shared_resource_history.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/get_authoriser.dart';
import 'package:solidpod/src/widgets/app_bar.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A [StatefulWidget] for showing and editing access permissions to a
/// resource. It displays the permission table of users with access, and
/// allows the user to change access permissions: by granting access
/// to others, changing a recipients access permissions or revoking
/// access permissions.
///
/// Parameters:
/// - [child] - the child widget to return to.
/// - [title] - Page title to show in the app bar.
/// - [backgroundColor] - Background color.
/// - [showAppBar] - Boolean flag describing whether to show app bar.
/// - [isExternalRes] - Boolean flag describing whether the resource
/// is externally owned.
/// - [accessModeList] - List of access mode options to show.
/// - [recipientTypeList] - List of recipient type options to show.
/// - [ownerWebId] - WebId of the owner of the resource. Required if the resource is externally owned.
/// - [granterWebId] - WebId of the granter of the resource. Required if the resource is externall owned.
/// - [resourceName] - The filename or file url of the resource. If [isExternalRes], it should be the url of the resource.
/// - [isFile] - Boolean flag describing whether the resource is a file. If false, the resource is assumed to be a directory.
/// - [customAppBar] - Specify a custom app bar widget.
/// - [onPermissionGranted] - Callback function called when permissions are granted successfully.
/// - [onNavigateBack] - Callback function called when navigating back from the screen.

class GrantPermissionUi extends StatefulWidget {
  const GrantPermissionUi({
    required this.child,
    this.title = 'Demonstrating data sharing functionality',
    this.backgroundColor = const Color.fromARGB(255, 210, 210, 210),
    this.showAppBar = true,
    this.isExternalRes = false,
    this.accessModeList = const ['read', 'write', 'append', 'control'],
    this.recipientTypeList = const ['public', 'indi', 'auth', 'group'],
    this.ownerWebId,
    this.granterWebId,
    this.resourceName,
    this.isFile = true,
    this.dataFilesMap = const {},
    this.customAppBar,
    this.onPermissionGranted,
    this.onNavigateBack,
    super.key,
  }) : assert(
          // Requires ownerWebId and granterWebId if resource
          // is an externally owned.
          isExternalRes == false ||
              (ownerWebId != null && granterWebId != null),
          'ownerWebId and granterWebId must be provided if isExternalRes == true',
        );

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

  /// String to assign the webId of the resource owner. Must
  /// be set if [isExternalRes] is set to true.

  final String? ownerWebId;

  /// String to assign the external webId of the resource granter. Must
  /// be set if [isExternalRes] is set to true.

  final String? granterWebId;

  /// The list of access modes to be displayed. By default all four types of
  /// access mode are listed.

  final List<String> accessModeList;

  /// The list of types of recipients receiving permission to access the resource. By default all four types of recipient are listed.

  final List<String> recipientTypeList;

  /// The name of the file or directory permission is being set to. This is a
  /// non required parameter. If not set there will be a text field to define
  /// the file name. If [isExternalRes] is set to true this must be set and the
  /// value should be the url of the resource.

  final String? resourceName;

  /// A flag to determine whether the given resource is a file or not. This is
  /// a parameter with default value true. In the case where [resourceName] is
  /// not set there will be a toggle to define this parameter.
  /// If [isExternalRes] is set to true this must be set and the value should
  /// be the url of the resource. Also if [resourceName] is set this flag must
  /// also be set

  final bool isFile;

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
  /// Flag to check whether permission table is initialised.

  bool permTableInitialied = false;

  /// Flag to check whether permission history is initialised.

  bool permHistoryInitialied = false;

  /// Define access mode list

  List<AccessMode> accessModeList = [];

  /// Define recipient type list

  List<RecipientType> recipientTypeList = [];

  /// Filename text controller

  final fileNameController = TextEditingController();

  /// Permission data map of a file

  Map<dynamic, dynamic> permDataMap = {};

  /// Owner WebId

  String _ownerWebId = '';

  /// Granter WebId

  String _granterWebId = '';

  /// File name of the current permission data map

  String permDataFile = '';

  /// Flag to track if permissions were granted successfully.

  bool permissionsGrantedSuccessfully = false;

  /// Pod data list retreived as a Future

  late Future<PermissionDetails?> getACLPerm;

  /// Permission history list retreived as a Future

  late Future<List<LogRecord>> getPermHistoryList;

  /// Permission history list

  List<LogRecord> permHistoryList = [];

  /// Unfiltered permission history list

  List<LogRecord> unFilteredPermHistoryList = [];

  /// Flag to check whether permission history is initialised.

  bool showCurrentPermOnly = false;

  /// A flag to identify if the resource is a file or not
  bool isFile = true;

  /// Gets permission details data from ACL on POD server if necessary.

  Future<PermissionDetails?> loadACLData(
    String resName, {
    bool isFile = true,
    bool isExternalRes = false,
  }) async {
    final SolidFunctionCallStatus response = await chkExistsAndHasAcl(
      fileName: resName,
      isFile: isFile,
      isExternalRes: isExternalRes,
    );

    switch (response) {
      case SolidFunctionCallStatus.aclFound:

        // Permission map from ACL of resource
        final Map<dynamic, dynamic> result = await readPermission(
          fileName: resName,
          isFile: isFile,
          isExternalRes: isExternalRes,
        );

        // Permission Details object to store permission map from ACL, and owner
        // and granter of a resource.
        final permissionDetails = PermissionDetails(
          permissionMap: result,
          ownerWebId: await getAuthoriser(
            isExternalRes: isExternalRes,
            webId: widget.ownerWebId,
          ),
          granterWebId: await getAuthoriser(
            isExternalRes: isExternalRes,
            webId: widget.granterWebId,
          ),
        );

        return permissionDetails;

      case SolidFunctionCallStatus.notLoggedIn:
        await _alert('Please login first to retrieve permission');

      case SolidFunctionCallStatus.noAclFound:
        await _alert(noAclMsg);

      default:
        await _alert('Unknown error');
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    // Load permission map from ACL, owner and granter web ids
    if (widget.resourceName != null) {
      getACLPerm = loadACLData(
        widget.resourceName as String,
        isFile: widget.isFile,
        isExternalRes: widget.isExternalRes,
      );
      getPermHistoryList =
          sharedResourcesHistory(resourceName: widget.resourceName as String);
      // permHistoryList = [];
    }
  }

  /// Update the permission data map

  Future<void> _updatePermissions(
    String fileName, {
    bool isFile = true,
    bool isExternalRes = false,
  }) async {
    final pdata = await loadACLData(
      fileName,
      isFile: isFile,
      isExternalRes: isExternalRes,
    );
    final updatedPermHistoryList =
        await sharedResourcesHistory(resourceName: fileName);

    assert(pdata != null);

    if (pdata!.permissionMap.isEmpty) {
      await _alert('We could not find a resource by the name $fileName');
    } else {
      setState(() {
        debugPrint('grantPermissionUi: setState: updating permissionMap...');
        permDataMap = pdata.permissionMap;
        permDataFile = fileName;
        _ownerWebId = pdata.ownerWebId;
        _granterWebId = pdata.granterWebId;
      });
    }

    if (updatedPermHistoryList.isEmpty) {
      await _alert(
        'We could not find permission log entries for resource by the name $fileName',
      );
    } else {
      setState(() {
        debugPrint('grantPermissionUi: setState: updating permHistoryList...');
        permHistoryList = updatedPermHistoryList;
        // Set full unfiltered list to current list from updated
        // log fetch
        unFilteredPermHistoryList = updatedPermHistoryList;
        debugPrint(
          'GrantPermissionUi: setState: last record: ${permHistoryList.last.dateTimeStr}',
        );
        debugPrint(
          'GrantPermissionUi: setState: length: ${permHistoryList.length}',
        );
      });
    }
  }

  // Search log records
  void _searchLogs(String enteredKeyword) {
    List<LogRecord> results = [];
    if (enteredKeyword.isEmpty) {
      // Display all log records if no search string
      results = unFilteredPermHistoryList;
      // permHistoryList;
    } else {
      // Display log records with recipient name, granter name,
      // permission type, permission matches
      results = unFilteredPermHistoryList.where((item) {
        return item.recipientName
                .toLowerCase()
                .contains(enteredKeyword.toLowerCase()) ||
            item.granterName
                .toLowerCase()
                .contains(enteredKeyword.toLowerCase()) ||
            item.permissionType
                .toLowerCase()
                .contains(enteredKeyword.toLowerCase()) ||
            item.permissionList
                .toLowerCase()
                .contains(enteredKeyword.toLowerCase());
      }).toList();
    }

    // Refresh the UI
    setState(() {
      permHistoryList = results;
      debugPrint(
        'searchLogs: updated search result to ${permHistoryList.length}',
      );
    });
  }

  /// Filter log records for current/all log records
  void getLatestLogRecords() {
    List<LogRecord> currentLogRecords = [];
    List<String> currentRecipients = [];

    // Loop through logs and get the latest for each resource
    for (final record in permHistoryList) {
      // Store most recent grant record
      if ((record.permissionType).contains('grant')) {
        final recipientWebId = record.recipientWebId;

        currentRecipients =
            currentLogRecords.map((item) => item.recipientWebId).toList();

        if (currentRecipients.contains(recipientWebId)) {
          final int prevMatchIndex = currentLogRecords
              .indexWhere((item) => item.recipientWebId == recipientWebId);
          final String prevDateTime =
              currentLogRecords[prevMatchIndex].dateTimeStr;
          // Update record if this record more recent than stored record
          if ([0, 1].contains(
            DateTime.parse(record.dateTimeStr)
                .compareTo(DateTime.parse(prevDateTime)),
          )) {
            currentLogRecords[prevMatchIndex] = record;
          }
        } else {
          // Store record if no prev record for this recipient
          currentLogRecords.add(record);
        }
      } else {
        // Skip revoke records
        continue;
      }
    }

    // Refresh the UI
    setState(() {
      permHistoryList = currentLogRecords;
      debugPrint(
        'getLatestLogRecords: number ${permHistoryList.length}',
      );
    });
  }

  /// Private function to call alert dialog in grant permission UI context
  Future<void> _alert(String msg) async => alert(context, msg);

  /// Build the main widget
  Widget _buildPermPage(
    BuildContext context, [
    PermissionDetails? initPermDetails,
    List<LogRecord>? initPermHistoryList,
  ]) {
    // Check if future is set or not. If set display the permission map
    if (initPermDetails != null && permTableInitialied == false) {
      permDataMap = initPermDetails.permissionMap;
      _ownerWebId = initPermDetails.ownerWebId;
      _granterWebId = initPermDetails.granterWebId;
      permDataFile = widget.resourceName!;
      permTableInitialied = true;
    }

    if (initPermHistoryList != null && permHistoryInitialied == false) {
      permHistoryList = initPermHistoryList;
      // Set full unfiltered list to current list from initial
      // log fetch
      unFilteredPermHistoryList = initPermHistoryList;
      permHistoryInitialied = true;
    }

    final retrievePermissionButton = ElevatedButton(
      child: const Text('Retrieve permissions'),
      onPressed: () async {
        final fileName = fileNameController.text;
        if (fileName.isEmpty) {
          await _alert('Please enter a file name');
        } else {
          await _updatePermissions(
            fileName,
            isFile: isFile,
          );
        }
      },
    );

    bool getIsFile() => widget.resourceName != null ? widget.isFile : isFile;

    // Use customAppBar if provided
    final customAppBar = widget.customAppBar ??
        defaultAppBar(
          context,
          widget.title,
          widget.backgroundColor,
          widget.child,
          onNavigateBack: () => widget.onNavigateBack?.call(),
          getResult: () => permissionsGrantedSuccessfully,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          // Display app bar if showAppBar selected
          // AppBar will be defaultAppBar() if customAppBar()
          // not provided
          appBar: widget.showAppBar ? customAppBar : null,

          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                smallGapV,
                // Sharing heading
                makeHeading(
                  makeSharingTitleStr(
                    fileName: widget.resourceName,
                    isFile: widget.isFile,
                  ),
                  bold: false,
                  addColor: false,
                  addPadding: false,
                ),
                smallGapV,
                // Choose resource and show _updatePermissions button
                if (widget.resourceName == null) ...[
                  getResourceForm(
                    formController: fileNameController,
                    isFile: isFile,
                    onResourceTypeChange: (bool v) =>
                        setState(() => isFile = v),
                  ),
                  smallGapV,
                  retrievePermissionButton,
                  smallGapV,
                ],
                ShareResourceButton(
                  resourceName: widget.resourceName,
                  fileNameController: fileNameController,
                  accessModeList: widget.accessModeList,
                  recipientTypeList: widget.recipientTypeList,
                  updatePermissionsFunction: _updatePermissions,
                  ownerWebId: _ownerWebId,
                  granterWebId: _granterWebId,
                  isExternalRes: widget.isExternalRes,
                  isFile: widget.isFile,
                  dataFilesMap: widget.dataFilesMap,
                  onPermissionGranted: widget.onPermissionGranted,
                ),

                mediumGapV,
                makeSubHeading('People with current access', addPadding: false),
                PermissionTable(
                  resourceName: permDataFile,
                  permDataMap: permDataMap,
                  ownerWebId: _ownerWebId,
                  granterWebId: _granterWebId,
                  updatePermissionsFunction: _updatePermissions,
                  parentWidget: widget.child,
                  isFile: getIsFile(),
                  isExternalRes: widget.isExternalRes,
                  constraints: constraints,
                ),
                mediumGapV,
                makeSubHeading(
                  showCurrentPermOnly
                      ? 'People with current access'
                      : 'Permission history',
                  addPadding: false,
                ),
                smallGapV,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 5.0,
                  children: [
                    Expanded(
                      flex: 3,
                      // Search logs field
                      child: TextField(
                        onChanged: (value) => _searchLogs(value),
                        decoration: const InputDecoration(
                          labelText:
                              'Search access level, permission type, recipient or granter name',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: 'Enter search text',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(25.0)),
                          ),
                        ),
                      ),
                    ),
                    // Current/History permission switch
                    SizedBox(
                      width: 170.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 5.0,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              showCurrentPermOnly
                                  ? 'Current Permissions'
                                  : 'All Permissions',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          Switch(
                            // This bool value toggles the switch.
                            value: showCurrentPermOnly,
                            activeThumbColor: ActionColors.success,
                            onChanged: (bool value) {
                              // This is called when the user toggles the switch.
                              setState(() {
                                showCurrentPermOnly = value;
                              });
                              // Update permHistoryList
                              if (showCurrentPermOnly) {
                                getLatestLogRecords();
                              } else {
                                setState(() {
                                  permHistoryList = unFilteredPermHistoryList;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                vSmallGapV,
                PermissionHistory(
                  // Force history rebuild on permission history change
                  key: ValueKey(permHistoryList),
                  resourceName: widget.resourceName!,
                  permHistory: permHistoryList,
                  constraints: constraints,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.resourceName == null
      ? _buildPermPage(context)
      : FutureBuilder(
          future: Future.wait([
            // Future that returns List of current access from ACL
            getACLPerm,
            // Future that returns List<LogRecord> from permission log
            getPermHistoryList,
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(body: loadingScreen(normalLoadingScreenHeight));
            }
            final PermissionDetails initCurrentPerm =
                snapshot.data![0] as PermissionDetails;
            final List<LogRecord> initPermHistoryList =
                snapshot.data![1] as List<LogRecord>;
            return initCurrentPerm.permissionMap.isEmpty
                ? widget.child
                : _buildPermPage(context, initCurrentPerm, initPermHistoryList);
          },
        );
}
