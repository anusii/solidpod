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

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/grant_permission_api.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/models/log_entry.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart' show RecipientPubKey;
import 'package:solidpod/src/solid/utils/key_manager.dart' show KeyManager;
import 'package:solidpod/src/solid/utils/misc.dart';

/// Grant access permissions to [fileName] to the type of recipient
/// or specific recipients, if recipient type is individual or group,
/// and group or individual recipients specified. This action updates
/// the ACL file of the resource in the owner's Pod, and appends a log
/// entry to the permission log in the owner, granter and recipients POD.
///
/// Parameters:
/// - [fileName] - is the name of the file that the [recipientWebIdList]
/// are receiving access to.
/// - [permissionList] - is the list of permissions to be granted to the
/// [recipientWebIdList].
/// - [recipientType] - is the type of the recipient of recipients in the
/// [recipientWebIdList].
/// - [recipientWebIdList] - is the list of webIds of the recipients
/// receiving access permissions to the file.
/// - [ownerWebId] - is the web ID of the owner of the file.
/// - [granterWebId] - is the web ID of the granter of access to the file.
/// This is usually the web ID of the user.
/// - [isExternalRes] - Optional flag describing whether the file is an
/// external resource shared to the user. If set to true, the [fileName]
/// should be the full URL of the file.
/// - [isFile] Optional flag describing whether the resources is a file or
/// not.
/// - [groupName] - Optional name of the group permission.

Future<SolidFunctionCallStatus> grantPermission({
  required String fileName,
  required List<dynamic> permissionList,
  required RecipientType recipientType,
  required List<dynamic> recipientWebIdList,
  required String ownerWebId,
  required String granterWebId,
  bool isFile = true,
  bool isExternalRes = false,
  String? groupName,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to grant permissions. '
      'Please authenticate before calling grantPermission().',
    );
  }

  try {
    if (!await KeyManager.hasSecurityKey()) {
      throw SecurityKeyNotAvailableException(
        'Security key is not available. '
        'Please ensure the security key is set before calling grantPermission().',
      );
    }

    final resourceUrl = await filenameToResourceUrl(
      fileName: fileName,
      isExternalRes: isExternalRes,
      isFile: isFile,
    );

    // Initially check if the resource has a corresponding ACL file. If not
    // return an error.

    if (await resourceHasAcl(resourceUrl, isFile: isFile)) {
      // Check if file exists
      final resStatus = await checkResourceStatus(resourceUrl, isFile: isFile);

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

            // If permission granted to specific recipients
            if (specificRecipientTypeList.contains(recipientType)) {
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
                final sharedAccessList =
                    await recipientPubKey.encryptData(permissionList.join(','));

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

          // 20260112 jesscmoore: the permission logs are not updated if
          // permission granted is to give public access or give access
          //to all authenticated users.

          // Add log entry to owner, granter, and receiver permission log
          // files for the individual recipient or each recipient in the
          // recipient group.

          for (final recipientWebId in recipientWebIdList) {
            final LogEntry logEntryRes = createPermLogEntry(
              permissionList: permissionList,
              resourceUrl: resourceUrl,
              ownerWebId: ownerWebId,
              permissionType: 'grant',
              granterWebId: granterWebId,
              recipientWebId: recipientWebId as String,
            );

            // Log file urls of the owner, granter, and receiver
            final logFilePath = await getPermLogFilePath();

            // Owner
            final ownerLogFileUrl =
                await getFileUrl(logFilePath, webId: ownerWebId);

            // Granter
            final granterLogFileUrl =
                await getFileUrl(logFilePath, webId: granterWebId);

            // Run log entry insert query for the granter
            await addPermLogLine(
              logFileUrl: granterLogFileUrl,
              logEntry: logEntryRes,
            );

            // If owner and the granter is not the same add another log file entry
            // for the owner
            if (ownerLogFileUrl != granterLogFileUrl) {
              await addPermLogLine(
                logFileUrl: ownerLogFileUrl,
                logEntry: logEntryRes,
              );
            }

            // Add log entry if the recipient is either an individual or group of WebIDs
            if (specificRecipientTypeList.contains(recipientType)) {
              final receiverLogFileUrl =
                  await getFileUrl(logFilePath, webId: recipientWebId);

              await addPermLogLine(
                logFileUrl: receiverLogFileUrl,
                logEntry: logEntryRes,
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
}
