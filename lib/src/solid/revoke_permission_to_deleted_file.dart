/// Function to revoke permission to a non existent file in a private file in a POD.
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
/// Authors: Jess Moore

library;

import 'dart:core';
import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/models/log_entry.dart';
import 'package:solidpod/src/solid/api/revoke_permission_api.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Revoke permissions to non-existent [fileName] (ie already deleted)
/// for a given individual Web ID [removerWebId].
/// Note: assumed for use case of user updating their own logs to
/// revoke their access to an external file that has already been
/// deleted without prior revoking of access to recipients. I.e. the
/// user and the remover are the same.
///
/// Parameters:
/// - [fileName] - is the name of the file revoking permission from.
/// - [isFileEncrypted] - flag denoting whether the file is encrypted.
/// - [permissionList] - is the list of permissions being revoked.
/// - [removerWebId] - is the Web ID of the individual for whom access is
/// being removed.
/// - [ownerWebId] - is the Web ID of file owner.
/// - [isFileUrl] - flag describing whether the [fileName] is the url
/// of the resource. (Default: false).

Future<SolidFunctionCallStatus> revokePermissionToDelFile({
  required String fileName,
  required bool isFileEncrypted,
  required List<dynamic> permissionList,
  required String removerWebId,
  required String ownerWebId,
  bool isFileUrl = false,
}) async {
  debugPrint(
    '[revokePermissionsToDelFile] revoking permissions for: $removerWebId to $fileName',
  );
  // Applies to external files only
  final isExternalRes = true;
  final isFile = true;

  // Get Url of file
  final resourceUrl = await filenameToResourceUrl(
    fileName: fileName,
    isFile: isFile,
    isFileUrl: isFileUrl,
    isExternalRes: isExternalRes,
  );

  // If the file is encrypted then remove the individual key from relavant
  // users/ user classes
  if (isFileEncrypted) {
    // Check if POD file structure is still there
    if (await checkPodInitialised(removerWebId)) {
      // Generate unique ID for the resource being shared
      final resUniqueId = getUniqueIdResUrl(resourceUrl, removerWebId);

      // Delete shared key content from recipient's POD
      await removeSharedKey(removerWebId, resUniqueId);
    }
  }

  // Add log entry to receiver permission log files

  // Get user webID
  final userWebId = await AuthDataManager.getWebId() as String;

  // Create log entry
  // final logEntryRes = createPermLogEntry(
  final LogEntry logEntryRes = createPermLogEntry(
    permissionList,
    resourceUrl,
    ownerWebId,
    'revoke',
    userWebId,
    removerWebId,
  );

  debugPrint('Log entry: ${logEntryRes.id}');
  debugPrint(logEntryRes.record);

  // Log file urls of the owner, granter, and receiver
  final logFilePath = await getPermLogFilePath();

  debugPrint('logFilePath: $logFilePath');

  // Add log entry to recipient's log
  if (await checkPodInitialised(removerWebId)) {
    final receiverLogFileUrl = await getFileUrl(logFilePath, removerWebId);
    await addPermLogLine(
      receiverLogFileUrl,
      // logEntryRes[0] as String,
      // logEntryRes[1] as String,
      logEntryRes.id,
      logEntryRes.record,
    );
  }

  return SolidFunctionCallStatus.success;
}
