/// Function to read a private file in PODs.
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
/// Authors: Anushka Vidanage, Dawei Chen, Ashley Tang, Graham Williams

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart' hide Key;

import 'package:encrypter_plus/encrypter_plus.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Read [filePath] from POD with file [mode] (default is text).
///
/// Check if the user is logged in and then read and parse the file content.
///
/// The file will be read from the `appname/data` directory by default, unless
/// [basePath] is specified to override the default base path.
///
/// Examples:
/// - `readPod('abc.ttl', context, widget)` reads from `appname/data/abc.ttl`
/// - `readPod('movies/abc.ttl', context, widget)` reads from `appname/data/movies/abc.ttl`
/// - `readPod('appname/data/file.ttl', context, widget)` reads from `appname/data/file.ttl` (already correct path)
/// - `readPod('file.ttl', context, widget, basePath: 'appname/custom')` reads from `appname/custom/file.ttl`
///
/// [filePath] - The path to the file to read
/// [context] - The BuildContext for UI interactions (e.g., security key prompts)
/// [child] - The child widget to return to after UI interactions
/// [mode] - The file open mode (default: text)
/// [basePath] - Optional base path to override the default `appname/data` directory

Future<String> readPod(
  String filePath,
  BuildContext context,
  Widget child, {
  FileOpenMode mode = FileOpenMode.text,
  String? basePath,
}) async {
  if (!await checkLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to read from POD.',
    );
  }

  // Normalise the file path using the specified base path
  // or default to appname/data, and handle cross-platform path separators
  // properly.

  final normalizedFilePath = await normalizeFilePath(filePath, basePath);

  // Check if the requested file exists

  final fileUrl = await getFileUrl(normalizedFilePath);
  final fileExists = await checkResourceStatus(fileUrl);

  switch (fileExists) {
    case ResourceStatus.exist:
      try {
        final fileContent = await fetchPrvFile(fileUrl);

        // Decrypt if reading an encrypted file
        Key? indKey;

        if (await KeyManager.hasIndividualKey(fileUrl)) {
          // Get the individual key for the file.

          indKey = await KeyManager.getIndividualKey(fileUrl);
        } else if (hasInheritedKey(
          fileContent,
          fileUrl,
        )) {
          // Get the individual key for the file.

          final parentDirPath = getParentDir(
            fileContent,
            fileUrl,
          );
          final parentDirUrl = await getDirUrl(parentDirPath);
          indKey = await KeyManager.getIndividualKey(parentDirUrl);
        }

        if (indKey != null) {
          // Decrypt the file content

          final dataMap = parseTTL(fileContent);
          assert(dataMap.containsKey(fileUrl));

          return decryptData(
            dataMap[fileUrl][encDataPred] as String,
            indKey,
            IV.fromBase64(dataMap[fileUrl][ivPred] as String),
          );
        } else {
          return fileContent;
        }
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
