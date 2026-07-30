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
/// Authors: Anushka Vidanage, Dawei Chen

library;

import 'dart:convert';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/check_encryption.dart' show isContentEncrypted;
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_inheritance.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart' show KeyManager;
import 'package:solidpod/src/solid/utils/misc.dart';

/// Write file [fileUrl] with content [fileContent] to an external PODs in the
/// data directory (within potential subdirectories encoded in [fileUrl]).
///
/// [encrypted] defaults to `null`, meaning "not specified by the caller": when
/// overwriting an existing file, the file's *current* at-rest state on the
/// server is mirrored (plaintext stays plaintext, ciphertext stays
/// ciphertext) rather than always re-encrypting just because a shared
/// individual key happens to be on record. This matters for a resource the
/// owner decrypted in place for Public/Authenticated User sharing (see
/// `decryptFileInPlace` in solidpod) — without this, a recipient with write
/// access editing the file would silently re-encrypt it and break that
/// sharing grant. Pass `true`/`false` explicitly to force a specific
/// encryption state regardless of what's currently on the server.
///
/// The encryption boilerplate shared with [writePod] is factored out into
/// [getEncTTLStrWithRandomIV], and the "own POD vs external POD" routing is
/// shared via [isExternalOwner]. The remaining differences (how the encryption
/// key is resolved, the resource-status handling and the deliberate absence of
/// ACL creation) are intrinsic to writing into another user's shared POD and
/// are intentionally kept separate.

Future<void> writeExternalPod(
  String fileUrl,
  String fileContent,
  String fileOwnerWebId, {
  bool? encrypted,
  bool overwrite = true,
  String? inheritKeyFrom,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to write to external POD.',
    );
  }

  if (!overwrite) {
    debugPrint(
      'WARN: parameter "overwrite" is placeholder, its value is ignored by writeExternalPod()',
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
      final remoteFileContent = utf8.decode(await getResource(fileUrl));

      // When the caller didn't specify [encrypted], mirror whatever is
      // actually on the server right now instead of assuming a shared key
      // on record means the file should be (re-)encrypted — the owner may
      // have decrypted it in place for Public/Authenticated User sharing.
      final wantEncrypted = encrypted ??
          isContentEncrypted(fileUrl: fileUrl, content: remoteFileContent);

      final key = await KeyManager.getSharedIndividualKey(fileUrl);

      if (wantEncrypted && key != null) {
        // Get file path
        // final filePath =
        //     fileUrl.replaceAll(fileOwnerWebId.replaceAll(profCard, ''), '');

        content = await getEncTTLStrWithRandomIV(
          fileUrl: fileUrl,
          fileContent: fileContent,
          key: key,
        );

        if (!fileUrl.endsWith('.ttl')) {
          debugPrint(
            'WARN: Encrypted text file should be in turtle format, '
            'but the extension of provided filename "$fileUrl" is not ".ttl"',
          );
        }
      } else if (wantEncrypted && hasInheritedKey(remoteFileContent, fileUrl)) {
        // Get file path
        // final filePath =
        //     fileUrl.replaceAll(fileOwnerWebId.replaceAll(profCard, ''), '');

        // Get the individual key for the file
        final parentDirPath = getParentDir(remoteFileContent, fileUrl);
        final parentDirUrl = getExtDirUrl(fileUrl, parentDirPath);

        final key = await KeyManager.getSharedIndividualKey(parentDirUrl);
        assert(key != null);

        // Generate encrypted file content
        content = await getEncTTLStrWithRandomIV(
          fileUrl: fileUrl,
          fileContent: fileContent,
          key: key!,
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
      // debugPrint('File "$fileUrl" does not exist');

      // If the resource does not exist, if the encrypted flag is set to true,
      // and if inheritedFrom is set, then encrypt the file using the
      // inherited key
      if (inheritKeyFrom != null) {
        // Resolve the shared folder's URL on the external POD from the
        // destination [fileUrl]. Prefer the app-data-relative resolution
        // (which matches same-app cross-POD sharing); fall back to matching
        // the raw folder segment so this also works when the external POD's
        // application directory name differs from the current app's.

        final keyFolder = inheritKeyFrom.endsWith('/')
            ? inheritKeyFrom.substring(0, inheritKeyFrom.length - 1)
            : inheritKeyFrom;

        var parentDirUrl = getExtDirUrl(
          fileUrl,
          await normalizeFilePath(keyFolder, null),
        );
        if (parentDirUrl.isEmpty) {
          parentDirUrl = getExtDirUrl(fileUrl, keyFolder);
        }

        if (parentDirUrl.isEmpty) {
          throw Exception(
            'The "inherit encryption key" folder "$inheritKeyFrom" is not part '
            'of the destination path. It must name the shared folder the file '
            'is written into, e.g. "dir1/" for a destination ending in '
            '".../dir1/<file>".',
          );
        }

        final key = await KeyManager.getSharedIndividualKey(parentDirUrl);
        if (key == null) {
          throw Exception(
            'No shared encryption key was found for the folder "$parentDirUrl". '
            'Before uploading an encrypted file the POD owner must (1) create '
            'that folder with an inherited encryption key (e.g. via '
            'setInheritKeyDir / "Create Resource with ACL Inheritance") and '
            '(2) share the folder with your WebID, which also shares its key. '
            'To upload without encryption, leave the "inherit encryption key" '
            'field empty.',
          );
        }

        // Generate encrypted file content
        content = await getEncTTLStrWithRandomIV(
          fileUrl: fileUrl,
          fileContent: fileContent,
          key: key,
        );
      }

    /// av:23102025-TODO: Add functionality to support encryption of a new non
    /// inherited file. This is tricky as the key is not created for this file
  }

  // Create / update the file on the external POD.
  //
  // This is the only write performed here, so a 403 means the current WebID
  // simply does not have Write access to this specific resource. Surface an
  // actionable message instead of the generic "Failed to create resource".

  try {
    await createResource(fileUrl, content: content, contentType: contentType);
  } on Object catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('403') || msg.contains('forbidden')) {
      throw AccessForbiddenException(
        'Permission denied (HTTP 403) writing to "$fileUrl".\n'
        'Your WebID does not have Write access to this resource. Ask the '
        'owner to grant your WebID Write permission on this specific '
        'resource.\n'
        'Note: sharing only the parent folder does NOT grant write access to '
        'a file that already has its own ACL — the owner must share the file '
        'itself (or the file must inherit the folder ACL, i.e. have no ACL of '
        'its own).',
      );
    }
    rethrow;
  }

  // Do NOT create an ACL file for the resource on the external POD.
  //
  // Writing an `.acl` resource requires acl:Control on the target, which the
  // current user does not hold — they were only granted Read/Write/Append on
  // the shared parent directory. Attempting to PUT an `.acl` here would be
  // rejected with a 403 ForbiddenHttpError ("Failed to create resource").
  //
  // Moreover, even if it succeeded, generating a default (owner-only) ACL for
  // this individual file would override the parent directory's shared access
  // and could lock other recipients out. The resource therefore deliberately
  // inherits the ACL of the shared parent directory (its acl:default), which
  // the owner configured when sharing the directory.
}
