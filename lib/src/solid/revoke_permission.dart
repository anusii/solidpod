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
/// group Web ID [recipientIndOrGroupWebId] by removing the
/// permission in the ACL within the owner's POD and adding a
/// log entry recording the revoked permission in the permission
/// logs of the owner, granter and recipient.
///
/// Parameters:
/// - [fileName] - is the name of the file revoking permission from.
/// - [permissionList] - is the list of permissions being revoked.
/// - [recipientIndOrGroupWebId] - is the Web ID of the individual or
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
  required String recipientIndOrGroupWebId,
  required String ownerWebId,
  required RecipientType recipientType,
  bool isFile = true,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  // debugPrint('[revokePermissions] revoking permissions for: $recipientIndOrGroupWebId');

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
    final recipientWebIdList = [];

    if (recipientType == RecipientType.group) {
      // Read the file that stores group of webIds
      // Get the file path
      final groupFilePath =
          [await getDataDirPath(), recipientIndOrGroupWebId].join('/');

      // Get the url of the file
      final groupFileUrl = await getFileUrl(groupFilePath);

      final groupWebIdList = await readGroupTtl(groupFileUrl);
      recipientWebIdList.addAll(groupWebIdList);
    } else {
      recipientWebIdList.add(recipientIndOrGroupWebId);
    }

    // Check if the file is encrypted
    final fileIsEncrypted =
        await checkFileEnc(resourceUrl, isExternalRes: isExternalRes);

    // If the file is encrypted then remove the individual key from relavant
    // users/ user classes
    if (fileIsEncrypted) {
      if ([RecipientType.individual, RecipientType.group]
          .contains(recipientType)) {
        for (final recipientWebId in recipientWebIdList) {
          // Check if POD file structure is still there
          if (await checkPodInitialised(recipientWebId as String)) {
            // Generate unique ID for the resource being shared
            final resUniqueId = getUniqueIdResUrl(resourceUrl, recipientWebId);

            // Delete shared key content from recipient's POD
            await removeSharedKey(recipientWebId, resUniqueId);
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
      recipientWebId: recipientIndOrGroupWebId,
      recipientType: recipientType,
      isFile: isFile,
    );

    // Add log entry to owner, granter, and receiver permission log files

    // Get user webID
    // final userWebId = await AuthDataManager.getWebId() as String;

    for (final recipientWebId in recipientWebIdList) {
      final LogEntry logEntryRes = createPermLogEntry(
        permissionList: permissionList,
        resourceUrl: resourceUrl,
        ownerWebId: ownerWebId,
        permissionType: 'revoke',
        // User is revoking the permission
        // Get userWebId
        // FIXME 20260112 jesscmoore: This does not address the scenario where user is recipient revoking access to an already deleted file.
        granterWebId: await AuthDataManager.getWebId() as String, // userWebId,
        recipientWebId: recipientWebId as String,
      );

      // Log file urls of the owner, granter, and receiver
      final logFilePath = await getPermLogFilePath();

      // Scenario 1
      // PersonA = owner has granted access to PersonB
      // PersonA then revokes access to PersonB
      // PersonA = owner = granter = user

      // Scenario 2
      // PersonA = recipient with control and has granted
      // access to Person B.
      // PersonA then revokes access to PersonB.
      // PersonA = granter = user != owner

      // Scenario 3
      // PersonA = owner is deleting own file and revoking access
      // before delete.
      // PersonA = owner = granter = user

      // Scenario 4
      // PersonA = recipient with control who is deleting external
      // file and revoking access before delete.
      // PersonA = granter = user != owner

      // Scenario 5
      // PersonA = recipient who is revoking access to already
      // deleted file.
      // PersonA = user != granter && user != owner

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
        if (await checkPodInitialised(recipientWebId)) {
          final receiverLogFileUrl =
              await getFileUrl(logFilePath, webId: recipientWebId);
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
