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
import 'package:solidpod/src/solid/constants/schema.dart' show appsTerms;
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show genRandIndividualKey;
import 'package:solidpod/src/solid/utils/key_manager.dart' show KeyManager;
import 'package:solidpod/src/solid/utils/misc.dart'
    show
        getDirUrl,
        extractResourcePathFromUrl,
        generateResourceUrlFromPath,
        generateWebIdFromResourceUrl;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart' show parseTTLMap;

/// Returns true if there is an individual key for a given resource
bool hasInheritedKey(String fileContent, String fileUrl) {
  final dataMap = parseTTLMap(fileContent);
  return dataMap.containsKey(fileUrl) &&
      dataMap[fileUrl].containsKey('$appsTerms$inheritKeyPred');
}

/// Set a key for a given directory so that key can be used to encrypt multiple
/// resources within the directory. Takes two input parameters
///   [dirPath] - unnormalised path for the directory
///   [createAcl] - Whther to crete an acl file for the directory or not (default: true)
/// Directory will be created if not exist
Future<void> setInheritKeyDir(
  String dirPath, {
  bool createAcl = true,
  PathType pathType = PathType.relativeToData,
}) async {
  final dirUrl = await generateResourceUrlFromPath(
    resourcePath: dirPath,
    pathType: pathType,
    isFile: false,
  );

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

  if (!await KeyManager.hasIndividualKey(dirUrl)) {
    // Create an individual AES key for the directory. This key will
    // be used to encrypt all the resources inside the directory

    final normalizedDirPath = await extractResourcePathFromUrl(
      dirUrl,
      isFile: false,
    );

    await KeyManager.addIndividualKey(
      normalizedDirPath,
      genRandIndividualKey(),
      isFile: false,
    );
  }
}

/// Retrieve the encryption key of a (shared) resource

Future<Key?> retrieveKey(
  String resourceUrl, {
  String? inheritKeyFrom,
}) async {
  final keyUrl = inheritKeyFrom == null
      ? resourceUrl
      : await getDirUrl(
          inheritKeyFrom,
        );

  if (await KeyManager.hasIndividualKey(keyUrl)) {
    return await KeyManager.getIndividualKey(keyUrl);
  }

  // shared resource

  final sharedKeyUrl = inheritKeyFrom == null
      ? resourceUrl
      : await getDirUrl(
          inheritKeyFrom,
          await generateWebIdFromResourceUrl(resourceUrl),
        );

  if (await KeyManager.hasSharedIndividualKey(sharedKeyUrl)) {
    return await KeyManager.getSharedIndividualKey(sharedKeyUrl);
  }

  return null;
}
