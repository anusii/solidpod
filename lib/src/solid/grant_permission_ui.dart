/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Thursday 2026-01-15 13:42:22 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang, Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/chk_exists_and_has_acl.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';
import 'package:solidpod/src/solid/permission_table.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/share_resource_button.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/heading.dart';
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
  /// Initialise widget variables.

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

  /// The list of types of recipients receiving permission to access the resource. By default all four
  /// types of recipient are listed.

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

  List<AccessMode> accessModeList = [];

  /// Define recipient type list

  List<RecipientType> recipientTypeList = [];

  /// Filename text controller

  final fileNameController = TextEditingController();

  /// Group name text controller

  final groupNameController = TextEditingController();

  /// Group of webIds text controller

  final groupWebIdsController = TextEditingController();

  /// Permission data map of a file

  Map<dynamic, dynamic> permDataMap = {};

  /// Owner WebId

  String _ownerWebId = '';

  /// Granter WebId

  String _granterWebId = '';

  /// File name of the current permission data map

  String permDataFile = '';

  /// Selected recipient

  RecipientType selectedRecipientType = RecipientType.none;

  /// Selected recipient details

  String selectedRecipientDetails = '';

  /// List of webIds for group permission

  List<dynamic> finalWebIdList = [];

  /// Selected list of permissions

  List<String> selectedPermList = [];

  /// Flag to track if permissions were granted successfully.

  bool permissionsGrantedSuccessfully = false;

  /// Pod data list retreived as a Future

  late Future<List<dynamic>> podDataList;

  /// A flag to identify if the resource is a file or not
  bool isFile = true;

  /// Runs multiple asynchronous functions to get the data from
  /// POD server if necessary.

  Future<List<dynamic>> loadPodData(
    String resName, {
    bool isFile = true,
    bool isExternalRes = false,
  }) async {
    final SolidFunctionCallStatus response = await chkExistsAndHasAcl(
      fileName: resName,
      isFile: isFile,
      isExternalRes: widget.isExternalRes,
    );

    switch (response) {
      case SolidFunctionCallStatus.aclFound:
        final Map<dynamic, dynamic> result = await readPermission(
          fileName: resName,
          isFile: isFile,
          isExternalRes: widget.isExternalRes,
        );

        // Fetch owner's webID
        // ownerWebId == userWebId if not externally owned resource

        final ownerWebId = widget.isExternalRes
            ? widget.ownerWebId
            : await AuthDataManager.getWebId();
        // Fetch granter's webID
        // granterWebId == userWebId if not externally owned resource

        final granterWebId = widget.isExternalRes
            ? widget.granterWebId
            : await AuthDataManager.getWebId();

        return [result, ownerWebId, granterWebId];

      case SolidFunctionCallStatus.notLoggedIn:
        await _alert('Please login first to retrieve permission');

      case SolidFunctionCallStatus.noAclFound:
        await _alert(noAclMsg);

      default:
        await _alert('Unknown error');
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    // Load future
    if (widget.resourceName != null) {
      podDataList = loadPodData(
        widget.resourceName as String,
        isFile: widget.isFile,
        isExternalRes: widget.isExternalRes,
      );
    }

    // Load access mode list to be displayed
    for (final accessModeStr in widget.accessModeList) {
      accessModeList.add(getAccessMode(accessModeStr));
    }

    // Load recipient type list to be displayed
    for (final recTypeStr in widget.recipientTypeList) {
      recipientTypeList.add(RecipientType.getInstanceByValue(recTypeStr));
    }
  }

  /// Get new permission and update the permission map

  Future<void> _updatePermissions(
    String fileName, {
    bool isFile = true,
    bool isExternalRes = false,
  }) async {
    debugPrint('_updatePermissions(): ...');
    final pdata = await loadPodData(
      fileName,
      isFile: isFile,
      isExternalRes: isExternalRes,
    );
    if (pdata.isNotEmpty) {
      assert(pdata.length == 3);
      final permissionMap = pdata.first;
      final ownerWebId = pdata[1];
      final granterWebId = pdata.last;

      if (permissionMap.isEmpty) {
        await _alert('We could not find a resource by the name $fileName');
      } else {
        setState(() {
          permDataMap = permissionMap;
          permDataFile = fileName;
          _ownerWebId = ownerWebId as String;
          _granterWebId = granterWebId as String;
        });
      }
    }
  }

  /// Private function to call alert dialog in grant permission UI context
  Future<void> _alert(String msg) async => alert(context, msg);

  /// Build the main widget
  Widget _buildPermPage(BuildContext context, [List<Object?>? futureObjList]) {
    /// Controller for vertical page scrolling
    final pageScrollController = ScrollController();

    // Check if future is set or not. If set display the permission map
    if (futureObjList != null && pageInitialied == false) {
      permDataMap = futureObjList.first as Map;
      _ownerWebId = futureObjList[1] as String;
      _granterWebId = futureObjList.last as String;
      permDataFile = widget.resourceName!;
      pageInitialied = true;
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
            isExternalRes: widget.isExternalRes,
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

    return Scaffold(
      // Display app bar if showAppBar selected
      // AppBar will be defaultAppBar() if customAppBar()
      // not provided
      appBar: widget.showAppBar ? customAppBar : null,

      // Make Grant Permission UI vertically scrollable
      // Shows when content exceeds display height

      body: Scrollbar(
        // 20250722 jm:
        // For scrollbar visibility before scrolling,
        // set to true, or set property to true
        // in parent app MaterialApp(theme: ThemeData(scrollbarTheme: scrollbarTheme: ScrollbarThemeData(
        // thumbVisibility: WidgetStateProperty.all(true)))
        thumbVisibility: true, // show before user starts scrolling
        controller: pageScrollController,
        child: SingleChildScrollView(
          controller: pageScrollController,
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                smallGapV,
                // Sharing heading
                buildHeading(
                  getWelcomeStr(widget.resourceName),
                  22,
                  Colors.blueGrey,
                ),
                smallGapV,
                // Choose resource to share if not yet selected
                if (widget.resourceName == null) ...[
                  getResourceForm(
                    formController: fileNameController,
                    isFile: isFile,
                    onResourceTypeChange: (bool v) =>
                        setState(() => isFile = v),
                  ),
                  smallGapV,
                  retrievePermissionButton,
                ],
                // Share resource button
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

                largeGapV,
                getHeading('Granted file access permissions'),
                // Permissions table
                PermissionTable(
                  resourceName: permDataFile,
                  permDataMap: permDataMap,
                  ownerWebId: _ownerWebId,
                  granterWebId: _granterWebId,
                  updatePermissionsFunction: _updatePermissions,
                  parentWidget: widget.child,
                  isFile: getIsFile(),
                  isExternalRes: widget.isExternalRes,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      // Build as a separate widget with the possibility of adding a FutureBuilder
      // in the Future

      widget.resourceName == null
          ? _buildPermPage(context)
          : FutureBuilder(
              future: podDataList,
              builder: (context, snapshot) => snapshot.hasData
                  ? snapshot.data!.first == SolidFunctionCallStatus.notLoggedIn
                      ? widget.child
                      : _buildPermPage(context, snapshot.data)
                  : Scaffold(body: loadingScreen(normalLoadingScreenHeight)),
            );
}
