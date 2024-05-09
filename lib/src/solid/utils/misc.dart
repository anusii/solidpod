/// Miscellaneous utility functions used across the package.
///
// Time-stamp: <Friday 2024-02-16 10:59:10 +1100 Graham Williams>
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

import 'package:encrypt/encrypt.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path/path.dart' as path;
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/utils/app_info.dart' show AppInfo;
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;

// solid-encrypt uses unencrypted local storage and refers to http://yarrabah.net/ for predicates definition,
// do not use it before it is updated (same as what the gurriny project does)
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Write the given [key], [value] pair to the secure storage.
///
/// If [key] already exisits then delete that first and then
/// write again.

Future<void> writeToSecureStorage(String key, String value) async {
  final isKeyExist = await secureStorage.containsKey(
    key: key,
  );

  // Since write() method does not automatically overwrite an existing value.
  // To overwrite an existing value, call delete() first.

  if (isKeyExist) {
    await secureStorage.delete(
      key: key,
    );
  }

  await secureStorage.write(
    key: key,
    value: value,
  );
}

/// Get the verification key stored in PODs
// Future<String?> getVerificationKey() async {
//   final encKeyPath = await getEncKeyPath();
//   final encKeyFileUrl = await getFileUrl(encKeyPath);
//   final encKeyMap = await loadPrvTTL(encKeyFileUrl);

//   if (!encKeyMap.containsKey(encKeyFileUrl)) {
//     return null;
//   }

//   final verificationKey = encKeyMap[encKeyFileUrl][encKeyPred] as String;
//   return verificationKey;
// }

// /// Verify the user provided master password for data encryption
// bool verifyMasterPassword(String masterPasswd, String verificationKey) =>
//     genVerificationKey(masterPasswd) == verificationKey;

// /// Save master password to local secure storage
// Future<void> saveMasterPassword(String masterPasswd) async =>
//     writeToSecureStorage(masterPasswdSecureStorageKey, masterPasswd);

// /// Load master password from local secure storage
// Future<String?> loadMasterPassword() async =>
//     secureStorage.read(key: masterPasswdSecureStorageKey);

// /// Delete the saved master password from local secure storage
// Future<void> removeMasterPassword() async {
//   if (await secureStorage.containsKey(key: masterPasswdSecureStorageKey)) {
//     await secureStorage.delete(key: masterPasswdSecureStorageKey);
//   }
// }

/// Encrypt data using AES with the specified key
String encryptData(String data, Key key, IV iv, {AESMode mode = AESMode.sic}) =>
    Encrypter(AES(key, mode: mode)).encrypt(data, iv: iv).base64;

/// Decrypt a ciphertext value
String decryptData(String encData, Key key, IV iv,
        {AESMode mode = AESMode.sic}) =>
    Encrypter(AES(key, mode: mode)).decrypt(Encrypted.from64(encData), iv: iv);

/// Parse TTL content into a map {subject: {predicate: object}}
Map<String, dynamic> parseTTL(String ttlContent) {
  final g = Graph();
  g.parseTurtle(ttlContent);
  final dataMap = <String, dynamic>{};
  String extract(String str) => str.contains('#') ? str.split('#')[1] : str;
  for (final t in g.triples) {
    final sub = extract(t.sub.value as String);
    final pre = extract(t.pre.value as String);
    final obj = extract(t.obj.value as String);
    if (dataMap.containsKey(sub)) {
      assert(!(dataMap[sub] as Map).containsKey(pre));
      dataMap[sub][pre] = obj;
    } else {
      dataMap[sub] = {pre: obj};
    }
  }
  return dataMap;
}

/// Load and parse a private TTL file from POD
Future<Map<String, dynamic>> loadPrvTTL(String fileUrl) async {
  // final fileUrl = await getFileUrl(filePath);
  try {
    final rawContent = await fetchPrvFile(fileUrl);
    return parseTTL(rawContent);
  } on Exception catch (e) {
    throw Exception(e);
  }
}

/// Create a directory
// Future<bool> createDir(String dirName, String dirParentPath) async {
//   try {
//     // await createItem(dirName,
//     //     itemLoc: dirParentPath, contentType: dirContentType, fileFlag: false);
//     await createItem(false, dirName, '', fileLoc: dirParentPath);
//     return true;
//   } on Exception catch (e) {
//     print('Exception: $e');
//   }
//   return false;
// }

/// Create new TTL file with content
// Future<bool> createFile(String filePath, String fileContent) async {
//   try {
//     final fileName = path.basename(filePath);
//     final folderPath = path.dirname(filePath);

//     // await createItem(fileName, itemLoc: folderPath, itemBody: fileContent);
//     await createItem(true, fileName, fileContent,
//         fileType: 'text/turtle', fileLoc: folderPath);

//     return true;
//   } on Exception catch (e) {
//     print('Exception: $e');
//   }
//   return false;
// }

/// From a given resource path [resourcePath] create its URL
/// [isContainer] should be true if the resource is a directory, otherwise false
/// returns the full resource URL

Future<String> _getResourceUrl(String resourcePath, bool isContainer) async {
  final webId = await getWebId();
  assert(webId != null);
  assert(webId!.contains(profCard));
  final resourceUrl = webId!.replaceAll(profCard, resourcePath);
  if (isContainer && !resourceUrl.endsWith('/')) {
    return '$resourceUrl/';
  }

  return resourceUrl;
}

/// Create the URL for a file
Future<String> getFileUrl(String filePath) async =>
    _getResourceUrl(filePath, false);

/// Create the URL for a directory (container)
Future<String> getDirUrl(String dirPath) async =>
    _getResourceUrl(dirPath, true);

/// Encrypt a given data string and format to TTL
Future<String> getEncTTLStr(
    String filePath, String fileContent, Key key, IV iv) async {
  final encData = encryptData(fileContent, key, iv);

  final g = Graph();
  final f = URIRef(await getFileUrl(filePath));
  final ns = Namespace(ns: appsTerms);
  g.addTripleToGroups(f, ns.withAttr(pathPred), filePath);
  g.addTripleToGroups(f, ns.withAttr(ivPred), iv.base64);
  g.addTripleToGroups(f, ns.withAttr(encDataPred), encData);

  // Bind the long namespace to shorter string for better readability
  // String getPrefix(String UriStr) => Uri.parse(UriStr).pathSegments[-1];
  // g.bind(appFilePrefix, Namespace(ns: appsFile));
  // g.bind(appTermPrefix, ns);
  // final uri = Uri.parse(appsTerms);
  // final host = uri.host.split('.')[0];
  // final hostpath = uri.removeFragment().toString();
  // g.bind(host, Namespace(ns: hostpath));
  // g.bind(host, ns);

  g.serialize(abbr: 'short');

  final encTTL = g.serializedString;
  return encTTL;
}

/// Returns the path of file with verification key and private key
Future<String> getEncKeyPath() async =>
    [await AppInfo.canonicalName, encDir, encKeyFile].join('/');

/// Returns the path of file with individual keys
Future<String> getIndKeyPath() async =>
    [await AppInfo.canonicalName, encDir, indKeyFile].join('/');

/// Returns the path of file with public keys
Future<String> getPubKeyPath() async =>
    [await AppInfo.canonicalName, sharingDir, pubKeyFile].join('/');

/// Returns the path of the data directory
Future<String> getDataDirPath() async =>
    [await AppInfo.canonicalName, dataDir].join('/');

/// Extract the app name and the version from the package info
/// Return a record (with named fields https://dart.dev/language/records)

Future<({String name, String version})> getAppNameVersion() async =>
    (name: await AppInfo.name, version: await AppInfo.version);

/// Check whether a user is logged in or not
///
/// Check if the local storage has authentication
/// details of the user and also check whether the
/// access token is expired or not
/// returns boolean

Future<bool> checkLoggedIn() async {
  final webId = await getWebId();

  if (webId != null && webId.isNotEmpty) {
    final accessToken = await AuthDataManager.getAccessToken();
    if (accessToken != null && !JwtDecoder.isExpired(accessToken)) {
      return true;
    }
  }

  return false;
}

/// Delete login information from the local storage
///
/// returns true if successful

Future<bool> deleteLogIn() async {
  const success = true;
  try {
    await secureStorage.delete(key: webIdSecureStorageKey);
  } on Exception {
    return false;
  }
  return success && (await AuthDataManager.removeAuthData());
}

/// Save the webId to local secure storage

Future<void> saveWebId(String webId) async =>
    writeToSecureStorage(webIdSecureStorageKey, webId);

/// Get the webId from local secure storage

Future<String?> getWebId() async =>
    secureStorage.read(key: webIdSecureStorageKey);

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<List<String>> generateDefaultFolders() async {
  final appName = await AppInfo.canonicalName;
  final mainResDir = appName;

  final dataDirLoc = [mainResDir, dataDir].join('/');
  final sharingDirLoc = [mainResDir, sharingDir].join('/');
  final sharedDirLoc = [mainResDir, sharedDir].join('/');
  final encDirLoc = [mainResDir, encDir].join('/');
  final logDirLoc = [mainResDir, logsDir].join('/');

  final folders = [
    mainResDir,
    sharingDirLoc,
    sharedDirLoc,
    dataDirLoc,
    encDirLoc,
    logDirLoc,
  ];
  return folders;
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<Map<dynamic, dynamic>> generateDefaultFiles() async {
  final appName = await AppInfo.canonicalName;
  final mainResDir = appName;

  const encKeyFile = 'enc-keys.ttl';
  const pubKeyFile = 'public-key.ttl';
  const indKeyFile = 'ind-keys.ttl';
  const permLogFile = 'permissions-log.ttl';

  final sharingDirLoc = [mainResDir, sharingDir].join('/');
  final sharedDirLoc = [mainResDir, sharedDir].join('/');
  final encDirLoc = [mainResDir, encDir].join('/');
  final logDirLoc = [mainResDir, logsDir].join('/');

  final files = {
    sharingDirLoc: [
      pubKeyFile,
      '$pubKeyFile.acl',
    ],
    logDirLoc: [
      permLogFile,
      '$permLogFile.acl',
    ],
    sharedDirLoc: ['.acl'],
    encDirLoc: [encKeyFile, indKeyFile],
  };
  return files;
}

/// Logging out the user
Future<bool> logoutPod() async {
  final logoutUrl = await AuthDataManager.getLogoutUrl();
  if (logoutUrl != null) {
    try {
      return (await AuthDataManager.removeAuthData()) &&
          (await logout(logoutUrl));

      // final uri = Uri.parse(logoutUrl);
      // if (await canLaunchUrl(uri)) {
      //   return (await AuthDataManager.removeAuthData()) &&
      //       (await launchUrl(uri));
      // }
    } on Exception catch (e) {
      print('Exception: $e');
      return false;
    }
  }
  return true;
}
