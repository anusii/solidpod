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

import 'package:flutter/services.dart' show PlatformException;

import 'package:intl/intl.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/pod_paths.dart' show normalizeFilePath;

export 'package:solidpod/src/solid/utils/enc_in_place.dart';
export 'package:solidpod/src/solid/utils/pod_paths.dart';
export 'package:solidpod/src/solid/utils/session.dart';

// solid-encrypt uses unencrypted local storage and refers to http: //yarrabah.net/ for predicates definition,
// do not use it before it is updated (same as what the gurriny project does)
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Write the given [key], [value] pair to the secure storage.
///
/// `flutter_secure_storage`'s `write()` does not overwrite an existing value,
/// so any existing entry must be removed first. We delete unconditionally
/// rather than gating on `containsKey()`.
///
/// On iOS/macOS the keychain's uniqueness constraint for a generic-password
/// item is account + service only — it does NOT include the accessibility
/// attribute. However `containsKey()` scopes its lookup by the currently
/// configured accessibility (`first_unlock_this_device`, see [secureStorage]).
/// A stale item left behind by an earlier build with a different accessibility
/// is therefore invisible to `containsKey()` yet still collides on the
/// underlying `SecItemAdd`, surfacing as a [PlatformException] with OSStatus
/// -25299 (`errSecDuplicateItem`, "The specified item already exists in the
/// keychain."). The plugin's `delete()` strips the accessibility constraint,
/// so calling it unconditionally clears any such orphan before we write.

Future<void> writeToSecureStorage(String key, String value) async {
  await secureStorage.delete(key: key);

  try {
    await secureStorage.write(key: key, value: value);
  } on PlatformException catch (e) {
    // Belt and braces: if a duplicate still slips through (e.g. a leftover
    // synchronizable variant), purge once more and retry the write.

    if (_isDuplicateKeychainItem(e)) {
      await secureStorage.delete(key: key);
      await secureStorage.write(key: key, value: value);
    } else {
      rethrow;
    }
  }
}

/// Whether [e] reports the iOS/macOS keychain "item already exists" error
/// (`errSecDuplicateItem`, OSStatus -25299).
///
/// The Darwin plugin reports it via a [PlatformException] whose `details`
/// carry the raw OSStatus and whose `message` echoes the numeric code, so we
/// check both rather than relying on the generic `code` string.

bool _isDuplicateKeychainItem(PlatformException e) =>
    e.details == -25299 || (e.message?.contains('-25299') ?? false);

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
/// [parentPath] is the relative path to the parent directory, interpreted
/// relative to the app's data directory (`appname/data`), the same convention
/// used by [writePod]. An empty string therefore refers to the data directory
/// itself, e.g. `createContainer('', 'shared')` creates `appname/data/shared/`.
/// A path that already begins with `appname/data` is used as-is, so callers
/// (such as the file browser) may pass fully-qualified data paths too.
///
/// [folderName] is the name of the new directory to create. It must not
/// contain spaces or URL/filesystem-unsafe characters (see
/// [validateContainerName]).
///
/// [createAcl] controls whether a dedicated `.acl` file is created for the
/// new folder (default: `true`). Without its own `.acl` file a container
/// merely inherits the effective ACL of its parent, which means the folder
/// — and resources placed within it — cannot be shared independently. We
/// therefore generate a default `.acl` (granting the owner full access) so
/// the folder is ready for sharing, mirroring how [setInheritKeyDir] and
/// [writePod] behave for key-inherited folders and files.
///
/// Throws [ArgumentError] if the name is invalid, or an [Exception] if
/// the directory already exists or a network error occurs.

Future<void> createContainer(
  String parentPath,
  String folderName, {
  bool createAcl = true,
}) async {
  // Validate the folder name before making any network calls.

  validateContainerName(folderName);

  // Combine parent path and folder name, then resolve the path relative to
  // the app data directory (idempotent for paths that already include it).
  // getDirUrl() resolves relative to the POD root, so without this the folder
  // would be created at the POD root instead of inside the data directory.

  final folderPath =
      parentPath.isEmpty ? folderName : '$parentPath/$folderName';
  final dirUrl = await getDirUrl(await normalizeFilePath(folderPath, null));
  await createDir(dirUrl);

  // Create the corresponding `.acl` file for the new container so that the
  // folder can be shared. The directory URL already ends with a trailing
  // slash, so `$dirUrl.acl` yields the conventional `<folder>/.acl` location.

  if (createAcl) {
    final aclFileUrl = '$dirUrl.acl';
    if (await checkResourceStatus(aclFileUrl, isFile: true) ==
        ResourceStatus.notExist) {
      await createResource(
        aclFileUrl,
        content: await genAclTurtle(dirUrl, isFile: false),
      );
    }
  }
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
