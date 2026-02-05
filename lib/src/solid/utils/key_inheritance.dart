/// Utilities for encryption key inheritance
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Anushka Vidanage, Dawei Chen

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart' show Key;

import 'package:solidpod/src/solid/api/rest_api.dart'
    show checkResourceStatus, createResource;
import 'package:solidpod/src/solid/constants/common.dart'
    show inheritKeyPred, ResourceContentType, ResourceStatus;
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show genRandIndividualKey, getPredicateUrl;
import 'package:solidpod/src/solid/utils/key_manager.dart' show KeyManager;
import 'package:solidpod/src/solid/utils/misc.dart'
    show extractResourcePathFromUrl;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart' show turtleToTripleMap;

/// Returns true if there is an individual key for a given resource
bool hasInheritedKey(String fileContent, String fileUrl) {
  final map = turtleToTripleMap(fileContent);
  return map.containsKey(fileUrl) &&
      map[fileUrl]!.containsKey(getPredicateUrl(inheritKeyPred));
}

/// Set a key for a given directory so that key can be used to encrypt multiple
/// resources within the directory. Takes two input parameters
///   [dirUrl] - URL of the directory
///   [createAcl] - Whther to crete an acl file for the directory or not (default: true)
/// Directory will be created if not exist
Future<void> setInheritKeyDir(String dirUrl, {bool createAcl = true}) async {
  if (await checkResourceStatus(dirUrl, isFile: false) ==
      ResourceStatus.notExist) {
    // Create the directory
    // dc 20251105: TBC - Will all nonexist intermediate folders be created by CSS server?
    await createResource(
      dirUrl,
      isFile: false,
      contentType: ResourceContentType.directory,
    );
  }

  if (createAcl) {
    // Create the corresponding acl file if not exists

    final aclUrl = '$dirUrl.acl';
    if (await checkResourceStatus(aclUrl, isFile: true) ==
        ResourceStatus.notExist) {
      await createResource(
        aclUrl,
        content: await genAclTurtle(dirUrl, isFile: false),
      );
    } else {
      debugPrint('[setInheritKeyDir] $aclUrl already exists, do nothing.');
    }
  }

  if (await KeyManager.getIndividualKey(dirUrl) == null) {
    // Create an individual AES key for the directory. This key will
    // be used to encrypt all the resources inside the directory

    final normalizedDirPath = await extractResourcePathFromUrl(
      dirUrl,
      isFile: false,
    );

    await KeyManager.addIndividualKey(
      resourcePath: normalizedDirPath,
      indKey: genRandIndividualKey(),
      isFile: false,
    );
  }
}

/// Retrieve the encryption key of a (shared) resource

Future<Key?> retrieveEncKey(String resourceUrl, {String? inheritKeyUrl}) async {
  final keyUrl = inheritKeyUrl ?? resourceUrl;
  final key = await KeyManager.getIndividualKey(keyUrl);

  if (key == null) {
    return await KeyManager.getSharedIndividualKey(keyUrl);
  }

  return key;
}

/// Configure / set-up the encryption key for a file with URL [fileUrl].
/// If the encryption key is inherited (as specified by [inheritKeyUrl])
/// then check whether the corresponding directory exists, and create it
/// if not.

Future<Key> configureEncKey(String fileUrl, {String? inheritKeyUrl}) async {
  if (inheritKeyUrl == null) {
    if (await KeyManager.getIndividualKey(fileUrl) == null) {
      await KeyManager.addIndividualKey(
        resourcePath: await extractResourcePathFromUrl(fileUrl),
        indKey: genRandIndividualKey(),
      );
    }
    final key = await KeyManager.getIndividualKey(fileUrl);
    assert(key != null);
    return key!;
  }

  switch (await checkResourceStatus(inheritKeyUrl, isFile: false)) {
    case ResourceStatus.notExist:
      debugPrint(
        'WARNING: Directory $inheritKeyUrl does not exist. '
        'Creating the directory and corresponding acl file, '
        'and setting up a new key for the directory',
      );
      // Create directory and set a new key for the directory
      await setInheritKeyDir(inheritKeyUrl);

    case ResourceStatus.exist:
      if (await KeyManager.getIndividualKey(inheritKeyUrl) == null) {
        debugPrint(
          'WARNING: Directory $inheritKeyUrl does not have a key. '
          'Setting up a new key for the directory',
        );
        // Generate a new key for the directory
        await setInheritKeyDir(inheritKeyUrl, createAcl: false);
      }
      debugPrint(
        'Directory "$inheritKeyUrl" and key exists. Continuing the process...',
      );

    case ResourceStatus.unknown:
      throw Exception(
        'Unable to determine if directory "$inheritKeyUrl" exists, writePod() aborted',
      );
    case ResourceStatus.forbidden:
      throw AccessForbiddenException(
        'Access to directory "$inheritKeyUrl" is forbidden, writePod() aborted',
      );
  }

  final key = await KeyManager.getIndividualKey(inheritKeyUrl);
  assert(key != null);
  return key!;
}

/// Check if the provided [inheritKeyFrom] is consistent with the [pathType]

bool validateInheritKeyPath(
  String inheritKeyFrom, {
  required PathType pathType,
}) {
  // Currently validates if it is a URL

  try {
    if (inheritKeyFrom.trim().isEmpty) {
      throw Exception('inheritKeyFrom is empty');
    }

    if (pathType == PathType.absoluteUrl) {
      final uri = Uri.parse(inheritKeyFrom);
      if (uri.host.trim().isEmpty) {
        throw Exception('inheritKeyFrom="$inheritKeyFrom" is not a valid URL');
      }
    }
  } on Object catch (e) {
    debugPrint(e.toString());
    return false;
  }

  return true;
}
