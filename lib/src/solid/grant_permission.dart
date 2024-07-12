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

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/api/permission_api.dart';

/// Grant permission to [fileName] for a given [recipientWebIdList].
/// Parameters:
///   [fileName] is the name of the file providing permission to
///   [fileFlag] is the flag to identify if the resources is a file or not
///   [permissionList] is the list of permission to be granted
///   [recipientType] is the type of the recipient
///   [recipientWebIdList] is the list of webIds of the permission receivers
///   [isFileEncrypted] is the flag to determine if the file is encrypted or not
///   [child] is the child widget to return to

Future<void> grantPermission(
    String fileName,
    bool fileFlag,
    List<dynamic> permissionList,
    RecipientType recipientType,
    List<dynamic> recipientWebIdList,
    bool isFileEncrypted,
    BuildContext context,
    Widget child,
    [String? groupName]) async {
  await loginIfRequired(context);

  await getKeyFromUserIfRequired(context, child);

  // Get the file path
  final filePath = [await getDataDirPath(), fileName].join('/');

  // Get the url of the file
  final resourceUrl = await getFileUrl(filePath);

  // Check if file exists
  final resStatus = await checkResourceStatus(resourceUrl, fileFlag: fileFlag);

  if (resStatus == ResourceStatus.exist) {
    // Add the permission line to the relevant ACL file
    await setPermissionAcl(resourceUrl, recipientType, recipientWebIdList,
        permissionList, groupName);

    // Check if the file is encrypted
    final fileIsEncrypted = await checkFileEnc(resourceUrl);

    // If the file is encrypted then share the individual encryption key
    // with the receiver
    if (fileIsEncrypted) {
      // Get the individual encryption key for the file
      final indKey = await KeyManager.getIndividualKey(resourceUrl);

      if ([RecipientType.individual, RecipientType.group]
          .contains(recipientType)) {
        // For each recipient share the individual encryption key

        for (final recipientWebId in recipientWebIdList) {
          // Setup recipient's public key
          final recipientPubKey =
              RecipientPubKey(recipientWebId: recipientWebId as String);

          // Encrypt individual key
          final sharedIndKey = await recipientPubKey.encryptData(indKey.base64);

          // Encrypt resource URL
          final sharedResPath = await recipientPubKey.encryptData(resourceUrl);

          // Encrypt the list of permissions
          permissionList.sort();
          final sharedAccessList =
              await recipientPubKey.encryptData(permissionList.join(','));

          // Generate unique ID for the resource being shared
          final resUniqueId = getUniqueIdResUrl(resourceUrl, recipientWebId);

          // Copy shared content to recipient's POD
          await copySharedKey(recipientWebId, resUniqueId, sharedIndKey,
              sharedResPath, sharedAccessList);
        }
      } else {
        // if the recipient type is either public or authenticated agent
        // Copy the key to a publicly available or authenticated user accessible file
        await copySharedKeyUserClass(
            indKey, resourceUrl, permissionList, recipientType);
      }
    }

    // Add log entry to owner, granter, and receiver permission log files
    // av20240703: At this instance the owner and the granter are the same
    //             At some point we might need to change this function so that
    //             it can be used in the instances where owner is different from
    //             the granter

    // Get user webID
    final userWebId = await AuthDataManager.getWebId() as String;

    for (final recipientWebId in recipientWebIdList) {
      final logEntryRes = createPermLogEntry(permissionList, resourceUrl,
          userWebId, 'grant', userWebId, recipientWebId as String);

      // Log file urls of the owner, granter, and receiver
      final logFilePath = await getPermLogFilePath();
      final ownerLogFileUrl = await getFileUrl(logFilePath);

      // Run log entry insert query for the owner
      await addPermLogLine(
          ownerLogFileUrl, logEntryRes[0] as String, logEntryRes[1] as String);

      // Add log entry if the recipient is either an individual or group of WebIDs
      if ([RecipientType.individual, RecipientType.group]
          .contains(recipientType)) {
        final receiverLogFileUrl =
            await getFileUrl(logFilePath, recipientWebId);
        await addPermLogLine(receiverLogFileUrl, logEntryRes[0] as String,
            logEntryRes[1] as String);
      }
    }
  }
}
