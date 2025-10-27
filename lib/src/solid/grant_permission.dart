/// Function to grant permission to a private file in a POD.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/grant_permission_api.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Grant permission to [fileName] for a given [recipientWebIdList].
/// Parameters:
///   [fileName] is the name of the file providing permission to. In case where
///   [isExternalRes] is set to true, [fileName] should be the full URL of the file
///   [isFile] is the flag to identify if the resources is a file or not
///   [permissionList] is the list of permission to be granted
///   [recipientType] is the type of the recipient
///   [recipientWebIdList] is the list of webIds of the permission receivers
///   [ownerWebId] is the web ID of the owner of the file
///   [child] is the child widget to return to
///   [isExternalRes] is the flag to identify if the resource is external
///   [groupName] is the name of the group permission

Future<dynamic> grantPermission(
  String fileName,
  bool isFile,
  List<dynamic> permissionList,
  RecipientType recipientType,
  List<dynamic> recipientWebIdList,
  String ownerWebId,
  BuildContext context,
  Widget child, {
  bool isExternalRes = false,
  String? groupName,
}) async {
  final loggedIn = await loginIfRequired(context);

  if (loggedIn) {
    try {
      await getKeyFromUserIfRequired(context, child);

      final resourceUrl = await filenameToResourceUrl(
        fileName: fileName,
        isExternalRes: isExternalRes,
        isFile: isFile,
      );

      // Initially check if the resource has a corresponding ACL file. If not
      // return an error.

      if (await resourceHasAcl(resourceUrl, isFile: isFile)) {
        // Check if file exists
        final resStatus =
            await checkResourceStatus(resourceUrl, isFile: isFile);

        // Check if recipient/s have initialised their pods with the correct
        // directory structure
        var allRecipientsInitialised = true;
        for (final recipientWebId in recipientWebIdList) {
          final isInitialised =
              await checkPodInitialised(recipientWebId as String);
          if (!isInitialised) {
            allRecipientsInitialised = false;
          }
        }

        if (allRecipientsInitialised) {
          if (resStatus == ResourceStatus.exist) {
            // Add the permission line to the relevant ACL file
            await setPermissionAcl(
              resourceUrl,
              ownerWebId,
              recipientType,
              recipientWebIdList,
              permissionList,
              groupName,
              isFile,
            );

            // Check if the file is encrypted
            final fileIsEncrypted =
                await checkFileEnc(resourceUrl, isExternalRes: isExternalRes);

            // If the file is encrypted then share the individual encryption key
            // with the receiver
            if (fileIsEncrypted) {
              // Get the individual encryption key for the file
              final indKey = isExternalRes
                  ? await KeyManager.getSharedIndividualKey(resourceUrl)
                  : await KeyManager.getIndividualKey(resourceUrl);

              if ([RecipientType.individual, RecipientType.group]
                  .contains(recipientType)) {
                // For each recipient share the individual encryption key

                for (final recipientWebId in recipientWebIdList) {
                  // Setup recipient's public key
                  final recipientPubKey =
                      RecipientPubKey(recipientWebId: recipientWebId as String);

                  // Encrypt individual key
                  final sharedIndKey =
                      await recipientPubKey.encryptData(indKey.base64);

                  // Encrypt resource URL
                  final sharedResPath =
                      await recipientPubKey.encryptData(resourceUrl);

                  // Encrypt the list of permissions
                  permissionList.sort();
                  final sharedAccessList = await recipientPubKey
                      .encryptData(permissionList.join(','));

                  // Generate unique ID for the resource being shared
                  final resUniqueId =
                      getUniqueIdResUrl(resourceUrl, recipientWebId);

                  // Copy shared content to recipient's POD
                  await copySharedKey(
                    recipientWebId,
                    resUniqueId,
                    sharedIndKey,
                    sharedResPath,
                    sharedAccessList,
                  );
                }
              } else {
                // if the recipient type is either public or authenticated agent
                // Copy the key to a publicly available or authenticated user accessible file
                await copySharedKeyUserClass(
                  indKey,
                  resourceUrl,
                  permissionList,
                  recipientType,
                );
              }
            }

            // Add log entry to owner, granter, and receiver permission log files

            // Get user webID
            final userWebId = await AuthDataManager.getWebId() as String;

            for (final recipientWebId in recipientWebIdList) {
              final logEntryRes = createPermLogEntry(
                permissionList,
                resourceUrl,
                ownerWebId,
                'grant',
                userWebId,
                recipientWebId as String,
              );

              // Log file urls of the owner, granter, and receiver
              final logFilePath = await getPermLogFilePath();

              // Owner
              final ownerLogFileUrl = await getFileUrl(logFilePath, ownerWebId);

              // Granter
              final granterLogFileUrl = await getFileUrl(logFilePath);

              // Run log entry insert query for the granter
              await addPermLogLine(
                granterLogFileUrl,
                logEntryRes[0] as String,
                logEntryRes[1] as String,
              );

              // If owner and the granter is not the same add another log file entry
              // for the owner
              if (ownerLogFileUrl != granterLogFileUrl) {
                await addPermLogLine(
                  ownerLogFileUrl,
                  logEntryRes[0] as String,
                  logEntryRes[1] as String,
                );
              }

              // Add log entry if the recipient is either an individual or group of WebIDs
              if ([RecipientType.individual, RecipientType.group]
                  .contains(recipientType)) {
                final receiverLogFileUrl =
                    await getFileUrl(logFilePath, recipientWebId);

                await addPermLogLine(
                  receiverLogFileUrl,
                  logEntryRes[0] as String,
                  logEntryRes[1] as String,
                );
              }
            }
            return SolidFunctionCallStatus.success;
          } else {
            return SolidFunctionCallStatus.fail;
          }
        } else {
          return SolidFunctionCallStatus.notInitialised;
        }
      } else {
        debugPrint('Resource does not have a corresponding ACL file. '
            'If the ACL is inherited provide parent directory as the resource name!');
        return SolidFunctionCallStatus.noAclFound;
      }
    } on Object catch (e, stackTrace) {
      debugPrint('💥 [GrantPermission] Exception occurred: $e');
      debugPrint('📚 [GrantPermission] Stack trace: $stackTrace');
      return SolidFunctionCallStatus.fail;
    }
  } else {
    return SolidFunctionCallStatus.notLoggedIn;
  }
}
