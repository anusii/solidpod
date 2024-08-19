/// Function to read permissions for a given private file in a POD.
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
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart';

/// Read permission given for the [fileName].
/// Parameters:
///   [fileName] is the name of the file reading permission from
///   [fileFlag] is the flag to identify if the resources is a file or not
///   [child] is the child widget to return to

Future<dynamic> readPermission(
  String fileName,
  bool fileFlag,
  BuildContext context,
  Widget child,
) async {
  final loggedIn = await loginIfRequired(context);

  if (loggedIn) {
    await getKeyFromUserIfRequired(context, child);

    // Get the file path
    final filePath = [await getDataDirPath(), fileName].join('/');

    // Get the url of the file
    final resourceUrl = await getFileUrl(filePath);

    // Check if file exists
    final resStatus =
        await checkResourceStatus(resourceUrl, fileFlag: fileFlag);

    if (resStatus == ResourceStatus.exist) {
      // Read ACL file content
      final aclContentMap = await readAcl(resourceUrl);

      // Extract permission details to a map
      final permMap = extractAclPerm(aclContentMap);

      return permMap;
    } else {
      return {};
    }
  } else {
    return SolidFunctionCallStatus.notLoggedIn;
  }
}
