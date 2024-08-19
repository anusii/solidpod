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

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';
import 'package:solidpod/src/solid/api/common_permission.dart';

/// Read permission given for the [fileName].
/// Parameters:
///   [child] is the child widget to return to
///   [fileName] is the name of the file reading permission from
///   [sourceWebId] is the source WebID

Future<dynamic> sharedResources(
  BuildContext context,
  Widget child, [
  String? fileName,
  String? sourceWebId,
]) async {
  final loggedIn = await loginIfRequired(context);

  if (loggedIn) {
    await getKeyFromUserIfRequired(context, child);

    // Get user webID
    final userWebId = await AuthDataManager.getWebId() as String;

    // Log file url
    final logFilePath = await getPermLogFilePath();
    final logFileUrl = await getFileUrl(logFilePath);

    // Read log file
    final logContent = await fetchPrvFile(logFileUrl);

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
  } else {
    return SolidFunctionCallStatus.notLoggedIn;
  }
}
