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

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/constants/common.dart'
    show agentStr, permStr;
import 'package:solidpod/src/solid/constants/web_acl.dart'
    show getRecipientType;
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/revoke_permission.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';

/// Revoke permissions from [fileName] for recipients of the file.
///
/// Parameters:
///
/// -[fileName] - is the name of the file that permissions are being
/// revoked from.
/// - [isExternalRes] - boolean describing whether the file is an
/// external file shared to the user. Where it is set to true, [fileName] should be the full URL of the file.
/// - [isFile] - is the flag to identify if the resources is a file or not.
/// - [context] - is the build context.
/// - [child] - is the child widget to return to.

Future<SolidFunctionCallStatus> revokePermissionToRecipients({
  required String fileName,
  bool isFile = true,
  required BuildContext context,
  required Widget child,
  bool isExternalRes = false,
}) async {
  if (!isExternalRes) {
    try {
      debugPrint('[revokePermissionsToRecipients] fileName: $fileName');

      final List<String> recipientWebIdList;

      // Get user webID
      final userWebId = await AuthDataManager.getWebId() as String;
      debugPrint('user webID: $userWebId');

      // Initialise webID list
      final webIdList = <String>[];

      // Obtain access permissions from resource ACL
      if (!context.mounted) return SolidFunctionCallStatus.fail;
      final dynamic permDataMap = await readPermission(
        fileName: fileName,
        isFile: isFile,
        isExternalRes: isExternalRes,
      );

      // Extract webIds of users with access
      permDataMap.keys.forEach((key) {
        webIdList.add(key.toString());
      });

      // Get recipients from webIds with access
      // to revoke permissions to all accessors excluding the
      // owner
      final List<String> uniqueWebIdList = webIdList.toSet().toList();
      recipientWebIdList = uniqueWebIdList;
      recipientWebIdList.removeWhere((element) => element == userWebId);
      // debugPrint('Unique webIDs: $uniqueWebIdList');

      if (recipientWebIdList.isNotEmpty) {
        debugPrint(
          'Recipients: ${recipientWebIdList.join(', ')}',
        );

        // Revoke permission for recipients
        if (!context.mounted) return SolidFunctionCallStatus.fail;
        for (final recipientWebId in recipientWebIdList) {
          debugPrint('Revoking permission for $recipientWebId...');
          await revokePermission(
            fileName: fileName,
            isFile: isFile,
            permissionList: permDataMap[recipientWebId][permStr] as List,
            removerWebId: recipientWebId,
            ownerWebId: userWebId,
            recipientType: getRecipientType(
              permDataMap[recipientWebId][agentStr] as String,
              recipientWebId,
            ),
            context: context,
            child: child,
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
