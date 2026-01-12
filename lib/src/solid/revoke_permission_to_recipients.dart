/// Function to revoke permission of recipients to a file in a POD.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/constants/common.dart'
    show agentStr, permStr;
import 'package:solidpod/src/solid/constants/web_acl.dart'
    show getRecipientType;
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/revoke_permission.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';

/// Adds a log entry to the permission log of each recipient
/// of [fileName] that revokes their access to the file
/// and removes the permission entry from the associated
/// ACL file. Assumes userWebId == ownerWebId, which is true
/// when this function is called by deleteFile().
///
/// Parameters:
///
/// -[fileName] - is the name of the file that permissions are being
/// revoked from.
/// - [isFile] - flag describing whether the resources is a file or not.
/// (Default: true).
/// - [isFileUrl] - flag describing whether the resource [fileName] is the
/// resource url. (Default: false).
/// - [isExternalRes] - boolean describing whether the file is an
/// external file shared to the user. Where it is set to true, [fileName] should be the full URL of the file. (Default: false).

Future<SolidFunctionCallStatus> revokePermissionToRecipients({
  required String fileName,
  bool isFile = true,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  if (!isExternalRes) {
    try {
      final List<String> recipientWebIdList;

      // For user owned files, user = granter = owner
      final userWebId = await AuthDataManager.getWebId() as String;
      final ownerWebId = userWebId;
      final granterWebId = userWebId;

      // Initialise webID list
      final webIdList = <String>[];

      // Obtain access permissions from resource ACL
      // to get list of users with access to resoucre
      final dynamic permDataMap = await readPermission(
        fileName: fileName,
        isFile: isFile,
        isFileUrl: isFileUrl,
        isExternalRes: isExternalRes,
      );

      // Extract webIds of recipients with access
      // where recipients are keys to the permission records
      permDataMap.keys.forEach((key) {
        webIdList.add(key.toString());
      });

      // Get list of recipients from webIds with access in the
      // ACL, in order to revoke permissions to users with access
      // excluding the owner
      final List<String> uniqueWebIdList = webIdList.toSet().toList();
      recipientWebIdList = uniqueWebIdList;
      recipientWebIdList.removeWhere((element) => element == ownerWebId);

      if (recipientWebIdList.isNotEmpty) {
        // Revoke permission for each recipient
        for (final recipientWebId in recipientWebIdList) {
          debugPrint('Revoking permission for $recipientWebId...');

          await revokePermission(
            fileName: fileName,
            isFile: isFile,
            isFileUrl: isFileUrl,
            permissionList: permDataMap[recipientWebId][permStr] as List,
            recipientIndOrGroupWebId: recipientWebId,
            ownerWebId: ownerWebId,
            granterWebId: granterWebId,
            recipientType: getRecipientType(
              permDataMap[recipientWebId][agentStr] as String,
              recipientWebId,
            ),
            isExternalRes: isExternalRes,
          );
        }

        debugPrint(
          'Permission revoked for ${recipientWebIdList.length} recipients',
        );
      } else {
        debugPrint('No other users have access to this file.');
        debugPrint(
          'No permission revoked, as no other users have access to this file.',
        );
      }

      return SolidFunctionCallStatus.success;
    } catch (e) {
      // Error revoking permissions to recipients
      debugPrint('Error revoking permissions to recipients of user\' note: $e');
      rethrow;
    }
  } else {
    // For now, do not allow revoking permissions of external resource where user is not owner.
    // Fail if external resource
    return SolidFunctionCallStatus.fail;
  }
}
