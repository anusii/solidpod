/// Miscellaneous utility functions used across the package.
///
// Time-stamp: <Thursday 2026-01-22 11:12:44 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'package:intl/intl.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';

export 'package:solidpod/src/solid/utils/enc_in_place.dart';
export 'package:solidpod/src/solid/utils/pod_paths.dart';
export 'package:solidpod/src/solid/utils/session.dart';

// solid-encrypt uses unencrypted local storage and refers to http: //yarrabah.net/ for predicates definition,
// do not use it before it is updated (same as what the gurriny project does)
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Write the given [key], [value] pair to the secure storage.
///
/// If [key] already exisits then delete that first and then
/// write again.

Future<void> writeToSecureStorage(String key, String value) async {
  final isKeyExist = await secureStorage.containsKey(key: key);

  // Since write() method does not automatically overwrite an existing value.
  // To overwrite an existing value, call delete() first.

  if (isKeyExist) {
    await secureStorage.delete(key: key);
  }

  await secureStorage.write(key: key, value: value);
}

/// Create a directory with the given URL.

Future<void> createDir(String dirUrl) async {
  assert(dirUrl.endsWith('/'));
  await createResource(
    dirUrl,
    isFile: false,
    replaceIfExist: false,
    contentType: ResourceContentType.directory,
  );
}

/// Characters that are forbidden in container (folder) names.
///
/// These characters are either URL-unsafe (causing percent-encoding issues
/// such as spaces becoming `%20`) or filesystem-unsafe on common platforms.

final RegExp _invalidContainerNameChars = RegExp(
  r'''[ /#?%&+@=<>"|*:!\\]''',
);

/// Validates that [folderName] is a safe container name.
///
/// Throws [ArgumentError] if the name is empty, starts with a dot, or
/// contains characters that would be percent-encoded in a URL or are
/// otherwise unsafe for use as a directory name.

void validateContainerName(String folderName) {
  if (folderName.trim().isEmpty) {
    throw ArgumentError('Folder name cannot be empty.');
  }
  if (folderName.startsWith('.')) {
    throw ArgumentError('Folder name cannot start with a dot.');
  }
  final match = _invalidContainerNameChars.firstMatch(folderName);
  if (match != null) {
    final char = match.group(0);
    final label = char == ' ' ? 'spaces' : '"$char"';
    throw ArgumentError(
      'Folder name cannot contain $label. '
      'Avoid spaces and special characters: '
      r'/ \ # ? % & + @ = < > " | * : !',
    );
  }
}

/// Creates a new container (directory) on the POD from a relative path.
///
/// Combines [parentPath] and [folderName] into a relative path, resolves
/// the full directory URL via [getDirUrl], and creates the container.
///
/// [parentPath] is the normalised relative path to the parent directory
/// (e.g. `'myapp/data'` or `''` for the POD root).
///
/// [folderName] is the name of the new directory to create. It must not
/// contain spaces or URL/filesystem-unsafe characters (see
/// [validateContainerName]).
///
/// Throws [ArgumentError] if the name is invalid, or an [Exception] if
/// the directory already exists or a network error occurs.

Future<void> createContainer(String parentPath, String folderName) async {
  // Validate the folder name before making any network calls.

  validateContainerName(folderName);

  // Combine parent path and folder name, handling empty parent (POD root).

  final folderPath =
      parentPath.isEmpty ? folderName : '$parentPath/$folderName';
  final dirUrl = await getDirUrl(folderPath);
  await createDir(dirUrl);
}

/// Extract permission details of a file into a map.
/// Returns a map where keys are permission receiver webIds and
/// values are the list of permissions
Map<dynamic, dynamic> extractAclPerm(Map<dynamic, dynamic> aclFileContentMap) {
  final filePermMap = <dynamic, dynamic>{};
  for (final accessStr in aclFileContentMap.keys) {
    final permList = aclFileContentMap[accessStr][modePred];
    final receiverMap = {};

    if ((aclFileContentMap[accessStr] as Map).containsKey(agentPred)) {
      for (final receiverId
          in aclFileContentMap[accessStr][agentPred] as List) {
        receiverMap[receiverId] = agentPred;
      }
    }
    if ((aclFileContentMap[accessStr] as Map).containsKey(agentClassPred)) {
      for (final receiverId
          in aclFileContentMap[accessStr][agentClassPred] as List) {
        receiverMap[receiverId] = agentClassPred;
      }
    }
    if ((aclFileContentMap[accessStr] as Map).containsKey(agentGroupPred)) {
      for (final receiverId
          in aclFileContentMap[accessStr][agentGroupPred] as List) {
        receiverMap[receiverId] = agentGroupPred;
      }
    }

    for (final receiverId in receiverMap.keys) {
      if (filePermMap.containsKey(receiverId)) {
        filePermMap[receiverId][permStr] += permList;
        filePermMap[receiverId][agentStr] = receiverMap[receiverId];
      } else {
        filePermMap[receiverId] = {
          permStr: permList,
          agentStr: receiverMap[receiverId],
        };
      }
    }
  }

  return filePermMap;
}

/// Get resource name from URL
String getResNameFromUrl(String resourceUrl) {
  return resourceUrl.split('/').last;
}

/// Removes header and footer (which mess up the TTL format) from a PEM-formatted public key string.
///
/// This function takes a public key string, typically in PEM format, and removes
/// the standard PEM headers and footers.

String trimPubKeyStr(String keyStr) {
  final itemList = keyStr.split('\n');
  itemList.remove('-----BEGIN RSA PUBLIC KEY-----');
  itemList.remove('-----END RSA PUBLIC KEY-----');
  itemList.remove('-----BEGIN PUBLIC KEY-----');
  itemList.remove('-----END PUBLIC KEY-----');

  final keyStrTrimmed = itemList.join();

  return keyStrTrimmed;
}

/// Get date and time from a string
String getDateTime(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a');

  return dateFormat.format(dateTime);
}
