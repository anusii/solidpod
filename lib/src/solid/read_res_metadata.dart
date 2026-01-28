/// Function to read metadata of a resource.
///
/// Copyright (C) 2024-2026, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

Future<Map<String, String>> readResMetadata(
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
    // Retrieve file metadata
    return await getResourceMetadata(fileUrl);
  } on Object catch (e, trace) {
    debugPrint(e.toString());
    debugPrint(trace.toString());
    rethrow;
  }
}
