/// Extracted section widgets for the Home screen.
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
/// Authors: Dawei Chen

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart'
    show
        GrantPermissionUi,
        InitialSetupScreenBody,
        SharedResourcesUi,
        getKeyFromUserIfRequired,
        loginIfRequired,
        logoutPopup,
        largeGapV,
        smallGapV;

import 'package:demopod/constants/app.dart';
import 'package:demopod/features/permission_callback_demo.dart';

/// Builds the login management section widgets.

List<Widget> buildLoginManagementSection(
  BuildContext context,
  VoidCallback onResetWebId,
  Widget Function() createDemoPod,
) {
  return [
    largeGapV,
    const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solid Server Login Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    MarkdownTooltip(
      message: 'This will remove from our local device\'s memory the '
          'solid pod login information so that the next time you '
          'start up the app you will need to login to your solid '
          'server hosting your pod.',
      child: ElevatedButton(
        child: const Text('Forget Remote Solid Server Login'),
        onPressed: () async {
          final deleteRes = await deleteLogIn();

          var deleteMsg = '';

          if (deleteRes) {
            deleteMsg = 'Successfully forgot remote solid server login info';
          } else {
            deleteMsg = 'Failed to forget login info. Try again in a while';
          }

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Notice'),
              content: Text(deleteMsg),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'))
              ],
            ),
          );

          onResetWebId();
        },
      ),
    ),
    smallGapV,
    MarkdownTooltip(
      message: 'This will send a request through the browser to the '
          'remote solid server to log you out of your Pod.',
      child: ElevatedButton(
        onPressed: () async {
          await logoutPopup(context, createDemoPod());
        },
        child: const Text('Logout From Remote Solid Server'),
      ),
    ),
  ];
}

/// Builds the permission management and external resources section widgets.

List<Widget> buildPermissionSection(
  BuildContext context,
  Widget currentWidget,
  Widget Function() createHomeWidget,
) {
  return [
    largeGapV,
    const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resource Permission Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    ElevatedButton(
      child: const Text(
          'Add/Delete Permissions from a Specific Resource (key-value.ttl)'),
      onPressed: () async {
        final loggedIn = await loginIfRequired(
          context,
        );

        if (loggedIn) {
          await getKeyFromUserIfRequired(context, currentWidget);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrantPermissionUi(
                backgroundColor: titleBackgroundColor,
                resourceName: 'keyvalue/key-value.ttl',
                // accessModeList: ['read', 'write'],
                // recipientTypeList: ['indi', 'group'],
                // isFile: false,
                child: createHomeWidget(),
              ),
            ),
          );
        }
      },
    ),
    smallGapV,
    ElevatedButton(
      child: const Text('Permission Callback Demo'),
      onPressed: () async {
        final loggedIn = await loginIfRequired(
          context,
        );

        if (loggedIn) {
          await getKeyFromUserIfRequired(context, currentWidget);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PermissionCallbackDemo(child: createHomeWidget()),
            ),
          );
        }
      },
    ),
    smallGapV,
    ElevatedButton(
      child: const Text('Add/Delete Permissions from any Resource'),
      onPressed: () async {
        final loggedIn = await loginIfRequired(
          context,
        );

        if (loggedIn) {
          await getKeyFromUserIfRequired(context, currentWidget);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrantPermissionUi(
                backgroundColor: titleBackgroundColor,
                child: createHomeWidget(),
              ),
            ),
          );
        }
      },
    ),
    largeGapV,
    const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage External Resources with Access',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    ElevatedButton(
      child: const Text(
          'View specific resource (key-value.ttl) your WebID has access to'),
      onPressed: () async {
        final loggedIn = await loginIfRequired(
          context,
        );

        if (loggedIn) {
          await getKeyFromUserIfRequired(context, currentWidget);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SharedResourcesUi(
                backgroundColor: titleBackgroundColor,
                fileName: 'key-value.ttl',
                child: createHomeWidget(),
              ),
            ),
          );
        }
      },
    ),
    smallGapV,
    ElevatedButton(
      child: const Text('View ALL Resources your WebID has access to'),
      onPressed: () async {
        final loggedIn = await loginIfRequired(
          context,
        );

        if (loggedIn) {
          await getKeyFromUserIfRequired(context, currentWidget);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SharedResourcesUi(
                backgroundColor: titleBackgroundColor,
                child: createHomeWidget(),
              ),
            ),
          );
        }
      },
    ),
    smallGapV,
  ];
}

/// Builds the setup wizard section widgets.

List<Widget> buildSetupWizardSection(
  BuildContext context,
  Widget Function() createHomeWidget,
) {
  return [
    largeGapV,
    const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Wizard Demo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    smallGapV,
    ElevatedButton(
      onPressed: () async {
        final loggedIn = await loginIfRequired(context);

        if (!loggedIn) {
          debugPrint('Please login to run the demo');
          return;
        }

        final webId = await getWebId();
        if (webId == null) {
          debugPrint('web ID is not available');
          return;
        }

        final sampleDirUrl = await getDirUrl([
          await getDataDirPath(),
          'setup_wizard_demo',
        ].join('/'));
        final sampleFileName = 'setup_wizard_demo.ttl';
        final sampleFileUrl = await getFileUrl([
          await getDataDirPath(),
          'sampleFileName',
        ].join('/'));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: SafeArea(
                child: InitialSetupScreenBody(
                  resNeedToCreate: {
                    'folders': [sampleDirUrl],
                    'files': [sampleFileUrl],
                    'fileNames': [sampleFileName],
                  },
                  child: createHomeWidget(),
                ),
              ),
            ),
          ),
        );
      },
      child: const Text('Show Solid Pod Setup Wizard (Using Real Component)'),
    ),
    smallGapV,
  ];
}
