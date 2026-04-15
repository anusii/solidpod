/// Utility functions for generating folders and files at the initilisation stage.
///
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart'
    show
        getEncDirPath,
        getEncKeyPath,
        getIndKeyPath,
        getPubKeyPath,
        isUserLoggedIn,
        writeToSecureStorage;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart' show genPermLogTTLStr;

/// Key prefix for the POD initialisation flag in secure storage.

const String _podInitFlagPrefix = '_pod_init_done_';

/// Builds a unique storage key for the current user and app.

Future<String> _getPodInitFlagKey() async {
  final webId = await AuthDataManager.getWebId();
  if (webId == null || webId.isEmpty) {
    throw NotLoggedInException(
      'Cannot check initialisation flag without logging in',
    );
  }
  return '$_podInitFlagPrefix${appDirName}_$webId';
}

/// Returns `true` if the POD structure has already been initialised for the
/// current user and app, allowing subsequent logins to skip the full
/// folder/file existence check.

Future<bool> isPodStructureInitialised() async {
  try {
    final key = await _getPodInitFlagKey();
    final value = await secureStorage.read(key: key);
    return value == 'true';
  } on Object catch (e) {
    debugPrint('isPodStructureInitialised() check failed: $e');
    return false;
  }
}

/// Persists a flag indicating the POD structure has been successfully
/// initialised for the current user and app.

Future<void> markPodStructureInitialised() async {
  final key = await _getPodInitFlagKey();
  await writeToSecureStorage(key, 'true');
}

/// Clears the initialisation flag, forcing a full structure check on the
/// next login. Useful when the expected folder/file layout changes between
/// app versions.

Future<void> clearPodStructureInitialised() async {
  try {
    final key = await _getPodInitFlagKey();
    if (await secureStorage.containsKey(key: key)) {
      await secureStorage.delete(key: key);
    }
  } on Object catch (e) {
    debugPrint('clearPodStructureInitialised() failed: $e');
  }
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list
/// of strings. Each string in the list represents a path to a default folder
/// for the application.

Future<List<String>> generateDefaultFolders() async {
  final dataDirLoc = [appDirName, dataDir].join('/');
  final sharingDirLoc = [appDirName, sharingDir].join('/');
  final sharedDirLoc = [appDirName, sharedDir].join('/');
  final encDirLoc = [appDirName, encDir].join('/');
  final logDirLoc = [appDirName, logsDir].join('/');
  final profileDirLoc = [appDirName, profileDir].join('/');

  final folders = [
    appDirName,
    sharingDirLoc,
    sharedDirLoc,
    dataDirLoc,
    encDirLoc,
    logDirLoc,
    profileDirLoc,
  ];
  return folders;
}

/// Generates a list of custom folder paths for a given application.
///
/// This function takes the custom folder list given by the developer and
/// creates paths for those folders. Each custom folder will be created
/// inside the "data" folder. Following are few examples.
///   - Custom folder 'myDir1' will be created as '/data/myDir1'
///   - Custom folder 'myDir1/myDir3' will be created as '/data/myDir1/myDir3'
///   - Custom folder 'data' will be created as '/data/data'

List<String> generateCustomFolders(List customFolderPaths) {
  List<String> customFolderList = [];
  if (customFolderPaths.isNotEmpty) {
    for (String folderPath in customFolderPaths) {
      // Remove any leading '/' characters
      folderPath = folderPath.replaceFirst(RegExp(r'^/+'), '');
      customFolderList.add([appDirName, dataDir, folderPath].join('/'));
    }
  }
  return customFolderList;
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list
/// of strings. Each string in the list represents a path to a default folder
/// for the application.

Future<Map<dynamic, dynamic>> generateDefaultFiles() async {
  final sharingDirLoc = [appDirName, sharingDir].join('/');
  final sharedDirLoc = [appDirName, sharedDir].join('/');
  final encDirLoc = [appDirName, encDir].join('/');
  final logDirLoc = [appDirName, logsDir].join('/');
  final profileDirLoc = [appDirName, profileDir].join('/');

  final files = {
    sharingDirLoc: [pubKeyFile, '$pubKeyFile.acl'],
    logDirLoc: [permLogFile, '$permLogFile.acl'],
    sharedDirLoc: ['.acl'],
    encDirLoc: [encKeyFile, indKeyFile],
    profileDirLoc: ['.acl'],
  };
  return files;
}

/// Initialise the directory and file structure in a POD.

Future<void> initPod(
  String securityKey, {
  List<String>? dirUrls,
  List<String>? fileUrls,
}) async {
  // Check if the user has logged in.

  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('Can not initialise POD without logging in');
  }

  // Check (and generate) the directory URLs.

  if (dirUrls == null || dirUrls.isEmpty) {
    final defaultDirs = await generateDefaultFolders();
    dirUrls = [for (final d in defaultDirs) await getDirUrl(d)];
  }

  // Require the creation of the encryption directory and
  // the encKeyFile and indKeyFile in it.

  final encDirUrl = await getDirUrl(await getEncDirPath());
  if (!dirUrls.contains(encDirUrl)) {
    throw Exception('Can not initialise POD without creating $encDirUrl');
  }

  // Create the required directories.

  for (final d in dirUrls) {
    await createResource(
      d,
      isFile: false,
      contentType: ResourceContentType.directory,
    );
  }

  // Check (and generate) the file URLs.

  if (fileUrls == null || fileUrls.isEmpty) {
    final defaultFiles = await generateDefaultFiles();
    fileUrls = <String>[];
    for (final entry in defaultFiles.entries) {
      final d = entry.key;
      for (final f in entry.value as List) {
        fileUrls.add([d, f].join('/'));
      }
    }
  }

  // Create the encKeyFile, indKeyFile and pubKeyFile
  // and remove them from the fileUrls list.

  await KeyManager.initPodKeys(securityKey);
  fileUrls.remove(await getFileUrl(await getEncKeyPath()));
  fileUrls.remove(await getFileUrl(await getIndKeyPath()));
  fileUrls.remove(await getFileUrl(await getPubKeyPath()));

  for (final f in fileUrls) {
    final fileName = f.split('/').last;
    late String fileContent;
    late bool aclFlag;

    if (f.split('.').last == 'acl') {
      final items = f.split('.');
      final resourceUrl = items.getRange(0, items.length - 1).join('.');
      late Set<AccessMode> publicAccess;
      var isFile = true;
      switch (fileName) {
        case '$pubKeyFile.acl':
          publicAccess = {AccessMode.read};
        case '$permLogFile.acl':
          publicAccess = {AccessMode.append};
        default:
          assert(fileName == '.acl');
          isFile = false;

          // The shared directory ACL grants public read/write;
          // the profile directory ACL is owner-only (empty publicAccess).

          publicAccess = f.contains('/$sharedDir/')
              ? {AccessMode.read, AccessMode.write}
              : {};
      }

      fileContent = await genAclTurtle(
        resourceUrl,
        isFile: isFile,
        publicAccess: publicAccess,
      );

      aclFlag = true;
    } else {
      assert(fileName == permLogFile);
      fileContent = genPermLogTTLStr(f);
      aclFlag = false;
    }

    await createResource(f, content: fileContent, replaceIfExist: aclFlag);
  }

  await markPodStructureInitialised();
}
