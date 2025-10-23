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

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart';

/// Read permission given for the [fileName].
/// Parameters:
///   [fileName] is the name of the file reading permission from. In case where
///   [isExternalRes] is set to true, [fileName] should be the full URL of the file
///   [isFile] is the flag to identify if the resources is a file or not
///   [child] is the child widget to return to
///   [isExternalRes] is set to true if reading permissions from an external file

Future<dynamic> readPermission(
  String fileName,
  bool isFile,
  BuildContext context,
  Widget child, {
  bool isExternalRes = false,
}) async {
  final loggedIn = await loginIfRequired(context);

  if (loggedIn) {
    await getKeyFromUserIfRequired(context, child);

    var resourceUrl = '';
    if (!isExternalRes) {
      // Get the file path
      final filePath = [await getDataDirPath(), fileName].join('/');

      // Get the url of the file
      resourceUrl = await getFileUrl(filePath);
    } else {
      // Get the url of the file
      resourceUrl = fileName;
    }

    // Check if file exists
    final resStatus = await checkResourceStatus(resourceUrl, isFile: isFile);

    if (resStatus == ResourceStatus.exist ||
        resStatus == ResourceStatus.forbidden) {
      if (resStatus == ResourceStatus.forbidden) {
        debugPrint(
          '[read_permission] Allowing resource\'s ACL to be read when the resource is access forbidden',
        );
      }

      // Check if the resource has an ACL
      bool hasAcl = await resourceHasAcl(resourceUrl, isFile: isFile);

      if (hasAcl) {
        // Read ACL file content
        final aclContentMap = await readAcl(resourceUrl, isFile);

        // Extract permission details to a map
        final permMap = extractAclPerm(aclContentMap);

        return permMap;
      } else {
        debugPrint('Resource does not have a corresponding ACL file. '
            'If the ACL is inherited provide parent directory as the resource name!');
        return SolidFunctionCallStatus.noAclFound;
      }
    } else {
      return {};
    }
  } else {
    return SolidFunctionCallStatus.notLoggedIn;
  }
}
