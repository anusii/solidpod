/// Function to read a private file in PODs.
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
/// Authors: Anushka Vidanage, Dawei Chen

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Read file content from a POD
///
/// First check if the user is logged in and then
/// read and parse the file content

Future<String?> readPod(
    String filePath, BuildContext context, Widget child) async {
  // Login and initialise PODs if necessary

  await loginIfRequired(context);

  // Check if the requested file exists

  final fileUrl = await getFileUrl(filePath);
  final fileExists = await checkResourceStatus(fileUrl);

  if (fileExists == ResourceStatus.exist) {
    try {
      final fileContent = await fetchPrvFile(fileUrl);

      // Decrypt if reading an encrypted file

      if (await KeyManager.hasIndividualKey(fileUrl)) {
        await getKeyFromUserIfRequired(context, child);

        // Get the individual key for the file
        final indKey = await KeyManager.getIndividualKey(fileUrl);

        // Decrypt the file content

        final dataMap = parseTTL(fileContent);
        assert(dataMap.containsKey(fileUrl));

        return decryptData(dataMap[fileUrl][encDataPred] as String, indKey,
            IV.fromBase64(dataMap[fileUrl][ivPred] as String));
      } else {
        return fileContent;
      }
    } on Object catch (e) {
      debugPrint(e.toString());
    }
  }

  debugPrint('Resource "$filePath" does not exist.');
  return null;
}
