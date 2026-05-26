/// Miscellaneous utility functions used across the package.
///
// Time-stamp: <Thursday 2026-01-22 11:12:44 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'package:intl/intl.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/app_info.dart';

export 'package:solidpod/src/solid/utils/misc_auth.dart';
export 'package:solidpod/src/solid/utils/misc_container.dart';
export 'package:solidpod/src/solid/utils/misc_encryption.dart';
export 'package:solidpod/src/solid/utils/misc_paths.dart';

// solid-encrypt uses unencrypted local storage and refers to http: //yarrabah.net/ for predicates definition,
// do not use it before it is updated (same as what the gurriny project does)
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Write the given [key], [value] pair to the secure storage.
///
/// If [key] already exisits then delete that first and then
/// write again.

Future<void> writeToSecureStorage(String key, String value) async {
  final isKeyExist = await secureStorage.containsKey(key: key);

  // Since write() method does not automatically overwrite an existing value.
  // To overwrite an existing value, call delete() first.

  if (isKeyExist) {
    await secureStorage.delete(key: key);
  }

  await secureStorage.write(key: key, value: value);
}

/// Extract the app name and the version from the package info
/// Return a record (with named fields https://dart.dev/language/records)

Future<({String name, String version})> getAppNameVersion() async =>
    (name: await AppInfo.name, version: await AppInfo.version);

/// Set directory name for the app for storing the POD data
///
/// If not initially set the app name will be taken by default.

Future<void> setAppDirName(String inputAppDirName) async {
  if (inputAppDirName.isEmpty) {
    appDirName = await AppInfo.canonicalName;
  } else {
    appDirName = inputAppDirName;
  }
}

/// Get resource acl file path
String getResAclFile(String resourceUrl, [bool isFile = true]) {
  final resourceAclUrl = resourceUrl.endsWith('.acl')
      ? resourceUrl
      : isFile
          ? '$resourceUrl.acl'
          : '$resourceUrl/.acl';

  return resourceAclUrl;
}

/// Extract permission details of a file into a map.
/// Returns a map where keys are permission receiver webIds and
/// values are the list of permissions
Map<dynamic, dynamic> extractAclPerm(Map<dynamic, dynamic> aclFileContentMap) {
  final filePermMap = <dynamic, dynamic>{};
  for (final accessStr in aclFileContentMap.keys) {
    final permList = aclFileContentMap[accessStr][modePred];
    final receiverMap = {};

    if ((aclFileContentMap[accessStr] as Map).containsKey(agentPred)) {
      for (final receiverId
          in aclFileContentMap[accessStr][agentPred] as List) {
        receiverMap[receiverId] = agentPred;
      }
    }
    if ((aclFileContentMap[accessStr] as Map).containsKey(agentClassPred)) {
      for (final receiverId
          in aclFileContentMap[accessStr][agentClassPred] as List) {
        receiverMap[receiverId] = agentClassPred;
      }
    }
    if ((aclFileContentMap[accessStr] as Map).containsKey(agentGroupPred)) {
      for (final receiverId
          in aclFileContentMap[accessStr][agentGroupPred] as List) {
        receiverMap[receiverId] = agentGroupPred;
      }
    }

    for (final receiverId in receiverMap.keys) {
      if (filePermMap.containsKey(receiverId)) {
        filePermMap[receiverId][permStr] += permList;
        filePermMap[receiverId][agentStr] = receiverMap[receiverId];
      } else {
        filePermMap[receiverId] = {
          permStr: permList,
          agentStr: receiverMap[receiverId],
        };
      }
    }
  }

  return filePermMap;
}

/// Get resource name from URL
String getResNameFromUrl(String resourceUrl) {
  return resourceUrl.split('/').last;
}

/// Get date and time from a string
String getDateTime(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a');

  return dateFormat.format(dateTime);
}
