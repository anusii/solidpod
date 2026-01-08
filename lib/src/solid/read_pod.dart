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

library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/key_inheritance.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Read a (shared) file from POD..
///
/// Examples:
/// - `readPod('abc.ttl')` reads from `appname/data/abc.ttl`
/// - `readPod('movies/abc.ttl')` reads from `appname/data/movies/abc.ttl`
/// - `readPod('appname/data/file.ttl', pathType: PathType.relativeToPod)` reads from `appname/data/file.ttl`
/// - `readPod('custom/file.ttl', pathType: PathType.relativeToApp)` reads from `appname/custom/file.ttl`
/// - `readPod('https://pods.solidcommunity.au/podName/appDirectory/data/file.ttl', pathType: PathType.absoluteUrl)`
///    reads from 'https://pods.solidcommunity.au/podName/appDirectory/data/file.ttl'
///
/// Arguments:
/// - [filePath]: The path to the file to read
/// - [pathType]: Optional type of relative file path to override the default (relative to `appname/data` directory)

Future<String> readPod(
  String filePath, {
  PathType pathType = PathType.relativeToData,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to read from POD');
  }

  final fileUrl = await generateResourceUrlFromPath(
    resourcePath: filePath,
    pathType: pathType,
  );

  debugPrint('readPod: fileUrl=$fileUrl');

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

    final fileContent = utf8.decode(
      await getResource(fileUrl),
    );

    // Return raw content for non-turtle files

    if (!fileUrl.toLowerCase().endsWith('.ttl')) {
      return fileContent;
    }

    // Parse raw content if its turtle

    final tripleMap = turtleToTripleMap(fileContent);

    // Return raw content for turtle files that are not
    // encrypted by solidpod

    if (!tripleMap.containsKey(fileUrl)) {
      return fileContent;
    }

    final map = tripleMap[fileUrl]!;
    String? ivStr = map[getPredicateUrl(ivPred)];
    String? encDataStr = map[getPredicateUrl(encDataPred)];
    String? inheritKeyPath = map[getPredicateUrl(inheritKeyPred)];

    // Plaintext turtle

    if (ivStr == null || encDataStr == null) {
      return fileContent;
    }

    // Retrieve encryption key if available

    String? inheritKeyUrl;
    if (inheritKeyPath != null) {
      inheritKeyUrl = await generateResourceUrlFromPath(
        resourcePath: inheritKeyPath,
        pathType: PathType.relativeToPod,
        webId: await generateWebIdFromResourceUrl(fileUrl),
      );
    }

    final encKey = await retrieveEncKey(fileUrl, inheritKeyUrl: inheritKeyUrl);

    // Return (decrypted) text

    return encKey != null
        ? decryptData(encDataStr, encKey, IV.fromBase64(ivStr))
        : fileContent;
  } on Object catch (e, trace) {
    debugPrint(e.toString());
    debugPrint(trace.toString());
    rethrow;
  }
}
