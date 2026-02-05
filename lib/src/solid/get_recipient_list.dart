/// Function that gets access list for each file in a list of files in a POD and returns the list of unique webIDs of authorized users, excluding the POD owner.
///
// Time-stamp: <Monday 2025-07-28 15:38:10 +1100 Jess Moore>
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

library;

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/get_resources.dart';
import 'package:solidpod/src/solid/read_permission_file_list.dart';

/// Retrieve the list of recipients that have access to any file
/// in the user's POD.

Future<List<String>> getRecipientList() async {
  // Initialise the resource list and data
  final List<String> fileList;
  final Map<String, dynamic> dataMapWithPermissions;

  try {
    // Get list of file urls
    fileList = await getResources();

    if (fileList.isNotEmpty) {
      // Retrieve ACLs for each file
      dataMapWithPermissions = await readPermissionFileList(
        fileList: fileList,
        isFileUrl: false,
      );

      // Extract recipient webIDs to list
      final uniqRecipWebIdList = extractRecipWebIdList(
        dataMapWithPermissions,
        fileList: fileList,
      );

      return uniqRecipWebIdList;
    } else {
      // No files found in user's POD, therefore no recipients
      // of the user's files.
      return [];
    }
  } on Object catch (e) {
    debugPrint(e.toString());
    rethrow;
  }
}

/// Extract the list of unique WebIds of recipients of the Pod user's
/// files from the [dataFilesMap] containing acccess control lists for
/// each file in the app data folder of the user's Pod.
/// Where the first webId, on the unique WebId list aggregated
/// across all their files, is assumed to be the user.
///
/// Parameters:
///   [dataFilesMap] is the map of file names and access data.
///   [fileList] is the list of files in the [dataFilesMap].
List<String> extractRecipWebIdList(
  Map<String, dynamic> dataFilesMap, {
  List<String>? fileList,
}) {
  // Initialise webID list
  final webIdList = <String>[];
  final List<String> uniqWebIdList;

  // If not supplied, extract fileList
  fileList ??= dataFilesMap.keys.toList();

  // Extract webIDs to list
  for (final fileName in fileList) {
    dataFilesMap[fileName][authUserPred].keys.forEach((key) {
      webIdList.add(key.toString());
    });
  }

  // Derive unique WebIds
  uniqWebIdList = webIdList.toSet().toList();
  // debugPrint('Unique webIDs: $uniqWebIdList');

  // Recipients = unique WebIds minus user
  // Assumes the first WebId is the user
  final uniqRecipWebIdList = uniqWebIdList;
  uniqRecipWebIdList.removeAt(0);

  // debugPrint('Unique webIDs (excl user): $uniqRecipWebIdList');

  return uniqRecipWebIdList;
}
