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

library;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/read_permission.dart';

/// Read permissions of each file in a list of files,
/// Note: the list of files are always files owned by the user.
///
/// Parameters:
/// - [fileList] - is the list of files in the user's Pod.
/// - [isFile] - flag describing whether the resource is a file, false if the resource is a directory. (Default: true).
/// - [isFilePath] - Flag describing whether the filenames provided as keys
/// in the dataMap provide the filename with the app data dir. (Default: false).
/// - [isFileUrl] - Flag describing whether filenames used as keys in dataMap
/// are the url of the file. (Default: false).

Future<Map<String, dynamic>> readPermissionFileList({
  required List<String> fileList,
  bool isFile = true,
  bool isFilePath = false,
  bool isFileUrl = false,
}) async {
  // Initialise data map to hold returned permission of each file
  Map<String, dynamic> dataMap = <String, dynamic>{};
  List<Future<dynamic>> futures = [];

  // Create a list of future functions
  for (final fileName in fileList) {
    futures.add(
      readPermission(
        fileName: fileName,
        isFile: isFile,
        isFileUrl: isFileUrl,
      ),
    );
  }

  // Wait for permission list futures synchronously
  List<dynamic> results = await Future.wait(futures);

  // Add returned permission lists to data map
  for (int i = 0; i < fileList.length; i++) {
    // Add fileName key
    dataMap[fileList[i]] = {};

    // Add permission list
    dataMap[fileList[i]][authUserPred] = results[i];
  }

  return dataMap;
}
