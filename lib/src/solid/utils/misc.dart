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
import 'package:fast_rsa/fast_rsa.dart' show KeyPair;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path/path.dart' as path;
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart' show genDpopToken, logout;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/revoke_permission_to_recipients.dart';
import 'package:solidpod/src/solid/utils/app_info.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/init_helper.dart';
import 'package:solidpod/src/solid/utils/io_helper.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/permission.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Global callback for clearing application-specific caches during logout.
/// Apps should register their cache clearing logic here.
/// This ensures caches are cleared BEFORE any blocking network operations.
Future<void> Function()? _onLogoutClearCaches;

/// Register a callback to clear application-specific caches during logout.
/// This callback will be invoked BEFORE the OAuth2 logout endpoint call,
/// preventing race conditions where cached data might be visible during logout.
void registerLogoutCacheCallback(Future<void> Function() callback) {
  _onLogoutClearCaches = callback;
}

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

/// Load and parse a private TTL file from POD
// Future<Map<String, dynamic>> loadPrvTTL(String fileUrl) async {
//   // final fileUrl = await getFileUrl(filePath);
//   try {
//     if (await checkResourceStatus(fileUrl) == ResourceStatus.exist) {
//       final rawContent = await fetchPrvFile(fileUrl);
//       return parseTTL(rawContent);
//     } else {
//       return {};
//     }
//   } on Exception catch (e) {
//     throw Exception(e);
//   }
// }

/// Read the encryption key file content for display purposes.
///
/// This function directly reads the encryption key file without using readPod,
/// making it suitable for accessing files outside the appname/data directory.
///
/// Returns the raw TTL content of the encryption key file.
// Future<String> readEncryptionKeyContent() async {
//   final encKeyPath = await getEncKeyPath();
//   final encKeyUrl = await getFileUrl(encKeyPath);

//   try {
//     if (await checkResourceStatus(encKeyUrl) == ResourceStatus.exist) {
//       return utf8.decode(
//         await getResource(encKeyUrl),
//       );

//       return await fetchPrvFile(encKeyUrl);
//     } else {
//       throw Exception('Encryption key file does not exist at: $encKeyPath');
//     }
//   } on Exception catch (e) {
//     throw Exception('Failed to read encryption key file: $e');
//   }
// }

/// Encrypt a given data string and format to TTL
Future<String> getEncTTLStr({
  required String fileUrl,
  required String fileContent,
  required Key key,
  required IV iv,
  String? inheritKeyFrom,
}) async {
  final filePath = await extractResourcePathFromUrl(fileUrl);
  final triples = {
    URIRef(fileUrl): {
      solidTermsNS.ns.withAttr(pathPred): filePath,
      solidTermsNS.ns.withAttr(ivPred): iv.base64,
      if (inheritKeyFrom != null)
        solidTermsNS.ns.withAttr(inheritKeyPred): inheritKeyFrom,
      solidTermsNS.ns.withAttr(encDataPred): encryptData(fileContent, key, iv),
    },
  };

  final bindNS = {solidTermsNS.prefix: solidTermsNS.ns};

  return tripleMapToTurtle(triples, bindNamespaces: bindNS);
}

/// Returns the path of file with verification key and private key
Future<String> getEncKeyPath() async =>
    [appDirName, encDir, encKeyFile].join('/');

/// Returns the path of file with individual keys
Future<String> getIndKeyPath() async =>
    [appDirName, encDir, indKeyFile].join('/');

/// Returns the path of file with public keys
Future<String> getPubKeyPath() async =>
    [appDirName, sharingDir, pubKeyFile].join('/');

/// Returns the path of public file with individual keys
Future<String> getPubIndKeyPath() async =>
    [appDirName, sharingDir, pubIndKeyFile].join('/');

/// Returns the path of file with individual keys accessed only
/// by authenticated users
Future<String> getAuthUserIndKeyPath() async =>
    [appDirName, sharingDir, authUserIndKeyFile].join('/');

/// Returns the path of the data directory
Future<String> getDataDirPath() async => [appDirName, dataDir].join('/');

/// Returns the path of the shared directory
Future<String> getSharedDirPath() async => [appDirName, sharedDir].join('/');

/// Returns the path of the file with shared individual keys
Future<String> getSharedKeyFilePath() async =>
    [appDirName, sharedDir, sharedKeyFile].join('/');

/// Returns the path of the encryption directory
Future<String> getEncDirPath() async => [appDirName, encDir].join('/');

/// Returns the path of the encryption directory
Future<String> getPermLogFilePath() async =>
    [appDirName, logsDir, permLogFile].join('/');

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

Future<bool> isUserLoggedIn() async {
  final webId = await AuthDataManager.getWebId();

  if (webId != null && webId.isNotEmpty) {
    final accessToken = await AuthDataManager.getAccessToken();
    if (accessToken != null && !JwtDecoder.isExpired(accessToken)) {
      return true;
    }
  }

  return false;
}

/// Create a directory with the given URL

Future<void> createDir(String dirUrl) async {
  assert(dirUrl.endsWith('/'));
  await createResource(
    dirUrl,
    isFile: false,
    replaceIfExist: false,
    contentType: ResourceContentType.directory,
  );
}

/// Delete login information from the local storage
///
/// returns true if successful

Future<bool> deleteLogIn() async => AuthDataManager.removeAuthData();

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

  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];

  return (
    accessToken: authData['accessToken'] as String,
    dPopToken: genDpopToken(resourceUrl, rsaKeyPair, publicKeyJwk, httpMethod),
  );
}

/// Logging out the user with comprehensive error handling and platform support
///
/// This function performs a complete logout that includes:
/// 1. Clearing all encryption keys from memory
/// 2. Removing authentication data from secure storage
/// 3. Calling the OAuth2 logout endpoint (with error tolerance on web)
///
/// Returns true if logout succeeds or critical operations complete,
/// false only if critical operations (key/auth cleanup) fail.
Future<bool> logoutPod() async {
  try {
    // Step 1: Clear all cached encryption keys and security data from memory
    // This is CRITICAL and must be done regardless of other failures
    await KeyManager.clear();
    debugPrint('logoutPod() => KeyManager.clear() completed');

    // Step 2: Remove authentication data from secure storage
    // This is CRITICAL - must succeed
    final authDataRemoved = await AuthDataManager.removeAuthData();
    if (!authDataRemoved) {
      debugPrint(
        'logoutPod() => WARNING: AuthDataManager.removeAuthData() failed',
      );
      // Don't return false yet - logout endpoint is still needed
    }

    // Step 2.5: Clear application-specific caches BEFORE network call
    // This is CRITICAL to prevent race conditions where UI reads stale cache
    // during logout, especially when network is slow
    if (_onLogoutClearCaches != null) {
      try {
        await _onLogoutClearCaches!();
      } on Object catch (e) {
        debugPrint(
          'logoutPod() => WARNING: Application cache callback failed (non-critical): $e',
        );
        // Continue - the critical auth data is already cleared
      }
    } else {
      debugPrint('logoutPod() => No application cache callback registered');
    }

    // Step 3: Get the logout URL and attempt OAuth2 logout
    // This is OPTIONAL - should not block if it fails
    final logoutUrl = await AuthDataManager.getLogoutUrl();
    if (logoutUrl != null && logoutUrl.isNotEmpty) {
      try {
        // Call the OAuth2 logout endpoint
        // On web, this may fail with platform-related exceptions, but we continue anyway
        await logout(logoutUrl);
        debugPrint('logoutPod() => OAuth2 logout endpoint called successfully');
      } on Object catch (e) {
        // On Flutter Web, platform-related exceptions might occur
        // This is NOT a critical failure - the local session is already cleared
        debugPrint('logoutPod() => OAuth2 logout warning (non-critical): $e');
        // Continue - local data is already cleared which is most important
      }
    } else {
      debugPrint(
        'logoutPod() => No logout URL available, skipping OAuth2 logout',
      );
    }

    // Success if we cleared the local data (most important part)
    return authDataRemoved;
  } on Object catch (e) {
    // Catch any remaining exceptions
    debugPrint('logoutPod() => CRITICAL ERROR: $e');
    // Even if we reach here, attempt to clear auth data as fallback
    try {
      await AuthDataManager.removeAuthData();
      await KeyManager.clear();
    } catch (fallbackError) {
      debugPrint('logoutPod() => Fallback cleanup also failed: $fallbackError');
    }
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

/// Initialise the directory and file structure in a POD

Future<void> initPod(
  String securityKey, {
  List<String>? dirUrls,
  List<String>? fileUrls,
}) async {
  // Check if the user has logged in

  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('Can not initialise POD without logging in');
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
      isFile: false,
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
      var isFile = true;
      switch (fileName) {
        case '$pubKeyFile.acl':
          publicAccess = {AccessMode.read};
        case '$permLogFile.acl':
          publicAccess = {AccessMode.append};
        default:
          assert(fileName == '.acl');
          publicAccess = {AccessMode.read, AccessMode.write};
          isFile = false;
      }

      fileContent = await genAclTurtle(
        resourceUrl,
        isFile: isFile,
        publicAccess: publicAccess,
      );

      aclFlag = true;
    } else {
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

    case ResourceStatus.forbidden:
      debugPrint(
        'Access to ACL file "$aclUrl" for "$resourceUrl" is forbidden.',
      );

    case ResourceStatus.notExist:
      debugPrint('ACL file "$aclUrl" for "$resourceUrl" does not exist.');

    case ResourceStatus.unknown:
      throw Exception(
        'Error occurred when checking status of ACL file "$aclUrl" for "$resourceUrl"',
      );
  }
}

/// Delete a file and its associated resources, after first revoking
/// external access to the file. The file with path [filePath],
/// its ACL file, and its encryption key (if exists) will be deleted.
/// The permission logs of any recipients to the file, will also be
/// updated with a log line recording that permissions have been
/// revoked.
/// Throws an exception if the file does not exist or any error occurs.
///
/// Arguments:
///
/// - [filePath] - path of file to be deleted. Where [filePath] is the
/// app data directory and the filename.
/// - [contentType] - the type of content of the resource. Default:
/// [ResourceContentType.turtleText].
/// - [isKey] - flag describing whether the file to be deleted is a
/// security key. Use this flag if file is a security key to avoid
/// unnecessary operations that are not needed to delete a key.

Future<void> deleteFile(
  String filePath, {
  ResourceContentType contentType = ResourceContentType.turtleText,
  bool isKey = false,
}) async {
  final fileUrl = await getFileUrl(filePath);
  if (await isFileProtected(fileUrl)) {
    throw Exception('Delete protected file is not allowed');
  }
  if (!isKey) {
    // File to be deleted != key => perform all steps

    // Revoke permission to recipients:
    // to avoid the permission log of recipients still
    // showing the recipient as having access to the
    // file that is being deleted.
    // 20260112 jesscmoore: Assumes user is owner which is
    // always true in deleteFile().
    await revokePermissionToRecipients(fileName: filePath);

    await deleteResource(fileUrl, contentType);
    await deleteAclForResource(fileUrl);
    await KeyManager.removeIndividualKey(resourcePath: filePath);
  } else {
    // File to be deleted == key => perform delete only
    await deleteResource(fileUrl, contentType);
  }
}

/// Delete an external file with path [fileUrl] and the shared key
/// if the file is encrypted.
/// Throws an exception if the file does not exist or any error occurs.
Future<void> deleteExternalFile(
  String fileUrl, {
  ResourceContentType contentType = ResourceContentType.turtleText,
}) async {
  await deleteResource(fileUrl, contentType);
  await deleteAclForResource(fileUrl);
  await KeyManager.removeSharedIndividualKey(fileUrl);

  /// av: Need to add the funtionality to remove the log line from permission
  /// log. Otherwise, it will give an error.
}

/// Get date and time from a string
String getDateTime(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a');

  return dateFormat.format(dateTime);
}

/// Normalise file path for readPod/writePod operations.
///
/// Handles backward compatibility by checking if the filePath already includes
/// the app directory prefix, and constructs the appropriate normalised path.
///
/// When basePath is null (default for readPod/writePod), uses appname/data as base path.
///
/// [filePath] - The input file path
/// [basePath] - The base path to use (defaults to appname/data when null)
///
/// Returns the normalised file path.
///
/// Examples:
/// - `normalizeFilePath('abc.ttl', null)` returns `appname/data/abc.ttl`
/// - `normalizeFilePath('movies/abc.ttl', null)` returns `appname/data/movies/abc.ttl`
/// - `normalizeFilePath('appname/data/keys.ttl', null)` returns `appname/data/keys.ttl`
///
/// Note: Only `appname/data/` paths are supported for readPod/writePod operations.

Future<String> normalizeFilePath(String filePath, String? basePath) async {
  // Normalise path separators for cross-platform compatibility.

  final normalizedInput = filePath.replaceAll(path.separator, '/');

  // Use provided path or default to appname/data.

  final effectiveBasePath = basePath == null || basePath.trim().isEmpty
      ? await getDataDirPath()
      : basePath;

  // Check if path already starts with the correct base path (appname/data/).

  if (normalizedInput.startsWith(effectiveBasePath)) {
    // Full path is already prepended (appname/data/).

    return normalizedInput;
  } else {
    // Prepend the base path.

    return [effectiveBasePath, normalizedInput].join('/');
  }
}

/// Check if a given path string is a directory or not
bool isDir(String path) {
  if (path.endsWith('/') || !path.contains('.')) {
    return true;
  } else {
    return false;
  }
}

/// Generate the URL of resource according to its path and the type of the path.

Future<String> generateResourceUrlFromPath({
  required String resourcePath,
  required PathType pathType,
  bool isFile = true,
  String? webId,
}) async {
  final func = isFile ? getFileUrl : getDirUrl;
  switch (pathType) {
    case PathType.absoluteUrl:
      return resourcePath;

    case PathType.relativeToPod:
      return await func(resourcePath, webId: webId);

    case PathType.relativeToApp:
      return await func([appDirName, resourcePath].join('/'), webId: webId);

    case PathType.relativeToData:
      return await func(
        [await getDataDirPath(), resourcePath].join('/'),
        webId: webId,
      );
  }
}

/// Extract resource path from its URL
/// path format:
/// - appDir/path/to/file
/// - appDir/path/to/dir/

Future<String> extractResourcePathFromUrl(
  String resourceUrl, {
  bool isFile = true,
}) async {
  // See https://api.dart.dev/dart-core/Uri-class.html for details

  final segments = Uri.parse(resourceUrl).pathSegments;

  final path = segments.getRange(1, segments.length).join('/');

  return !(isFile || path.endsWith('/')) ? '$path/' : path;
}

/// Generate the Web ID of from resource URL

Future<String> generateWebIdFromResourceUrl(String resourceUrl) async {
  final uri = Uri.parse(resourceUrl);
  return [uri.origin, uri.pathSegments.first, profCard].join('/');
}
