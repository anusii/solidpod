/// Function to read shared resources for the user.
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
/// Authors: Anushka Vidanage

library;

import 'dart:convert';

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Read permission given for the [fileName].
///
/// Parameters:
/// - [fileName] is the name of the file reading permission from
/// - [sourceWebId] is the source WebID

Future<dynamic> sharedResources([
  String? fileName,
  String? sourceWebId,
]) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to access shared resources.',
    );
  }

  // Get user webID
  final userWebId = await AuthDataManager.getWebId() as String;

  // Log file url
  final logFilePath = await getPermLogFilePath();
  final logFileUrl = await getFileUrl(logFilePath);

  // Read log file
  final logContent = utf8.decode(
    await getResource(logFileUrl),
  );

  final logDataMap = parseTTLMap(logContent);

  var uniqueLogMap = getLatestLog(logDataMap, userWebId);

  // Filer log entried based on defined file name
  if (fileName != null) {
    uniqueLogMap = filterLogByFilename(uniqueLogMap, fileName);
  }

  // Filer log entried based on defined source webId
  if (sourceWebId != null) {
    uniqueLogMap = filterLogByWebId(uniqueLogMap, sourceWebId);
  }

  return uniqueLogMap;
}
