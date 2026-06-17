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
import 'package:demopod/features/manage_acl_folder.dart';
import 'package:demopod/features/permission_callback_demo.dart';
import 'package:demopod/features/multiple_resource_sharing.dart';
import 'package:demopod/utils/ensure_resource.dart';

// A bold section heading shared by the extracted sections below.

Widget _sectionHeading(String title) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

// Lay a group of buttons out as a wrapping row so that several buttons sit
// side by side rather than one per line.

Widget _buttonRow(List<Widget> buttons) {
  return Wrap(
    spacing: 10,
    runSpacing: 8,
    children: buttons,
  );
}

/// Builds the login management section widgets.

List<Widget> buildLoginManagementSection(
  BuildContext context,
  VoidCallback onResetWebId,
  Widget Function() createDemoPod,
) {
  return [
    largeGapV,
    _sectionHeading('Solid Server Login Management'),
    smallGapV,
    _buttonRow([
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
    ]),
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
    _sectionHeading('Resource Permission Management'),
    smallGapV,
    _buttonRow([
      ElevatedButton(
        child: const Text(
            'Add/Delete Permissions from a Specific Resource (key-value.ttl)'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
          );

          if (loggedIn) {
            await getKeyFromUserIfRequired(context, currentWidget);

            // Ensure the target resource exists on the Pod before opening the
            // grant permission UI. The button previously failed with a "not
            // found" error when keyvalue/key-value.ttl had never been created.

            if (!context.mounted) return;
            final ready = await ensurePodResourceExists(
              context,
              relativePath: dataFile,
              defaultContent: createDemoTtlStr('key-value'),
            );
            if (!ready) return;

            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GrantPermissionUi(
                  backgroundColor: titleBackgroundColor,
                  resourceNames: [dataFile],
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
      ElevatedButton(
        child: const Text('Create/Delete a Folder with ACL'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
          );

          if (loggedIn) {
            await getKeyFromUserIfRequired(context, currentWidget);

            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageAclFolder(),
              ),
            );
          }
        },
      ),
      ElevatedButton(
        child: const Text('Permission Callback Demo'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
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
      ElevatedButton(
        child: const Text('Add/Delete Permissions from any Resource'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
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
      ElevatedButton(
        child: const Text('Share Multiple Specified Resources'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
          );

          if (loggedIn) {
            await getKeyFromUserIfRequired(context, currentWidget);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MultiResourceShareDemo(child: createHomeWidget()),
              ),
            );
          }
        },
      ),
    ]),
    largeGapV,
    _sectionHeading('Manage External Resources with Access'),
    smallGapV,
    _buttonRow([
      ElevatedButton(
        child: const Text(
            'View specific resource (key-value.ttl) your WebID has access to'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
          );

          if (loggedIn) {
            await getKeyFromUserIfRequired(context, currentWidget);

            // Ensure the target resource exists on the Pod before opening the
            // shared resources UI. The button previously failed with a "not
            // found" error when keyvalue/key-value.ttl had never been created.

            if (!context.mounted) return;
            final ready = await ensurePodResourceExists(
              context,
              relativePath: dataFile,
              defaultContent: createDemoTtlStr('key-value'),
            );
            if (!ready) return;

            if (!context.mounted) return;
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
      ElevatedButton(
        child: const Text('View ALL Resources your WebID has access to'),
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
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
    ]),
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
    _sectionHeading('Setup Wizard Demo'),
    smallGapV,
    _buttonRow([
      ElevatedButton(
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            clientId: clientIdVal,
            redirectUris: redirectUrisList,
            postLogoutRedirectUris: postLogoutRedirectUrisList,
            context: context,
          );

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
    ]),
    smallGapV,
  ];
}
