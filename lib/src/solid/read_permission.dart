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

library;

import 'dart:core';

import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/constants/common.dart'
    show agentClassPred, agentStr, permStr;
import 'package:solidpod/src/solid/constants/web_acl.dart'
    show RecipientType, authenticatedAgent, publicAgent;
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart';

/// Read permission given for the [fileName] from the associated ACL file.
///
/// Parameters:
/// - [fileName] - is the name of the file reading permission from.
/// - [isFile] - flag describing whether [fileName] is a file or not.
///
/// - [isFileUrl] - boolean describing whether [fileName] is the url
/// of the resource. Default: false.
/// - [isExternalRes] - flag describing whether [fileName] is an
/// external resource shared with the user. If it is set to true, the
/// [fileName] should be the full URL of the file. Default: false.

Future<Map<dynamic, dynamic>> readPermission({
  required String fileName,
  required bool isFile,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  final resourceUrl = await filenameToResourceUrl(
    fileName: fileName,
    isFile: isFile,
    isExternalRes: isExternalRes,
    isFileUrl: isFileUrl,
  );

  // Read ACL file content
  final Map<dynamic, dynamic> aclContentMap = await readAcl(
    resourceUrl,
    isFile,
  );

  // Extract permission details to a map
  final Map<dynamic, dynamic> permMap = extractAclPerm(aclContentMap);

  return permMap;
}

/// The Public/Authenticated-User access modes currently granted on
/// [fileName], keyed by [RecipientType.public]/[RecipientType.authUser].
/// A class with no current grant is omitted from the result.
///
/// Single source of truth for "does this resource currently have a
/// Public/AuthenticatedUser grant" — used both by [grantPermission] (to
/// decide whether an individual/group grant must first revoke and
/// re-encrypt) and by solidui's confirmation dialog for the same action.

Future<Map<RecipientType, List<String>>> getUserClassPermissions({
  required String fileName,
  required bool isFile,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  final permMap = await readPermission(
    fileName: fileName,
    isFile: isFile,
    isFileUrl: isFileUrl,
    isExternalRes: isExternalRes,
  );

  final result = <RecipientType, List<String>>{};
  for (final receiverId in permMap.keys) {
    if (receiverId is! String ||
        permMap[receiverId][agentStr] != agentClassPred) {
      continue;
    }
    final perms = (permMap[receiverId][permStr] as List).cast<String>();
    if (URIRef(receiverId) == publicAgent) {
      result[RecipientType.public] = perms;
    } else if (URIRef(receiverId) == authenticatedAgent) {
      result[RecipientType.authUser] = perms;
    }
  }
  return result;
}
