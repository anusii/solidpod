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

import 'dart:convert';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypter_plus/encrypter_plus.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/key_inheritance.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
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
/// - `readPod('abc.ttl')` reads from `appname/data/abc.ttl`
/// - `readPod('movies/abc.ttl')` reads from `appname/data/movies/abc.ttl`
/// - `readPod('appname/data/file.ttl', pathType: PathType.relativeToPod)` reads from `appname/data/file.ttl`
/// - `readPod('custom/file.ttl', pathType: PathType.relativeToApp)` reads from `appname/custom/file.ttl`
/// - `readPod('https://pods.solidcommunity.au/podName/appDirectory/data/file.ttl', pathType: PathType.absoluteUrl)`
///    reads from 'https://pods.solidcommunity.au/podName/appDirectory/data/file.ttl'
///
/// [filePath] - The path to the file to read
/// [pathType] - Optional type of file path to override the default (relative to `appname/data` directory)

Future<String> readPod(
  String filePath, {
  PathType pathType = PathType.relativeToData,
}) async {
  if (!await checkLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to read from POD.',
    );
  }

  final fileUrl = await generateResourceUrlFromPath(
    resourcePath: filePath,
    pathType: pathType,
  );

  final fileStatus = await checkResourceStatus(fileUrl);

  if (fileStatus != ResourceStatus.exist) {
    switch (fileStatus) {
      case ResourceStatus.notExist:
        throw ResourceNotExistException('$fileUrl does not exist');
      case ResourceStatus.forbidden:
        throw AccessForbiddenException('Access to $fileUrl is not allowed');
      case ResourceStatus.unknown:
        throw Exception('Unknown error.');
      default:
        {}
    }
  }

  try {
    // Retrieve raw content

    // final fileContent = await fetchPrvFile(fileUrl);

    final fileContent = utf8.decode(
      await getResource(fileUrl),
    );

    // Parse raw content if its turtle

    if (!fileUrl.toLowerCase().endsWith('.ttl')) {
      return fileContent;
    }

    // final tripleMap = turtleToTripleMap(fileContent);
    // assert(tripleMap.containsKey(fileUrl));

    // // Retrieve encryption key if available

    // final map = tripleMap[fileUrl]!;
    // String? inheritKeyPath = map[solidTermsNS.ns.withAttr(inheritKeyPred).value];
    Key? encKey;

    // if (await KeyManager.hasIndividualKey(fileUrl)) {
    //   encKey = await KeyManager.getIndividualKey(fileUrl);
    // } else if (inheritKeyPath != null) {

    //   encKey = await KeyManager.getIndividualKey(await getDirUrl(inheritKeyPath) );
    // } else {
    //   if (pathType == PathType.absoluteUrl) {
    //     if (await KeyManager.hasSharedIndividualKey(fileUrl)) {
    //       encKey = await KeyManager.getSharedIndividualKey(fileUrl);

    //   }
    // }

    // }

    // IV? iv = map[solidTermsNS.ns.withAttr(ivPred).value];
    // String? encData = map[solidTermsNS.ns.withAttr(encDataPred).value];

    if (await KeyManager.hasIndividualKey(fileUrl)) {
      // Get the individual key for the file.

      encKey = await KeyManager.getIndividualKey(fileUrl);
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
      encKey = await KeyManager.getIndividualKey(parentDirUrl);
    }

    if (encKey != null) {
      // Decrypt the file content

      final tripleMap = turtleToTripleMap(fileContent);

      assert(tripleMap.containsKey(fileUrl));

      String getVal(String pred) =>
          tripleMap[fileUrl]![solidTermsNS.ns.withAttr(pred).value] as String;

      return decryptData(
        getVal(encDataPred),
        encKey,
        IV.fromBase64(getVal(ivPred)),
      );
    } else {
      return fileContent;
    }
  } on Object catch (e) {
    debugPrint(e.toString());
    rethrow;
  }
}
