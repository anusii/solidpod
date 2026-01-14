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
/// Authors: Anushka Vidanage, Jess Moore, Ashley Tang, Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/chk_exists_and_has_acl.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';
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
    this.isFile = true,
    this.dataFilesMap = const {},
    this.customAppBar,
    this.onPermissionGranted,
    this.onNavigateBack,
    super.key,
  }) : assert(
          // Requires externalWebId of resource owner to be provided if resource
          // is an externally owned resource.
          isExternalRes == false || externalWebId != null,
          'externalWebId must be provided if isExternalRes == true',
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

  /// Form controller
  final formKey = GlobalKey<FormState>();

  /// Filename text controller
  final fileNameController = TextEditingController();

  /// Group name text controller
  final groupNameController = TextEditingController();

  /// Group of webIds text controller
  final groupWebIdsController = TextEditingController();

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

        // Get owner's webID
        final webId = widget.isExternalRes
            ? widget.externalWebId
            : await AuthDataManager.getWebId();
        return [result, webId];
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

  // Get new permission and update the permission map
  Future<void> _updatePermissions(
    String fileName, {
    bool isFile = true,
    bool isExternalRes = false,
  }) async {
    final pdata = await loadPodData(
      fileName,
      isFile: isFile,
      isExternalRes: isExternalRes,
    );
    if (pdata.isNotEmpty) {
      assert(pdata.length == 2);
      final permissionMap = pdata.first;
      final webId = pdata.last;

      if (permissionMap.isEmpty) {
        await _alert('We could not find a resource by the name $fileName');
      } else {
        setState(() {
          permDataMap = permissionMap;
          permDataFile = fileName;
          ownerWebId = webId as String;
        });
      }
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

  // Private function to call alert dialog in grant permission UI context
  Future<void> _alert(String msg) async => alert(context, msg);

  // Private function to show snackbar in grant permission UI context
  Future<void> _showSnackBar(
    String msg,
    Color bgColor, {
    Duration duration = const Duration(seconds: 4),
  }) async =>
      showSnackBar(context, msg, bgColor, duration: duration);

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
            groupNameController,
            groupWebIdsController,
            _updateGroupWebIdInput,
          ),
    };

    // 20260109 jesscmoore Added capability for granters to share
    // resources, as well as resource owners
    final recipientButtonContainer = getButtonContainer(
      buttons: widget.isExternalRes
          // Recipient type buttons for resource granter
          ? [
              for (final rtype in granterRecipientTypes)
                if (recipientTypeList.contains(rtype))
                  getRecipientTypeButton(
                    rtype,
                    onPressed: recipientTypeActions[rtype]!,
                    padding: getPadding(rtype),
                  ),
            ]
          // Recipient type buttons for resource owner
          : [
              for (final rtype in ownerRecipientTypes)
                if (recipientTypeList.contains(rtype))
                  getRecipientTypeButton(
                    rtype,
                    onPressed: recipientTypeActions[rtype]!,
                    padding: getPadding(rtype),
                  ),
            ],
    );

    bool getIsFile() => widget.resourceName != null ? widget.isFile : isFile;

    final permDataTable = buildPermDataTable(
      context: context,
      permDataResource: permDataFile,
      isFile: getIsFile(),
      permDataMap: permDataMap,
      ownerWebId: ownerWebId,
      parentWidget: widget.child,
      onDeleteFuncion: _updatePermissions,
      isExternalRes: widget.isExternalRes,
    );

    final grantPermissionButton = getButton(
      'Grant Permission',
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          if (selectedRecipientType.type.isNotEmpty) {
            if (selectedPermList.isNotEmpty) {
              final dataFile = widget.resourceName ?? fileNameController.text;

              SolidFunctionCallStatus result;
              try {
                result = await grantPermission(
                  fileName: dataFile,
                  isFile: getIsFile(),
                  permissionList: selectedPermList,
                  recipientType: selectedRecipientType,
                  recipientWebIdList: finalWebIdList as List,
                  ownerWebId: ownerWebId,
                  isExternalRes: widget.isExternalRes,
                  groupName: selectedRecipientType == RecipientType.group
                      ? groupNameController.text.trim()
                      : null,
                );
              } on Object catch (e, stackTrace) {
                result = SolidFunctionCallStatus.fail;
                debugPrintException(e, stackTrace);
              }

              if (result == SolidFunctionCallStatus.success) {
                _showSnackBar(successMsg, Colors.green);
                await _updatePermissions(dataFile, isFile: getIsFile());

                // Mark permissions as granted successfully for callback tracking
                setState(() => permissionsGrantedSuccessfully = true);

                // Trigger the onPermissionGranted callback if provided
                widget.onPermissionGranted?.call();
              } else if (result == SolidFunctionCallStatus.fail) {
                // More detailed error message with troubleshooting tips
                _showSnackBar(failureMsg, Colors.red);

                // Also log to console for debugging
                debugPrintFailure(dataFile, finalWebIdList, selectedPermList);
              } else if (result == SolidFunctionCallStatus.notInitialised) {
                _showSnackBar(podNotInitMsg, warnBgColor);
              } else {
                await _alert(updatePermissionMsg);
              }
            } else {
              await _alert('Please select one or more file access permissions');
            }
          } else {
            await _alert('Please select a type of recipient');
          }
        }
      },
    );

    final form = getForm(
      formKey: formKey,
      welcomeHeading:
          buildHeading(getWelcomeStr(widget.resourceName), 22, Colors.blueGrey),
      children: [
        if (widget.resourceName == null) ...[
          getResourceForm(
            formController: fileNameController,
            isFile: isFile,
            onResourceTypeChange: (bool v) => setState(() => isFile = v),
          ),
          smallGapV,
          retrievePermissionButton,
        ],
        largeGapV,
        getHeading('Select the recipient/s of file access permissions'),
        getRecipientText(selectedRecipientType, selectedRecipientDetails),
        recipientButtonContainer,
        smallGapV,
        getHeading('Select the list of file access permissions'),
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
        getHeading('Granted file access permissions'),
        getFormScrollbar(tableScrollController, permDataTable),
      ],
    );

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
      appBar: widget.showAppBar ? customAppBar : null,

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
