/// Function to write data to a private file in in an external POD shared by
/// another user.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;

/// Write file [fileUrl] with content [fileContent] to an external PODs in the
/// data directory (within potential subdirectories encoded in [fileUrl]).
/// The content will be encrypted if the original content is true.
///
/// av: 20250522 - Future work - extend this functionality to write new files
///                to external PODs with encrypted functionality.

Future<SolidFunctionCallStatus> writeExternalPod(
  String fileUrl,
  String fileContent,
  String fileOwnerWebId,
  BuildContext context,
  Widget child, {
  bool encrypted = true,
  String? inheritKeyFrom,
}) async {
  if (!await checkLoggedIn()) {
    throw Exception(
      'User must be logged in to write to external POD.',
    );
  }

  // Check if the file already exists
  // The file should exist if its individual key exists

  // final remoteFileEncrypted = await KeyManager.hasSharedIndividualKey(fileUrl);

  // Define file type
  var contentType = ResourceContentType.turtleText;

  // File content
  var content = fileContent;

  // Check if the file already exists
  switch (await checkResourceStatus(fileUrl)) {
    case ResourceStatus.exist:
      final remoteFileContent = await fetchPrvFile(fileUrl);
      if (await KeyManager.hasSharedIndividualKey(fileUrl)) {
        // Get the security key (and cache it in KeyManager)
        await getKeyFromUserIfRequired(context, child);

        // Get file path
        final filePath =
            fileUrl.replaceAll(fileOwnerWebId.replaceAll(profCard, ''), '');

        content = await getEncTTLStr(
          filePath,
          fileContent,
          await KeyManager.getSharedIndividualKey(fileUrl),
          genRandIV(),
          extWebId: fileOwnerWebId,
        );

        if (!fileUrl.endsWith('.ttl')) {
          debugPrint('WARN: Encrypted text file should be in turtle format, '
              'but the extension of provided filename "$fileUrl" is not ".ttl"');
        }
      } else if (hasInheritedKey(
        remoteFileContent,
        fileUrl,
      )) {
        // Get file path
        final filePath =
            fileUrl.replaceAll(fileOwnerWebId.replaceAll(profCard, ''), '');

        // Get the individual key for the file
        final parentDirPath = getParentDir(
          remoteFileContent,
          fileUrl,
        );
        final parentDirUrl = getExtDirUrl(fileUrl, parentDirPath);

        // Generate encrypted file content
        content = await getEncTTLStr(
          filePath,
          fileContent,
          await KeyManager.getSharedIndividualKey(parentDirUrl),
          genRandIV(),
          extWebId: fileOwnerWebId,
          inheritKeyFrom: parentDirPath,
        );
      } else {
        if (!fileUrl.endsWith('.ttl')) {
          // .plainText may result in a filename ending with `$.txt'
          // .any may result in a filename ending with `$.unknown'
          contentType = ResourceContentType.auto;
        }
      }
      break;

    case ResourceStatus.forbidden:
      throw Exception(
        'Access to file "$fileUrl" is forbidden, writePod() aborted',
      );

    case ResourceStatus.unknown:
      throw Exception(
        'Unable to determine if file "$fileUrl" exists, writePod() aborted',
      );

    case ResourceStatus.notExist: // Empty case falls through.
      debugPrint('File "$fileUrl" does not exist');

      // If the resource does not exist, if the encrypted flag is set to true,
      // and if inheritedFrom is set, then encrypt the file using the
      // inherited key
      if (inheritKeyFrom != null) {
        // Get normalised directory path
        String normalizedDirPath =
            await normalizeFilePath(inheritKeyFrom, null);

        final parentDirUrl = getExtDirUrl(fileUrl, normalizedDirPath);

        // Get file path
        final filePath =
            fileUrl.replaceAll(fileOwnerWebId.replaceAll(profCard, ''), '');

        // Generate encrypted file content
        content = await getEncTTLStr(
          filePath,
          fileContent,
          await KeyManager.getSharedIndividualKey(parentDirUrl),
          genRandIV(),
          extWebId: fileOwnerWebId,
        );
      }

    /// av:23102025-TODO: Add functionality to support encryption of a new non
    /// inherited file. This is tricky as the key is not created for this file
  }

  // Create file on server
  await createResource(fileUrl, content: content, contentType: contentType);

  // Create the ACL file for the data file if necessary
  // Check if file exsits AND if there is no inheritedFrom variable set. If this
  // is set then the ACL file will be inherited

  final aclFileUrl = '$fileUrl.acl';
  if (await checkResourceStatus(aclFileUrl) == ResourceStatus.notExist &&
      inheritKeyFrom == null) {
    await createResource(aclFileUrl, content: await genAclTurtle(fileUrl));
  }

  return SolidFunctionCallStatus.success;
}
