/// Function to get POD resources by reading each private file in PODs.
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
/// Authors: Jess Moore, Anushka Vidanage, Graham Williams

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Get the list of files created by the user in their POD by querying the data directory of the POD.
///
/// We first check if the user is logged in and get the list of resources in the container.
///
/// Examples:
/// - `getResources('appname/data')` reads from `appname/data` directory.
///
/// Note: Only `appname/data/` paths are supported for the readPod operations called by getResources().

Future<List<String>> getResources(
  BuildContext context,
  Widget child,
) async {
  await checkLoggedIn(
    errorMessage: 'User must be logged in to get resources. '
        'Please authenticate before calling getResources().',
  );

  var webId = await getWebId() as String;
  webId = webId.replaceAll(profCard, '');

  final dataDirPath = await getDataDirPath();
  final dataDirUrl = await getDirUrl(dataDirPath);

  final resDirUrl = dataDirUrl;

  // Normalise the file path to use appname/data as base path
  // and handle cross-platform path separators properly.

  final normalizedFilePath = await normalizeFilePath(resDirUrl, null);

  // Check if the directory exists.

  final dirExists = await checkResourceStatus(resDirUrl, isFile: false);

  switch (dirExists) {
    case ResourceStatus.exist:
      try {
        //debugPrint('Data: $dataDirUrl');
        final res = await getResourcesInContainer(resDirUrl);
        // debugPrint(res.toString());

        return res.files;
      } on Object catch (e) {
        debugPrint(e.toString());
        rethrow;
      }
    case ResourceStatus.notExist:
      throw Exception('Resource "$normalizedFilePath" does not exist.');
    default:
      throw Exception('Unknown error.');
  }
}
