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
import 'package:solidpod/src/solid/models/log_record.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Read permission log (including revoked permissions) of a user's
/// Pod for a specific [resourceName].
///
/// Parameters:
/// - [resourceName] is the name of the file reading permission from

Future<List<LogRecord>> sharedResourcesHistory({
  required String resourceName,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to access shared resources.',
    );
  }

  // Log file url
  final logFilePath = await getPermLogFilePath();
  final logFileUrl = await getFileUrl(logFilePath);

  // Read log file
  final logContent = utf8.decode(
    await getResource(logFileUrl),
  );

  // Convert log from TTL to triple map
  final logDataMap = parseTTLMap(logContent);

  // Extract permission history log of file from log in triple map format
  final List<LogRecord> permHistMap = getLog(
    resourceName: resourceName,
    logDataMap: logDataMap,
  );

  return permHistMap;
}
