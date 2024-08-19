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

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypt/encrypt.dart';
import 'package:fast_rsa/fast_rsa.dart' show KeyPair;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart' show genDpopToken, logout;
import 'package:crypto/crypto.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/app_info.dart' show AppInfo;
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/permission.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

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

/// Encrypt data using AES with the specified key
String encryptData(String data, Key key, IV iv, {AESMode mode = AESMode.sic}) =>
    Encrypter(AES(key, mode: mode)).encrypt(data, iv: iv).base64;

/// Decrypt a ciphertext value
String decryptData(
  String encData,
  Key key,
  IV iv, {
  AESMode mode = AESMode.sic,
}) =>
    Encrypter(AES(key, mode: mode)).decrypt(Encrypted.from64(encData), iv: iv);

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

/// Generates a public key block from a given key content.
String genPubKeyStr(String pubKeyContent) =>
    '''-----BEGIN RSA PUBLIC KEY-----\n$pubKeyContent\n-----END RSA PUBLIC KEY-----''';

/// Get unique bit of the webId
String getUniqueStrWebId(String webId) {
  var uniqueStr = webId.replaceAll('https://', '');
  uniqueStr = uniqueStr.replaceAll('http://', '');
  uniqueStr = uniqueStr.replaceAll('/$profCard', '');
  uniqueStr = uniqueStr.replaceAll('/', '-');

  return uniqueStr;
}

/// Generate unique ID for the resource URL
/// In order for the ID to be unique across all webIDs and no one can
/// reverse engineer the resource being shared we also use receiver webId
/// in the ID generation process
String getUniqueIdResUrl(String resourceUrl, String receiverWebId) {
  return sha256.convert(utf8.encode(resourceUrl + receiverWebId)).toString();
}

/// From a given resource path [resourcePath] create its URL
/// [isContainer] should be true if the resource is a directory, otherwise false
/// returns the full resource URL

Future<String> _getResourceUrl(
  String resourcePath,
  bool isContainer, [
  String? extWebId,
]) async {
  String? webId = '';
  // Check if resource url is needed for an external webId
  if (extWebId != null) {
    webId = extWebId;
  } else {
    webId = await AuthDataManager.getWebId();
  }
  assert(webId != null);
  assert(webId!.contains(profCard));
  final resourceUrl = webId!.replaceAll(profCard, resourcePath);
  if (isContainer && !resourceUrl.endsWith('/')) {
    return '$resourceUrl/';
  }

  return resourceUrl;
}

/// Create the URL for a file
Future<String> getFileUrl(String filePath, [String? extWebId]) async =>
    (extWebId == null)
        ? await _getResourceUrl(filePath, false)
        : await _getResourceUrl(filePath, false, extWebId);

/// Create the URL for a directory (container)
Future<String> getDirUrl(String dirPath, [String? extWebId]) async =>
    (extWebId == null)
        ? await _getResourceUrl(dirPath, true)
        : await _getResourceUrl(dirPath, true, extWebId);

/// Encrypt a given data string and format to TTL
Future<String> getEncTTLStr(
  String filePath,
  String fileContent,
  Key key,
  IV iv,
) async {
  final triples = {
    URIRef(await getFileUrl(filePath)): {
      solidTermsNS.ns.withAttr(pathPred): filePath,
      solidTermsNS.ns.withAttr(ivPred): iv.base64,
      solidTermsNS.ns.withAttr(encDataPred): encryptData(fileContent, key, iv),
    },
  };
  final bindNS = {solidTermsNS.prefix: solidTermsNS.ns};

  return tripleMapToTurtle(triples, bindNamespaces: bindNS);
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

/// Returns the path of public file with individual keys
Future<String> getPubIndKeyPath() async =>
    [await AppInfo.canonicalName, sharingDir, pubIndKeyFile].join('/');

/// Returns the path of file with individual keys accessed only
/// by authenticated users
Future<String> getAuthUserIndKeyPath() async =>
    [await AppInfo.canonicalName, sharingDir, authUserIndKeyFile].join('/');

/// Returns the path of the data directory
Future<String> getDataDirPath() async =>
    [await AppInfo.canonicalName, dataDir].join('/');

/// Returns the path of the shared directory
Future<String> getSharedDirPath() async =>
    [await AppInfo.canonicalName, sharedDir].join('/');

/// Returns the path of the shared directory
Future<String> getSharedKeyFilePath() async =>
    [await AppInfo.canonicalName, sharedDir, sharedKeyFile].join('/');

/// Returns the path of the encryption directory
Future<String> getEncDirPath() async =>
    [await AppInfo.canonicalName, encDir].join('/');

/// Returns the path of the encryption directory
Future<String> getPermLogFilePath() async =>
    [await AppInfo.canonicalName, logsDir, permLogFile].join('/');

/// Extract the app name and the version from the package info
/// Return a record (with named fields https://dart.dev/language/records)

Future<({String name, String version})> getAppNameVersion() async =>
    (name: await AppInfo.name, version: await AppInfo.version);

/// Return the web ID
Future<String?> getWebId() async => AuthDataManager.getWebId();

/// Check whether a user is logged in or not
///
/// Check if the local storage has authentication
/// details of the user and also check whether the
/// access token is expired or not
/// returns boolean

Future<bool> checkLoggedIn() async {
  final webId = await AuthDataManager.getWebId();

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

Future<bool> deleteLogIn() async => AuthDataManager.removeAuthData();

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<List<String>> generateDefaultFolders() async {
  final mainResDir = await AppInfo.canonicalName;

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
  final mainResDir = await AppInfo.canonicalName;

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

/// Get resource acl file path
String getResAclFile(String resourceUrl, [bool fileFlag = true]) {
  final resourceAclUrl = resourceUrl.endsWith('.acl')
      ? resourceUrl
      : fileFlag
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
  assert(authData != null);

  final rsaInfo = authData!['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];

  return (
    accessToken: authData['accessToken'] as String,
    dPopToken: genDpopToken(resourceUrl, rsaKeyPair, publicKeyJwk, httpMethod),
  );
}

/// Logging out the user
Future<bool> logoutPod() async {
  final logoutUrl = await AuthDataManager.getLogoutUrl();
  if (logoutUrl != null) {
    try {
      await KeyManager.clear();
      return (await AuthDataManager.removeAuthData()) &&
          (await logout(logoutUrl));
    } on Exception catch (e) {
      debugPrint('Exception: $e');
      return false;
    }
  }
  return true;
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

/// Initialise the directory and file structure in a POD

Future<void> initPod(
  String securityKey, {
  List<String>? dirUrls,
  List<String>? fileUrls,
}) async {
  // Check if the user has logged in

  final loggedIn = await checkLoggedIn();
  if (!loggedIn) {
    throw Exception('Can not initialise POD without logging in');
  }

  // Check (and generate) the directory URLs

  if (dirUrls == null || dirUrls.isEmpty) {
    final defaultDirs = await generateDefaultFolders();
    dirUrls = [for (final d in defaultDirs) await getDirUrl(d)];
  }

  // Require the creation of the encryption directory and
  // the encKeyFile and indKeyFile in it.
  // (The app asks for the security key, so this is a reasonable requirement?)

  final encDirUrl = await getDirUrl(await getEncDirPath());
  if (!dirUrls.contains(encDirUrl)) {
    throw Exception('Can not initialise POD without creating $encDirUrl');
  }

  // Create the required directories

  for (final d in dirUrls) {
    await createResource(
      d,
      fileFlag: false,
      contentType: ResourceContentType.directory,
    );
  }

  // Check (and generate) the file URLs

  if (fileUrls == null || fileUrls.isEmpty) {
    final defaultFiles = await generateDefaultFiles();
    fileUrls = <String>[];
    for (final entry in defaultFiles.entries) {
      final d = entry.key;
      for (final f in entry.value as List) {
        fileUrls.add([d, f].join('/'));
      }
    }
  }

  // Create the encKeyFile, indKeyFile and pubKeyFile
  // and remove them from the fileUrls list

  await KeyManager.initPodKeys(securityKey);
  fileUrls.remove(await getFileUrl(await getEncKeyPath()));
  fileUrls.remove(await getFileUrl(await getIndKeyPath()));
  fileUrls.remove(await getFileUrl(await getPubKeyPath()));

  for (final f in fileUrls) {
    final fileName = f.split('/').last;
    late String fileContent;
    late bool aclFlag;

    if (f.split('.').last == 'acl') {
      final items = f.split('.');
      final resourceUrl = items.getRange(0, items.length - 1).join('.');
      late Set<AccessMode> publicAccess;
      var fileFlag = true;
      switch (fileName) {
        case '$pubKeyFile.acl':
          publicAccess = {AccessMode.read};
        case '$permLogFile.acl':
          publicAccess = {AccessMode.append};
        default:
          debugPrint(fileName);
          assert(fileName == '.acl');
          publicAccess = {AccessMode.read, AccessMode.write};
          fileFlag = false;
      }

      fileContent = await genAclTurtle(
        resourceUrl,
        fileFlag: fileFlag,
        publicAccess: publicAccess,
      );

      aclFlag = true;
    } else {
      debugPrint(fileName);
      assert(fileName == permLogFile);
      fileContent = genPermLogTTLStr(f);
      aclFlag = false;
    }

    await createResource(f, content: fileContent, replaceIfExist: aclFlag);
  }
}

/// Delete the ACL file for a resource
Future<void> deleteAclForResource(String resourceUrl) async {
  final aclUrl = '$resourceUrl.acl';
  final status = await checkResourceStatus(aclUrl);

  switch (status) {
    case ResourceStatus.exist:
      await deleteResource(aclUrl, ResourceContentType.turtleText);

    case ResourceStatus.notExist:
      debugPrint('ACL file for "$resourceUrl" does not exist.');

    case ResourceStatus.unknown:
      throw Exception(
        'Error occurred when checking status of ACL file for "$resourceUrl"',
      );
  }
}

/// Delete a file with path [filePath], its ACL file, and its encryption key
/// if exists.
/// Throws an exception if the file does not exist or any error occurs.
Future<void> deleteFile(
  String filePath, {
  ResourceContentType contentType = ResourceContentType.turtleText,
}) async {
  final fileUrl = await getFileUrl(filePath);
  await deleteResource(fileUrl, contentType);
  await deleteAclForResource(fileUrl);
  if (await KeyManager.hasIndividualKey(fileUrl)) {
    await KeyManager.removeIndividualKey(filePath);
  }
}

/// Get date and time from a string
String getDateTime(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a');

  return dateFormat.format(dateTime);
}
