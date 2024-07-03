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

import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/api_client.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Read file content from a POD
///
/// First check if the user is logged in and then
/// read and parse the file content

Future<dynamic> readPod(String filePath, BuildContext context, Widget child,
    {FileOpenMode mode = FileOpenMode.text}) async {
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

Future<void> downloadFile(String remoteFileName, File file) async {
  final fileUrl =
      await getFileUrl([await getDataDirPath(), remoteFileName].join('/'));

  if (await checkResourceStatus(fileUrl) == ResourceStatus.notExist) {
    throw Exception('$fileUrl does not exist');
  }

  final sink = file.openWrite();
  final stream = await CssApiClient.pullBinaryData(fileUrl);
  final fileSize = await getFileSize(fileUrl);
  var receivedSize = 0;

  stream.listen((chunk) {
    receivedSize += chunk.length;
    sink.add(chunk);
    debugPrint('${chunk.length}: ${receivedSize * 100.0 / fileSize}%');
  }, onDone: () => unawaited(sink.close()));

  debugPrint('File written to ${file.absolute}');

  // await createResource(fileUrl,
  //     content: await file.readAsBytes(),
  //     contentType: ResourceContentType.binary);

  // await streamRequestStream(fileUrl, file.openRead());
}

Future<int> getFileSize(String fileUrl) async => int.parse(
    (await CssApiClient.getResourceHeaders(fileUrl))['content-length']!);
