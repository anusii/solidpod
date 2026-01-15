/// Function to check if user is logged in and has ACL in a POD.
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
/// Authors: Anushka Vidanage, Jess Moore

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Check [fileName] exists and has the associated ACL file. Requires user
/// to be logged in.
///
/// Parameters:
/// - [fileName] - is the name of the file to reading permission from.
/// - [isFile] - flag describing whether the resources is a file or not.
/// (Default: false).
/// - [isFileUrl] - flag describing whether the resource [fileName] is
/// the url of the resource. (Default: false).
/// - [isExternalRes] - flag describing whether the resource is an
/// external file shared with the user. (Default: false).

Future<SolidFunctionCallStatus> chkExistsAndHasAcl({
  required String fileName,
  required bool isFile,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  if (!await isUserLoggedIn()) {
    return SolidFunctionCallStatus.notLoggedIn;
  }

  final resourceUrl = await filenameToResourceUrl(
    fileName: fileName,
    isFileUrl: isFileUrl,
    isExternalRes: isExternalRes,
    isFile: isFile,
  );

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
      // Return desired acl found status
      return SolidFunctionCallStatus.aclFound;
    } else {
      debugPrint('Resource does not have a corresponding ACL file. '
          'If the ACL is inherited provide parent directory as the resource name!');
      return SolidFunctionCallStatus.noAclFound;
    }
  } else {
    return SolidFunctionCallStatus.fileNotExists;
  }
}
