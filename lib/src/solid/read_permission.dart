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
/// Authors: Anushka Vidanage, Jess Moore

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart';

/// Read permission given for the [fileName] from the associated ACL file.
///
/// Parameters:
/// - [fileName] - is the name of the file reading permission from. In case where
/// - [isExternalRes] - is boolean describing whether [fileName] is an
/// external resource shared with the user. If it is set to true, the
/// [fileName] should be the full URL of the file.
/// - [isFile] - boolean describing whether [fileName] is a file or not.

Future<Map<dynamic, dynamic>> readPermission({
  required String fileName,
  required bool isFile,
  bool isExternalRes = false,
}) async {
  final resourceUrl = await filenameToResourceUrl(
    fileName: fileName,
    isExternalRes: isExternalRes,
    isFile: isFile,
  );

  // Read ACL file content
  final Map<dynamic, dynamic> aclContentMap =
      await readAcl(resourceUrl, isFile);

  // Extract permission details to a map
  final Map<dynamic, dynamic> permMap = extractAclPerm(aclContentMap);

  return permMap;
}
