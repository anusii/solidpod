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
/// Authors: Anushka Vidanage, Jess Moore

library;

import 'dart:core';

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/api/revoke_permission_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/models/log_entry.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart';

/// Revoke permissions to [fileName] for a given individual or
/// group Web ID [removerIndOrGroupWebId].
///
/// Parameters:
/// - [fileName] - is the name of the file revoking permission from.
/// - [permissionList] - is the list of permissions being revoked.
/// - [removerIndOrGroupWebId] - is the Web ID of the individual or
/// group for whom access is being removed.
/// - [ownerWebId] - is the Web ID of file owner.
/// - [recipientType] - is the type of the recipient.
/// - [isFile] - flag describing whether the resources is a file or not.
/// (Default: true).
/// - [isFileUrl] - flag describing whether the [fileName] is the url
/// of the resource. (Default: false).
/// - [isExternalRes] - flag describing whether resource is an external
/// file shared to the user. Where set to true, the [fileName] should be
/// the full URL of the file. (Default: false).

Future<SolidFunctionCallStatus> revokePermission({
  required String fileName,
  required List<dynamic> permissionList,
  required String removerIndOrGroupWebId,
  required String ownerWebId,
  required RecipientType recipientType,
  bool isFile = true,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  // debugPrint('[revokePermissions] revoking permissions for: $removerIndOrGroupWebId');

  final resourceUrl = await filenameToResourceUrl(
    fileName: fileName,
    isFile: isFile,
    isFileUrl: isFileUrl,
    isExternalRes: isExternalRes,
  );

  // Check if file/directory exists
  final resStatus = await checkResourceStatus(resourceUrl, isFile: isFile);

  if (resStatus == ResourceStatus.exist) {
    // Extract the list of remover WebIds for whom access is being
    // removed
    final removerWebIdList = [];

    if (recipientType == RecipientType.group) {
      // Read the file that stores group of webIds
      // Get the file path
      final groupFilePath =
          [await getDataDirPath(), removerIndOrGroupWebId].join('/');

      // Get the url of the file
      final groupFileUrl = await getFileUrl(groupFilePath);

      final groupWebIdList = await readGroupTtl(groupFileUrl);
      removerWebIdList.addAll(groupWebIdList);
    } else {
      removerWebIdList.add(removerIndOrGroupWebId);
    }

    // Check if the file is encrypted
    final fileIsEncrypted =
        await checkFileEnc(resourceUrl, isExternalRes: isExternalRes);

    // If the file is encrypted then remove the individual key from relavant
    // users/ user classes
    if (fileIsEncrypted) {
      if ([RecipientType.individual, RecipientType.group]
          .contains(recipientType)) {
        for (final removerWebId in removerWebIdList) {
          // Check if POD file structure is still there
          if (await checkPodInitialised(removerWebId as String)) {
            // Generate unique ID for the resource being shared
            final resUniqueId = getUniqueIdResUrl(resourceUrl, removerWebId);

            // Delete shared key content from recipient's POD
            await removeSharedKey(removerWebId, resUniqueId);
          }
        }
      } else {
        // if the recipient type is either public or authenticated agent
        // Remove the key from the publicly available or authenticated user
        // accessible file
        await removeSharedKeyUserClass(resourceUrl, recipientType);
      }
    }

    // Remove the permission line from the relevant ACL file
    await removePermissionAcl(
      resourceUrl: resourceUrl,
      ownerWebId: ownerWebId,
      removerId: removerIndOrGroupWebId,
      recipientType: recipientType,
      isFile: isFile,
    );

    // Add log entry to owner, granter, and receiver permission log files
    // av20240703: At this instance the owner and the granter are the same
    //             At some point we might need to change this function so that
    //             it can be used in the instances where owner is different from
    //             the granter

    // Get user webID
    final userWebId = await AuthDataManager.getWebId() as String;

    for (final removerWebId in removerWebIdList) {
      final LogEntry logEntryRes = createPermLogEntry(
        permissionList: permissionList,
        resourceUrl: resourceUrl,
        ownerWebId: ownerWebId,
        permissionType: 'revoke',
        granterWebId: userWebId,
        recipientWebId: removerWebId as String,
      );

      // Log file urls of the owner, granter, and receiver
      final logFilePath = await getPermLogFilePath();

      // Owner
      // [20251029 jesscmoore] Assumes user = owner and uses
      // AuthDataManager.getWebId() to fetch user webId
      final ownerLogFileUrl = await getFileUrl(logFilePath, webId: ownerWebId);

      // Granter
      // [20251029 jesscmoore] Assumes user = granter and uses
      // AuthDataManager.getWebId() to fetch user webId
      final granterLogFileUrl = await getFileUrl(logFilePath);

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
      if ([RecipientType.individual, RecipientType.group]
          .contains(recipientType)) {
        if (await checkPodInitialised(removerWebId)) {
          final receiverLogFileUrl =
              await getFileUrl(logFilePath, webId: removerWebId);
          await addPermLogLine(
            logFileUrl: receiverLogFileUrl,
            logEntry: logEntryRes,
          );
        }
      }
    }
    return SolidFunctionCallStatus.success;
  } else {
    return SolidFunctionCallStatus.fail;
  }
}
