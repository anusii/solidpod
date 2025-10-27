/// A screen to demonstrate the data sharing capabilities of PODs.
///
// Time-stamp: <Wednesday 2025-10-08 15:39:39 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
///
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang, Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/heading.dart';
import 'package:solidpod/src/solid/utils/permission_helper.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';
import 'package:solidpod/src/widgets/app_bar.dart';
import 'package:solidpod/src/widgets/file_permission_data_table.dart';
import 'package:solidpod/src/widgets/group_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/ind_webid_input_dialog.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

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
  List<AccessMode> accessModeList = [];

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

  /// Pod data list retreived as a Future
  late Future<List<dynamic>> podDataList;

  /// A flag to identify if the resource is a file or not
  bool isFile = true;

  /// Runs multiple asynchronous functions to get the data from
  /// POD server if necessary.
  Future<List<dynamic>> _loadPodData(
    String resourceName,
    Widget child, {
    bool isFile = true,
  }) async {
    final result = await readPermission(
      resourceName,
      isFile,
      context,
      child,
      isExternalRes: widget.isExternalRes,
    );
    final webId = widget.isExternalRes
        ? widget.externalWebId
        : await AuthDataManager.getWebId();
    return [result, webId];
  }

  @override
  void initState() {
    super.initState();
    // Load future
    if (widget.resourceName != null) {
      podDataList = _loadPodData(widget.resourceName!, widget);
    }

    // Load access mode list to be displayed
    for (final accessModeStr in widget.accessModeList) {
      accessModeList.add(getAccessMode(accessModeStr));
    }

    // Load recipient list to be displayed
    for (final recTypeStr in widget.recipientTypeList) {
      recipientTypeList.add(RecipientType.getInstanceByValue(recTypeStr));
    }
  }

  // Get new permission and update the permission map
  Future<void> _updatePermissions(String fileName, {bool isFile = true}) async {
    final pdata = await _loadPodData(fileName, widget.child, isFile: isFile);
    final permissionMap = pdata.first;

    if (permissionMap == SolidFunctionCallStatus.notLoggedIn) {
      await _alert('Please login first to retrieve permission');
    } else if (permissionMap == SolidFunctionCallStatus.noAclFound) {
      await _alert(noAclMsg);
    } else if ((permissionMap as Map).isEmpty) {
      await _alert('We could not find a resource by the name $fileName');
    } else {
      // updatePermTable(permissionMap, webId as String, fileName);
      setState(() {
        permDataMap = permissionMap;
        permDataFile = fileName;
        ownerWebId = pdata.last;
      });
    }
  }

  // Update checkbox tick data.

  void _updateCheckbox(bool newValue, AccessMode accessMode) => setState(() {
        switch (accessMode) {
          case AccessMode.read:
            readChecked = newValue;
          case AccessMode.write:
            writeChecked = newValue;
          case AccessMode.control:
            controlChecked = newValue;
          case AccessMode.append:
            appendChecked = newValue;
        }
        if (newValue) {
          selectedPermList.add(accessMode.mode);
        } else {
          selectedPermList.remove(accessMode.mode);
        }
      });

  List<Widget> _getButtons(List<RecipientType> recipientTypeList) {
    EdgeInsetsGeometry? getPadding(RecipientType rtype) =>
        rtype == RecipientType.public ? null : const EdgeInsets.only(left: 8.0);

    final recipientTypeActions = {
      RecipientType.public: () => setState(() {
            selectedRecipientType = RecipientType.public;
            selectedRecipientDetails = '';
            finalWebIdList = [publicAgent.value];
          }),
      RecipientType.authUser: () => setState(() {
            selectedRecipientType = RecipientType.authUser;
            selectedRecipientDetails = '';
            finalWebIdList = [authenticatedAgent.value];
          }),
      RecipientType.individual: () async => await indWebIdInputDialog(
            context,
            _updateIndWebIdInput,
            widget.dataFilesMap,
          ),
      RecipientType.group: () async => await groupWebIdInputDialog(
            context,
            formControllerGroupName,
            formControllerGroupWebIds,
            _updateGroupWebIdInput,
          ),
    };

    return [
      for (final rtype in relevantRecipientTypes)
        if (recipientTypeList.contains(rtype))
          getRecipientTypeButton(
            rtype,
            onPressed: recipientTypeActions[rtype]!,
            padding: getPadding(rtype),
          ),
    ];
  }

  // Update individual webid input data
  void _updateIndWebIdInput(String receiverWebId) => setState(() {
        selectedRecipientType = RecipientType.individual;
        selectedRecipientDetails = receiverWebId;
        finalWebIdList = [receiverWebId];
      });

  // Update group of webids input data
  void _updateGroupWebIdInput(String groupName, List<dynamic> webIdList) =>
      setState(() {
        selectedRecipientType = RecipientType.group;
        selectedRecipientDetails =
            '$groupName with WebIDs ${webIdList.join(', ')}';
        finalWebIdList = webIdList;
      });

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

    final retrievePermissionButton = getRetrieveButton(
      context,
      formControllerFileName.text,
      isFile,
      onRetrieve: _updatePermissions,
    );

    final buttonContainer = getButtonContainer(
      buttons: widget.isExternalRes ? [] : _getButtons(recipientTypeList),
    );

    final grantPermissionButton = getButton(
      'Grant Permission',
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          if (selectedRecipientType.type.isNotEmpty) {
            if (selectedPermList.isNotEmpty) {
              final dataFile =
                  widget.resourceName ?? formControllerFileName.text;

              SolidFunctionCallStatus? result;
              try {
                result = await grantPermission(
                  dataFile,
                  true,
                  selectedPermList,
                  selectedRecipientType,
                  finalWebIdList as List,
                  ownerWebId,
                  context,
                  widget.child,
                  isExternalRes: widget.isExternalRes,
                  groupName: selectedRecipientType == RecipientType.group
                      ? formControllerGroupName.text.trim()
                      : null,
                ) as SolidFunctionCallStatus?;
              } on Object catch (e, stackTrace) {
                printException(e);
                printStackTrace(stackTrace);
                result = SolidFunctionCallStatus.fail;
              }

              if (result == SolidFunctionCallStatus.success) {
                if (!context.mounted) return;
                showSnackBar(context, successMsg, Colors.green);
                await _updatePermissions(dataFile, isFile: isFile);

                // Mark permissions as granted successfully for callback tracking
                setState(() => permissionsGrantedSuccessfully = true);

                // Trigger the onPermissionGranted callback if provided
                widget.onPermissionGranted?.call();
              } else if (result == SolidFunctionCallStatus.fail) {
                if (!context.mounted) return;

                // Also log to console for debugging
                printFailure(dataFile);
                printRecipients(finalWebIdList);
                printPermissions(selectedPermList);

                // More detailed error message with troubleshooting tips
                showSnackBar(context, failureMsg, Colors.red);
              } else if (result == SolidFunctionCallStatus.notInitialised) {
                if (!context.mounted) return;
                showSnackBar(context, podNotInitMsg, warnBgColor);
              } else {
                await _alert(updatePermissionMsg);
              }
            } else {
              await _alert(selectPermissionMsg);
            }
          } else {
            await _alert(selectRecipientTypeMsg);
          }
        }
      },
    );

    final permDataTable = buildPermDataTable(
      context,
      permDataFile,
      widget.isFile ?? isFile,
      permDataMap,
      ownerWebId,
      widget.child,
      _updatePermissions,
      isExternalRes: widget.isExternalRes,
    );

    final form = Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            buildHeading(getWelcomeStr(widget.resourceName), 22),
            smallGapV,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.resourceName == null) ...[
                  getResourceForm(
                    formControllerFileName,
                    isFile,
                    (bool value) => setState(() => isFile = value),
                  ),
                  smallGapV,
                  retrievePermissionButton,
                ],
                largeGapV,
                getHeading(selectRecipientPermissionStr),
                getRecipientText(
                  selectedRecipientType,
                  selectedRecipientDetails,
                ),
                buttonContainer,
                smallGapV,
                getHeading(selectFilePermissionStr),
                ...getPermissionCheckBoxes(
                  accessModeList,
                  modeSwitches: {
                    AccessMode.read: readChecked,
                    AccessMode.write: writeChecked,
                    AccessMode.control: controlChecked,
                    AccessMode.append: appendChecked,
                  },
                  onUpdate: _updateCheckbox,
                ),
                grantPermissionButton,
                largeGapV,
                getHeading(grantPermissionStr),
                getFormScrollbar(tableScrollController, permDataTable),
              ],
            ),
          ],
        ),
      ),
    );

    final appBar = widget.customAppBar ??
        defaultAppBar(
          context,
          widget.title,
          widget.backgroundColor,
          widget.child,
          onNavigateBack: () => widget.onNavigateBack?.call(),
          getResult: () => permissionsGrantedSuccessfully,
        );

    return Scaffold(
      appBar: widget.showAppBar ? appBar : null,

      // Make Grant Permission UI vertically scrollable
      // Shows when content exceeds display height
      body: getPageScrollbar(pageScrollController, form),
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
