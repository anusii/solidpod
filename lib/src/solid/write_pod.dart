/// Function to write data to a private file in PODs.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Dawei Chen

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants.dart' show ResourceStatus;
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Write file [fileName] and content [fileContent] to PODs
/// The content will be encrypted if [encryptContent] is true.

Future<void> writePod(
    String fileName, String fileContent, BuildContext context, Widget child,
    {bool encryptContent = true}) async {
  // Write data to file in the data directory
  final filePath = path.join(await getDataDirPath(), fileName);

  await loginIfRequired(context);

  // Check if the file already exists

  final fileUrl = await getFileUrl(filePath);
  final fileExists = await checkResourceStatus(fileUrl, true);

  final replace = fileExists == ResourceStatus.exist ? true : false;
  late final String content;

  if (encryptContent) {
    // Get the security key (and cache it in KeyManager)
    await getKeyFromUserIfRequired(context, child);

    late final Key indKey;

    switch (fileExists) {
      case ResourceStatus.exist:
        // Reuse the individual key if the file already exists
        indKey = await KeyManager.getIndividualKey(fileUrl);

      case ResourceStatus.notExist:
        // Generate random individual key
        indKey = genRandIndividualKey();

        // Add the encrypted individual key and its IV to the ind-key file
        await KeyManager.putIndividualKey(filePath, indKey);

      default:
        throw Exception('Unable to determine if file "$filePath" exists');
    }

    // Encrypt the file content
    content = await getEncTTLStr(filePath, fileContent, indKey, genRandIV());
  } else {
    content = fileContent;
  }

  // Create file on server
  await createResource(fileUrl, content: content, replaceIfExist: replace);
}
