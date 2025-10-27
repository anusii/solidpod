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

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/common_permission.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants/common.dart';
// import 'package:solidpod/src/solid/read_permission.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
// import 'package:solidpod/src/solid/utils/permission.dart';

/// Check [fileName] exists and has the associated ACL file. Requires user
/// to be logged in.
///
/// Parameters:
///   [fileName] is the name of the file reading permission from. In case where
///   [isExternalRes] is set to true, [fileName] should be the full URL of the file
///   [isFile] is the flag to identify if the resources is a file or not
///   [child] is the child widget to return to
///   [isExternalRes] is set to true if reading permissions from an external file
/// - [context] - The build context.

Future<dynamic> chkExistsAndHasAcl({
  required String fileName,
  required bool isFile,
  required BuildContext context,
  required Widget child,
  bool isExternalRes = false,
}) async {
  final loggedIn = await loginIfRequired(context);

  if (loggedIn) {
    await getKeyFromUserIfRequired(context, child);

    final resourceUrl = await filenameToResourceUrl(
      fileName: fileName,
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
      return {};
    }
  } else {
    return SolidFunctionCallStatus.notLoggedIn;
  }
}
