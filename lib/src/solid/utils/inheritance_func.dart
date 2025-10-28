/// Utility functions related to resource inheritance.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// A class to represent inheritance compatibility of a directory
enum InheritanceCompatibility {
  /// Incompatible
  incompatible('incompatible'),

  /// Compatible but a key has not been assiged
  compatibleWithoutKey('compatible without key'),

  /// Compatible with a key
  compatibleWithKey('compatible with key');

  /// Generative enum constructor
  const InheritanceCompatibility(this._value);

  /// String label of data type
  final String _value;

  /// Return the string value of data type
  String get label => _value;
}

/// Split given path into multiple sub-paths (segments)
List<String> buildPathSegments(String path) {
  List<String> parts = path.split('/');

  // remove the last item from the list as it is the file name
  parts.remove(parts.last);

  List<String> result = [];
  String current = '';

  for (var part in parts) {
    if (current.isEmpty) {
      current = part;
    } else {
      current = '$current/$part';
    }
    result.add('$current/');
  }

  result.removeRange(0, 2);

  return result;
}

// Check if a parent directory is there in a given list [dirPathList] of paths
// If a path is similar to the parent directory path given by the user
// ignore it
Future<bool> includeParentDir(
  List dirPathList,
  String userParentDirPath,
) async {
  bool hasOtherParentDir = false;

  for (final subPath in dirPathList) {
    //
    if (userParentDirPath == subPath) {
      continue;
    }
    final subPathUrl = await getDirUrl(subPath);

    if (await KeyManager.hasIndividualKey(subPathUrl)) {
      hasOtherParentDir = true;
      break;
    }
  }
  return hasOtherParentDir;
}

// Check the compatibility of a given directory to be a parent directory
// and have inherited resources
// Checked accoding to the following logic
//  - If the given parent directory already has an individual key, it is
//    compatible
//  - If the given parent directory is empty, it is compatible
//  - If the given parent directory has resources check any file is pointing to
//    a parent directory that is above (level up) the given parent directory. If
//    there are any such files, incompatible
//
Future<InheritanceCompatibility> ihtCompatibility(String parentDirUrl) async {
  // Recursive function to check resources in a container
  Future<InheritanceCompatibility> checkResInContainer(
    String containerUrl,
  ) async {
    final res = await getResourcesInContainer(containerUrl);
    final folderList = res.subDirs;
    final fileList = res.files;

    print(fileList);
    print(folderList);

    if (folderList.isNotEmpty) {
      for (final dirName in folderList) {
        final dirAclUrl = '$containerUrl/$dirName/.acl';
        if (await checkResourceStatus(dirAclUrl) == ResourceStatus.notExist) {
          return await checkResInContainer('$containerUrl/$dirName/');
        }
      }
      if (fileList.isNotEmpty) {
        bool allFilesHaveAcl = true;
        for (final fileName in fileList) {
          final fileAclUrl = '$containerUrl/$fileName';
          if (await checkResourceStatus(fileAclUrl) ==
              ResourceStatus.notExist) {
            allFilesHaveAcl = false;
            break;
          }
        }
        if (allFilesHaveAcl) {
          return InheritanceCompatibility.compatibleWithoutKey;
        } else {
          return InheritanceCompatibility.incompatible;
        }
      } else {
        return InheritanceCompatibility.compatibleWithoutKey;
      }
    } else {
      if (fileList.isNotEmpty) {
        bool allFilesHaveAcl = true;
        for (final fileName in fileList) {
          final fileAclUrl = '$containerUrl/$fileName.acl';
          if (await checkResourceStatus(fileAclUrl) ==
              ResourceStatus.notExist) {
            allFilesHaveAcl = false;
            break;
          }
        }
        if (allFilesHaveAcl) {
          return InheritanceCompatibility.compatibleWithoutKey;
        } else {
          return InheritanceCompatibility.incompatible;
        }
      } else {
        return InheritanceCompatibility.compatibleWithoutKey;
      }
    }
  }

  if (await KeyManager.hasIndividualKey(parentDirUrl)) {
    return InheritanceCompatibility.compatibleWithKey;
  } else {
    return await checkResInContainer(parentDirUrl);
  }
}
