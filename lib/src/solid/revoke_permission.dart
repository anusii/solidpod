/// Function to revoke permission from a private file in a POD.
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
import 'package:solidpod/src/solid/utils/misc.dart';

/// Revoke permissions from [fileName] for a given [removerWebId].
/// Parameters:
///   [fileName] is the name of the file revoking permission from
///   [fileFlag] is the flag to identify if the resources is a file or not
///   [removerWebId] is the webId of the permission remover
///   [child] is the child widget to return to

Future<void> revokePermission(String fileName, bool fileFlag,
    String removerWebId, BuildContext context, Widget child) async {
  await loginIfRequired(context);

  await getKeyFromUserIfRequired(context, child);

  // Get the file path
  final filePath = [await getDataDirPath(), fileName].join('/');

  // Get the url of the file
  final resourceUrl = await getFileUrl(filePath);

  // Check if file exists
  final resStatus = await checkResourceStatus(resourceUrl, fileFlag: fileFlag);

  if (resStatus == ResourceStatus.exist) {
    final resourceName = resourceUrl.split('/').last;

    // Remove the permission line from the relevant ACL file
    await removePermissionAcl(resourceName, resourceUrl, removerWebId);

    // Check if the file is encrypted
    final fileIsEncrypted = await checkFileEnc(resourceUrl);

    // If the file is encrypted then share the individual encryption key
    // with the receiver
    if (fileIsEncrypted) {
      // Generate unique ID for the resource being shared
      final resUniqueId = getUniqueIdResUrl(resourceUrl, removerWebId);

      // Delete shared key content from recipient's POD
      await removeSharedKey(removerWebId, resUniqueId);
    }
  }
}