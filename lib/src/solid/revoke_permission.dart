/// Function to revoke permission from a private file in a POD.
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
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/api/revoke_permission_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart';

/// Revoke permissions from [fileName] for a given [removerWebId].
/// Parameters:
///   [fileName] is the name of the file revoking permission from. In case where
///   [isExternalRes] is set to true, [fileName] should be the full URL of the file
///   [isFile] is the flag to identify if the resources is a file or not
///   [removerWebId] is the Web ID of the person whose permission gets removed
///   [ownerWebId] is the Web ID of file owner
///   [recipientType] is the type of the recipient
///   [child] is the child widget to return to

Future<dynamic> revokePermission(
  String fileName,
  bool isFile,
  List<dynamic> permissionList,
  String removerWebId,
  String ownerWebId,
  RecipientType recipientType,
  BuildContext context,
  Widget child, {
  bool isExternalRes = false,
}) async {
  if (!await checkLoggedIn()) {
    throw Exception(
      'User must be logged in to revoke permissions.',
    );
  }

  await getKeyFromUserIfRequired(context, child);

  var resourceUrl = '';

  if (!isExternalRes) {
    // Get the file path
    final filePath = [await getDataDirPath(), fileName].join('/');

    // Get the url of the resource
    if (isFile) {
      resourceUrl = await getFileUrl(filePath);
    } else {
      resourceUrl = await getDirUrl(filePath);
    }
  } else {
    resourceUrl = fileName;
  }

  // print(resourceUrl);

  // Check if file/directory exists
  final resStatus = await checkResourceStatus(resourceUrl, isFile: isFile);

  if (resStatus == ResourceStatus.exist) {
    // Common list of remover IDs to process further
    final removerIdList = [];

    if (recipientType == RecipientType.group) {
      // Read the file that stores group of webIds
      // Get the file path
      final groupFilePath = [await getDataDirPath(), removerWebId].join('/');

      // Get the url of the file
      final groupFileUrl = await getFileUrl(groupFilePath);

      final groupWebIdList = await readGroupTtl(groupFileUrl);
      removerIdList.addAll(groupWebIdList);
    } else {
      removerIdList.add(removerWebId);
    }

    // Check if the file is encrypted
    final fileIsEncrypted =
        await checkFileEnc(resourceUrl, isExternalRes: isExternalRes);

    // If the file is encrypted then remove the individual key from relavant
    // users/ user classes
    if (fileIsEncrypted) {
      if ([RecipientType.individual, RecipientType.group]
          .contains(recipientType)) {
        for (final removerId in removerIdList) {
          // Check if POD file structure is still there
          if (await checkPodInitialised(removerId as String)) {
            // Generate unique ID for the resource being shared
            final resUniqueId = getUniqueIdResUrl(resourceUrl, removerId);

            // Delete shared key content from recipient's POD
            await removeSharedKey(removerId, resUniqueId);
          }
        }
      } else {
        // if the recipient type is either public or authenticated agent
        // Remove the key from the publicly available or authenticated user
        // accessible file
        await removeSharedKeyUserClass(resourceUrl, recipientType);
      }
    }

    final resourceName = resourceUrl.split('/').last;

    // Remove the permission line from the relevant ACL file
    await removePermissionAcl(
      resourceName,
      resourceUrl,
      ownerWebId,
      removerWebId,
      recipientType,
    );

    // Add log entry to owner, granter, and receiver permission log files
    // av20240703: At this instance the owner and the granter are the same
    //             At some point we might need to change this function so that
    //             it can be used in the instances where owner is different from
    //             the granter

    // Get user webID
    final userWebId = await AuthDataManager.getWebId() as String;

    for (final removerId in removerIdList) {
      final logEntryRes = createPermLogEntry(
        permissionList,
        resourceUrl,
        ownerWebId,
        'revoke',
        userWebId,
        removerId as String,
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
        if (await checkPodInitialised(removerId)) {
          final receiverLogFileUrl = await getFileUrl(logFilePath, removerId);
          await addPermLogLine(
            receiverLogFileUrl,
            logEntryRes[0] as String,
            logEntryRes[1] as String,
          );
        }
      }
    }
    return SolidFunctionCallStatus.success;
  } else {
    return SolidFunctionCallStatus.fail;
  }
}
