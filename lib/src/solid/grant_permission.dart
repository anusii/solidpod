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
import 'package:solidpod/src/solid/read_permission.dart'
    show getUserClassPermissions;
import 'package:solidpod/src/solid/revoke_permission.dart' show revokePermission;
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart' show RecipientPubKey;
import 'package:solidpod/src/solid/utils/key_manager.dart' show KeyManager;
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;

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
/// - [revokePublicAccessOnSpecificGrant] - When [recipientType] is
/// individual or group and the resource currently has a Public or
/// Authenticated User class grant (and is therefore plaintext on the
/// server, per the decryption step this function performs for those
/// recipient classes), revoke that grant and re-encrypt the resource
/// before proceeding. Without this, the resource would end up both still
/// readable by the previously-granted class *and* holding a stale
/// individual key that does not match the (still plaintext) content.
/// Defaults to `true`; set to `false` to keep today's behaviour where
/// granting to a specific recipient never touches an existing
/// public/authUser grant.

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
  bool revokePublicAccessOnSpecificGrant = true,
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

    // Ensure the resource has its own ACL file before attempting to share it.

    if (!isExternalRes &&
        !await resourceHasAcl(resourceUrl, isFile: isFile) &&
        await checkResourceStatus(resourceUrl, isFile: isFile) ==
            ResourceStatus.exist) {
      debugPrint(
        '[grantPermission] No ACL file found for "$resourceUrl"; '
        'creating a default ACL so the resource can be shared.',
      );
      await createResource(
        '$resourceUrl.acl',
        content: await genAclTurtle(
          resourceUrl,
          externalWebId: ownerWebId,
          isFile: isFile,
        ),
      );
    }

    // Initially check if the resource has a corresponding ACL file. If not
    // return an error.

    if (await resourceHasAcl(resourceUrl, isFile: isFile)) {
      // Check if file exists
      final resStatus = await checkResourceStatus(resourceUrl, isFile: isFile);

      // Check if recipient/s have initialised their pods with the correct
      // directory structure - required to access the shared resource
      bool allRecipientsInitialised = true;
      bool hasSpecificRecipients = false;
      if (specificRecipientTypeList.contains(recipientType)) {
        hasSpecificRecipients = true;
        for (final recipientWebId in recipientWebIdList) {
          final isInitialised = await checkPodInitialised(
            recipientWebId as String,
          );
          if (!isInitialised) {
            allRecipientsInitialised = false;
          }
        }
      }

      // Where recipient is specific recipient, only assign access
      // if recipient pods have been initialised
      if (allRecipientsInitialised || !hasSpecificRecipients) {
        if (resStatus == ResourceStatus.exist) {
          // Sharing to a specific individual/group assumes the resource is
          // ciphertext under an individual key (see the `fileHasIndKey`
          // branch below). If it's currently also granted to the Public or
          // Authenticated User class, it's plaintext on the server (that
          // class has no key of its own to decrypt with) — so revoke that
          // grant and re-encrypt first. Otherwise the resource would end up
          // both still openly readable *and* holding a stale individual key
          // that doesn't match the (still plaintext) bytes. Must run before
          // `setPermissionAcl` below, so `revokePermission`'s own ACL read
          // still sees the pre-existing grant.
          if (hasSpecificRecipients && revokePublicAccessOnSpecificGrant) {
            final existingClassPerms = await getUserClassPermissions(
              fileName: resourceUrl,
              isFile: isFile,
              isFileUrl: true,
              isExternalRes: isExternalRes,
            );
            for (final classType in existingClassPerms.keys) {
              final classAgent = classType == RecipientType.public
                  ? publicAgent
                  : authenticatedAgent;
              debugPrint(
                '[grantPermission] revoking existing $classType access on '
                '"$resourceUrl" before granting to $recipientType',
              );
              await revokePermission(
                fileName: resourceUrl,
                isFileUrl: true,
                permissionList: existingClassPerms[classType]!,
                recipientIndOrGroupWebId: classAgent.value,
                recipientType: classType,
                ownerWebId: ownerWebId,
                granterWebId: granterWebId,
                isFile: isFile,
                isExternalRes: isExternalRes,
              );
            }
          }

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

          // Whether the user originally chose to protect this resource
          // (i.e. an individual encryption key has been recorded for it).
          // This is the legacy "is encrypted" signal: it does not by
          // itself tell us whether the bytes currently on the server are
          // still encrypted — a file shared earlier with the Public or
          // Authenticated User class has its outer wrapper stripped by
          // [decryptFileInPlace] below.

          final fileHasIndKey = await checkFileEnc(
            resourceUrl,
            isExternalRes: isExternalRes,
          );
          debugPrint(
            '[grantPermission] resourceUrl="$resourceUrl" '
            'recipientType=$recipientType '
            'hasSpecificRecipients=$hasSpecificRecipients '
            'fileHasIndKey=$fileHasIndKey '
            'isExternalRes=$isExternalRes',
          );

          if (hasSpecificRecipients && fileHasIndKey) {
            // Permission granted to specific individuals or groups: share
            // the individual encryption key with each recipient via their
            // POD so they can decrypt the file content.

            final indKey = isExternalRes
                ? await KeyManager.getSharedIndividualKey(resourceUrl)
                : await KeyManager.getIndividualKey(resourceUrl);
            assert(indKey != null);

            for (final recipientWebId in recipientWebIdList) {
              // Setup recipient's public key
              final recipientPubKey = RecipientPubKey(
                recipientWebId: recipientWebId as String,
              );

              // Encrypt individual key
              final sharedIndKey = await recipientPubKey.encryptData(
                indKey!.base64,
              );

              // Encrypt resource URL
              final sharedResPath = await recipientPubKey.encryptData(
                resourceUrl,
              );

              // Encrypt the list of permissions
              permissionList.sort();
              final sharedAccessList = await recipientPubKey.encryptData(
                permissionList.join(','),
              );

              // Generate unique ID for the resource being shared
              final resUniqueId = getUniqueIdResUrl(
                resourceUrl,
                recipientWebId,
              );

              // Copy shared content to recipient's POD
              await copySharedKey(
                recipientWebId,
                resUniqueId,
                sharedIndKey,
                sharedResPath,
                sharedAccessList,
              );
            }
          } else if (!hasSpecificRecipients && isFile) {
            // Permission granted to the Public or Authenticated User class:
            // these recipients cannot be issued an individual key (they have
            // no POD/private key under our control), so the only way for
            // them to actually read the resource by navigating to its URL is
            // for the file itself to be plaintext on the server.
            //
            // This only applies to files: a directory (container) has no byte
            // content to decrypt, so the block is skipped for directories and
            // only its ACL is updated above.
            //
            // Inspect the actual bytes on the server, not just whether
            // an ind-key record exists — this stays robust against the
            // legacy case where the ind-key record was dropped while
            // the file content is still encrypted.
            //
            // The individual key is intentionally kept in `ind-keys.ttl`
            // so that the file can be re-encrypted later by
            // [encryptFileInPlace] if public/auth-user access is revoked.

            if (await isFileContentEncrypted(resourceUrl)) {
              debugPrint('[grantPermission] decrypting "$resourceUrl" for '
                  'public/authUser sharing');
              await decryptFileInPlace(
                resourceUrl,
                isExternalRes: isExternalRes,
              );
            } else {
              debugPrint('[grantPermission] outer layer already plaintext: '
                  '"$resourceUrl"');

              await applyPublicShareDecryptedHookInPlace(resourceUrl);
            }
          }

          // 20260112 jesscmoore: the permission logs should be updated
          // for granting access to public, auth users, and specific recipients.

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
            final ownerLogFileUrl = await getFileUrl(
              logFilePath,
              webId: ownerWebId,
            );

            // Granter
            final granterLogFileUrl = await getFileUrl(
              logFilePath,
              webId: granterWebId,
            );

            // Add log entry to owner, granter, and receiver permission
            // log files for the individual recipient or each recipient
            // in the recipient group.

            // Update granter log
            await addPermLogLine(
              logFileUrl: granterLogFileUrl,
              logEntry: logEntryRes,
            );

            // Upddate owner log (if owner != granter)
            if (ownerLogFileUrl != granterLogFileUrl) {
              await addPermLogLine(
                logFileUrl: ownerLogFileUrl,
                logEntry: logEntryRes,
              );
            }

            // Update recipient logs if the recipient is either an individual or group of WebIDs
            if (hasSpecificRecipients) {
              final receiverLogFileUrl = await getFileUrl(
                logFilePath,
                webId: recipientWebId,
              );

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
      debugPrint(
        'Resource does not have a corresponding ACL file. '
        'If the ACL is inherited provide parent directory as the resource name!',
      );
      return SolidFunctionCallStatus.noAclFound;
    }
  } on Object catch (e, stackTrace) {
    debugPrint('💥 [GrantPermission] Exception occurred: $e');
    debugPrint('📚 [GrantPermission] Stack trace: $stackTrace');
    return SolidFunctionCallStatus.fail;
  }
}
