/// Function to write data to a private file in PODs.
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
/// Authors: Dawei Chen

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;

/// Write [fileName] to contain [fileContent] to PODs in the
/// data directory (within potential subdirectories encoded in [fileName]).
/// The content will be encrypted if [encrypted] is true.
///
/// The file will be written to the `appname/data` directory by default, unless
/// [basePath] is specified to override the default base path.
///
/// Examples:
/// - `writePod('abc.ttl', content, context, widget)` writes to `appname/data/abc.ttl`
/// - `writePod('movies/abc.ttl', content, context, widget)` writes to `appname/data/movies/abc.ttl`
/// - `writePod('appname/data/file.ttl', content, context, widget)` writes to `appname/data/file.ttl` (already correct path)
/// - `writePod('file.ttl', content, context, widget, basePath: 'appname/custom')` writes to `appname/custom/file.ttl`
///
/// [fileName] - The name of the file to write
/// [fileContent] - The content to write to the file
/// [context] - The BuildContext for UI interactions (e.g., security key prompts)
/// [child] - The child widget to return to after UI interactions
/// [encrypted] - Whether to encrypt the file content (default: true)
/// [createAcl] - Whether to create a separate acl for the resource (default: true)
/// [basePath] - Optional base path to override the default `appname/data` directory
/// [inheritKeyFrom] - Optional parameter to set a parent directory for the key to
///                   be inherited from. If set a single encryption key associated
///                   with the given directory is used to encrypt the resource.
///                   If this is set, then content will be encrypted regardless
///                   of encrypted flag is True or False.

Future<SolidFunctionCallStatus> writePod(
  String fileName,
  String fileContent,
  BuildContext context,
  Widget child, {
  bool encrypted = true,
  bool createAcl = true,
  String? basePath,
  String? inheritKeyFrom,
}) async {
  // Sanity check - ensure fileName doesn't end with path separators
  // The normalizeFilePath function will handle path separator normalization

  assert(!fileName.endsWith('/'));
  assert(!fileName.endsWith('\\'));

  if (!await checkLoggedIn()) {
    throw Exception(
      'User must be logged in to write to POD.',
    );
  }

  // If file key is inherited then check if parent directory exists. If not
  // create parent directory
  if (inheritKeyFrom != null) {
    String normalizedDirPath =
        await normalizeFilePath(inheritKeyFrom, basePath);
    // Following addition is to make sure that the path value added to the
    // ind-keys.ttl contains / so that can be recognised as a directory
    if (!normalizedDirPath.endsWith('/')) {
      normalizedDirPath += '/';
    }
    final parentDirUrl = await getDirUrl(normalizedDirPath);

    await getKeyFromUserIfRequired(context, child);

    switch (await checkResourceStatus(parentDirUrl, isFile: false)) {
      case ResourceStatus.notExist:
        debugPrint(
            'WARNING: Directory $inheritKeyFrom does not exist. Creating '
            'the directory and corresponding acl file, and setting up a new key '
            'for the directory');
        // Create directory and set a new key for the directory
        await setInheritKeyDir(inheritKeyFrom, basePath: basePath);
        break;
      case ResourceStatus.exist:
        if (!await KeyManager.hasIndividualKey(parentDirUrl)) {
          debugPrint(
              'WARNING: Directory $inheritKeyFrom does not have a key. Setting '
              'up a new key for the directory');
          // Generate a new key for the directory
          await setInheritKeyDir(
            inheritKeyFrom,
            basePath: basePath,
            createAcl: false,
          );
        }
        debugPrint(
          'Directory "$parentDirUrl" and key exists. Continuing the process...',
        );
        break;
      case ResourceStatus.unknown:
        throw Exception(
          'Unable to determine if directory "$parentDirUrl" exists, writePod() aborted',
        );
      case ResourceStatus.forbidden:
        throw Exception(
          'Access to directory "$parentDirUrl" is forbidden, writePod() aborted',
        );
    }
  }

  // Check if the file already exists
  // The file should exist if its individual key exists

  // Normalise the file path using the specified base path
  // or default to appname/data, and handle cross-platform path separators properly.

  final normalizedFilePath = await normalizeFilePath(fileName, basePath);
  final fileUrl = await getFileUrl(normalizedFilePath);
  final existingFileEncrypted = await KeyManager.hasIndividualKey(fileUrl);

  switch (await checkResourceStatus(fileUrl)) {
    case ResourceStatus.exist:

      // Ask user to confirm when the encryption status of the file is changed

      if (encrypted != existingFileEncrypted) {
        late bool overwrite;

        final overwriteMsg =
            '${existingFileEncrypted ? "Encrypted" : "Unencrypted"}'
            ' data file "$fileName" already exists,'
            ' do you want to overwrite it with '
            '${encrypted ? "encrypted" : "unencrypted"} content?';

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notice'),
            content: Text(overwriteMsg),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  overwrite = true;
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Overwrite',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  overwrite = false;
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (!overwrite) {
          throw Exception(
            'Not overwriting file "$normalizedFilePath", writePod() aborted',
          );
        } else {
          debugPrint('Overwrite file "$normalizedFilePath"');
        }
      }

    case ResourceStatus.unknown:
      throw Exception(
        'Unable to determine if file "$normalizedFilePath" exists, writePod() aborted',
      );

    case ResourceStatus.forbidden:
      throw Exception(
        'Access to file "$normalizedFilePath" is forbidden, writePod() aborted',
      );

    case ResourceStatus.notExist: // Empty case falls through.
      debugPrint('File "$normalizedFilePath" does not exist');
  }

  var content = fileContent;
  var contentType = ResourceContentType.turtleText;

  // If inheritKeyFrom is set, always encrypt the resource
  if (inheritKeyFrom != null) {
    final normalizedDirPath = await normalizeFilePath(inheritKeyFrom, basePath);
    final parentDirUrl = await getDirUrl(normalizedDirPath);
    content = await getEncTTLStr(
      normalizedFilePath,
      fileContent,
      await KeyManager.getIndividualKey(parentDirUrl),
      genRandIV(),
      inheritKeyFrom: normalizedDirPath,
    );
  } else {
    if (encrypted) {
      // Reuse the individual key if the key already exists,
      // otherwise, generate a random key and add it to the individual key file.

      if (!existingFileEncrypted) {
        await KeyManager.addIndividualKey(
          normalizedFilePath,
          genRandIndividualKey(),
        );
      }

      content = await getEncTTLStr(
        normalizedFilePath,
        fileContent,
        await KeyManager.getIndividualKey(fileUrl),
        genRandIV(),
      );
    } else {
      // Delete existing (encrypted) file if the new content is unencrypted

      if (existingFileEncrypted) {
        await deleteFile(normalizedFilePath);
      }

      // If the filename does not end with `.ttl', set content type to plain text

      if (!fileUrl.endsWith('.ttl')) {
        // .plainText may result in a filename ending with `$.txt'
        // .any may result in a filename ending with `$.unknown'
        contentType = ResourceContentType.auto;
      }
    }
  }

  if ((encrypted || inheritKeyFrom != null) && !fileUrl.endsWith('.ttl')) {
    debugPrint('WARNING: Encrypted text file should be in turtle format, '
        'but the extension of provided filename "$fileName" is not ".ttl"');
  }

  // Create file on server
  await createResource(fileUrl, content: content, contentType: contentType);

  // Create the ACL file for the data file if necessary

  final aclFileUrl = '$fileUrl.acl';
  if (await checkResourceStatus(aclFileUrl) == ResourceStatus.notExist &&
      createAcl) {
    await createResource(aclFileUrl, content: await genAclTurtle(fileUrl));
  }

  return SolidFunctionCallStatus.success;
}
