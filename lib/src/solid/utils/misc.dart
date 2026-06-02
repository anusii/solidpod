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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path/path.dart' as path;
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart' show DpopTokenGenerator;

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

/// Get tokens necessary to fetch a resource from a POD
///
/// returns the access token and DPoP token
Future<({String accessToken, String dPopToken})> getTokensForResource(
  String resourceUrl,
  String httpMethod,
) async {
  final authData = await AuthDataManager.loadAuthData();

  if (authData == null) {
    throw Exception('Authentication data not available. Please login first.');
  }

  final authManager = AuthDataManager.getAuthManager();
  if (authManager == null) {
    throw Exception('Auth manager not available. Please login first.');
  }

  final dPopToken = await DpopTokenGenerator.generateForRequest(
    endpointUrl: resourceUrl,
    httpMethod: httpMethod,
    accessToken: authData.accessToken,
    keyManager: authManager.keyManager,
  );

  return (
    accessToken: authData.accessToken,
    dPopToken: dPopToken,
  );
}

/// Logging out the user with comprehensive error handling and platform support
///
/// This function performs a complete logout that includes:
/// 1. Clearing all encryption keys from memory
/// 2. Clearing application-specific caches
/// 3. Calling the OIDC logout endpoint via SolidAuthManager (with error tolerance)
/// 4. Removing authentication data from secure storage
///
/// Returns true if critical cleanup (key/auth data) succeeds.
Future<bool> logoutPod() async {
  try {
    await KeyManager.clear();

    // Clear app caches before any network operations to prevent race conditions.
    if (_onLogoutClearCaches != null) {
      try {
        await _onLogoutClearCaches!();
      } on Object catch (e) {
        debugPrint('logoutPod() cache callback failed (non-critical): $e');
      }
    }

    // Contact the OIDC logout endpoint and rotate the DPoP key.
    // Must be called before removeAuthData() clears _authManager.
    try {
      await AuthDataManager.getAuthManager()?.logout();
    } on Object catch (e) {
      debugPrint('logoutPod() OAuth2 logout warning (non-critical): $e');
    }

    final authDataRemoved = await AuthDataManager.removeAuthData();
    return authDataRemoved;
  } on Object catch (e) {
    debugPrint('logoutPod() CRITICAL ERROR: $e');
    try {
      await AuthDataManager.removeAuthData();
      await KeyManager.clear();
    } on Object catch (_) {}
    return false;
  }
}

/// Clear all login state without opening a browser.
///
/// Performs the same cleanup as [logoutPod] but invalidates the IdP session
/// via a headless HTTP request rather than launching a visible browser
/// window. Use this when switching accounts or recovering from stale
/// credentials.

Future<bool> silentLogout() async {
  try {
    await KeyManager.clear();

    // Get logout URL from discovery doc before clearing the manager.
    String? logoutUrl;
    try {
      logoutUrl = await AuthDataManager.getLogoutUrl();
    } on Object catch (_) {}

    // Clear local token state only — no browser redirect.
    await AuthDataManager.getAuthManager()?.forgetUser();

    final authDataRemoved = await AuthDataManager.removeAuthData();

    if (_onLogoutClearCaches != null) {
      try {
        await _onLogoutClearCaches!();
      } on Object catch (e) {
        debugPrint('silentLogout() cache callback failed (non-critical): $e');
      }
    }

    // Best-effort IdP session invalidation via headless HTTP GET.
    if (logoutUrl != null && logoutUrl.isNotEmpty) {
      try {
        await http.get(Uri.parse(logoutUrl));
      } on Object catch (e) {
        debugPrint('silentLogout() headless logout failed (non-critical): $e');
      }
    }

    return authDataRemoved;
  } on Object catch (e) {
    debugPrint('silentLogout() CRITICAL: $e');
    try {
      await AuthDataManager.removeAuthData();
      await KeyManager.clear();
    } on Object catch (_) {}
    return false;
  }
}

/// Removes header and footer (which mess up the TTL format) from a PEM-formatted public key string.
///
/// This function takes a public key string, typically in PEM format, and removes
/// the standard PEM headers and footers.

String trimPubKeyStr(String keyStr) {
  final itemList = keyStr.split('\n');
  itemList.remove('-----BEGIN RSA PUBLIC KEY-----');
  itemList.remove('-----END RSA PUBLIC KEY-----');
  itemList.remove('-----BEGIN PUBLIC KEY-----');
  itemList.remove('-----END PUBLIC KEY-----');

  final keyStrTrimmed = itemList.join();

  return keyStrTrimmed;
}

/// Get date and time from a string
String getDateTime(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a');

  return dateFormat.format(dateTime);
}
