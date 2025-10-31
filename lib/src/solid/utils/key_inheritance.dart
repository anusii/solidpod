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
/// Authors: Anushka Vidanage

library;

import 'package:solidpod/src/solid/api/rest_api.dart'
    show checkResourceStatus, createResource;
import 'package:solidpod/src/solid/constants/common.dart'
    show inheritKeyPred, ResourceContentType, ResourceStatus;
import 'package:solidpod/src/solid/constants/schema.dart' show appsTerms;
import 'package:solidpod/src/solid/utils/key_manager.dart' show KeyManager;
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show genRandIndividualKey;
import 'package:solidpod/src/solid/utils/misc.dart'
    show getDirUrl, normalizeFilePath;
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
  String? basePath,
}) async {
  final normalizedDirPath = await normalizeFilePath(dirPath, basePath);
  final dirUrl = await getDirUrl(normalizedDirPath);

  if (await checkResourceStatus(dirUrl, isFile: false) ==
      ResourceStatus.notExist) {
    // Create the directory
    await createResource(
      dirUrl,
      isFile: false,
      contentType: ResourceContentType.directory,
    );
  }

  if (createAcl) {
    // Create the corresponding acl file
    await createResource(
      '$dirUrl.acl',
      content: await genAclTurtle(dirUrl, isFile: false),
    );
  }

  if (!await KeyManager.hasIndividualKey(dirUrl)) {
    // Create an individual AES key for the directory. This key will
    // be used to encrypt all the resources inside the directory
    await KeyManager.addIndividualKey(
      normalizedDirPath,
      genRandIndividualKey(),
      isFile: false,
    );
  }
}
