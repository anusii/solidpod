/// Function to get access list for each file in a list of files in a POD.
///
// Time-stamp: <Sunday 2025-07-27 10:59:10 +1100 Jess Moore>
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
/// Authors: Jess Moore

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/chk_exists_and_has_acl.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';

/// Get the access control list data of each file in a map of files, ie.
/// webIDs and their access permission for each of the files in a map of
/// data files [dataMap].
/// Note: the list of files are always files owned by the user.
///
/// Parameters:
/// - [dataMap] - is map of resource data to which access lists are added.
/// - [context] - the build context.
/// - [child] - is the child widget to return to.
/// - [isFile] - flag describing whether the resource is a file, false if the resource is a directory. (Default: true).
/// - [isFilePath] - Flag describing whether the filenames provided as keys
/// in the dataMap provide the filename with the app data dir. (Default: false).
/// - [isFileUrl] - Flag describing whether filenames used as keys in dataMap
/// are the url of the file. (Default: false).
///   [fileList] Provide list of files in Pods if known.

Future<Map<String, dynamic>> getAccessLists(
  Map<String, dynamic> dataMap,
  BuildContext context,
  Widget child, {
  bool isFile = true,
  bool isFilePath = false,
  bool isFileUrl = false,
  List<String>? fileList,
}) async {
  fileList = fileList ?? dataMap.keys.toList();

  // Read recipients for each file
  for (final fileName in fileList) {
    // Check file exists and has an associated ACL file.
    final SolidFunctionCallStatus response = await chkExistsAndHasAcl(
      fileName: fileName,
      isFile: isFile,
      isFileUrl: isFileUrl,
      context: context,
      child: child,
    );

    if (response == SolidFunctionCallStatus.aclFound) {
      // Read permissions from the ACL.
      final dynamic permList = await readPermission(
        fileName: fileName,
        isFile: isFile,
        isFileUrl: isFileUrl,
      );

      // Add fileName key if missing
      if (!dataMap.containsKey(fileName)) {
        dataMap[fileName] = {};
      }

      // Add recipients map to dataMap
      dataMap[fileName][authUserPred] = permList;
      // debugPrint('adding permission map to dataMap for this file');
    } else {
      // Create empty map for each file if acl does not exist
      dataMap[fileName] = {};
      // debugPrint(
      //     'no acl found, adding empty permission map to dataMap for this file',);
    }
  }

  return dataMap;
}
