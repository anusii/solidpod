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

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/app_info.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
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

/// Checks whether a POD-relative [resourcePath] falls within the current
/// application's directory tree.
///
/// Returns `true` if the resource belongs to this app, meaning the app
/// holds the encryption key required to decrypt it. Returns `false` if
/// the resource belongs to another application's folder, in which case
/// decryption may not be possible.
///
/// [resourcePath] should be a normalised POD-relative path (e.g.
/// `myapp/data/file.ttl`). Absolute URLs or empty strings return `false`.

Future<bool> isPathInCurrentApp(String resourcePath) async {
  try {
    if (resourcePath.trim().isEmpty) return false;

    if (resourcePath.startsWith('http://') ||
        resourcePath.startsWith('https://')) {
      debugPrint(
        'isPathInCurrentApp: expected a POD-relative path but received '
        'an absolute URL: $resourcePath',
      );
      return false;
    }

    // Derive the current app name from getDataDirPath() which returns
    // "APP_NAME/data". The first segment is the app name.

    final appDataPath = await getDataDirPath();
    if (appDataPath.isEmpty) return false;

    final currentAppName = appDataPath.split('/').first;
    if (currentAppName.isEmpty) return false;

    // Build full URLs for both the resource and the app root, then
    // compare prefixes. getDirUrl appends a trailing slash which
    // prevents false positives (e.g. "myapp2" matching "myapp").

    final resourceUrl = await getFileUrl(resourcePath);
    final appRootUrl = await getDirUrl(currentAppName);

    return resourceUrl.startsWith(appRootUrl);
  } catch (e) {
    debugPrint('Error in isPathInCurrentApp: $e');
    return false;
  }
}

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

/// Create a directory with the given URL.

Future<void> createDir(String dirUrl) async {
  assert(dirUrl.endsWith('/'));
  await createResource(
    dirUrl,
    isFile: false,
    replaceIfExist: false,
    contentType: ResourceContentType.directory,
  );
}

/// Characters that are forbidden in container (folder) names.
///
/// These characters are either URL-unsafe (causing percent-encoding issues
/// such as spaces becoming `%20`) or filesystem-unsafe on common platforms.

final RegExp _invalidContainerNameChars = RegExp(
  r'''[ /#?%&+@=<>"|*:!\\]''',
);

/// Validates that [folderName] is a safe container name.
///
/// Throws [ArgumentError] if the name is empty, starts with a dot, or
/// contains characters that would be percent-encoded in a URL or are
/// otherwise unsafe for use as a directory name.

void validateContainerName(String folderName) {
  if (folderName.trim().isEmpty) {
    throw ArgumentError('Folder name cannot be empty.');
  }
  if (folderName.startsWith('.')) {
    throw ArgumentError('Folder name cannot start with a dot.');
  }
  final match = _invalidContainerNameChars.firstMatch(folderName);
  if (match != null) {
    final char = match.group(0);
    final label = char == ' ' ? 'spaces' : '"$char"';
    throw ArgumentError(
      'Folder name cannot contain $label. '
      'Avoid spaces and special characters: '
      r'/ \ # ? % & + @ = < > " | * : !',
    );
  }
}

/// Creates a new container (directory) on the POD from a relative path.
///
/// Combines [parentPath] and [folderName] into a relative path, resolves
/// the full directory URL via [getDirUrl], and creates the container.
///
/// [parentPath] is the normalised relative path to the parent directory
/// (e.g. `'myapp/data'` or `''` for the POD root).
///
/// [folderName] is the name of the new directory to create. It must not
/// contain spaces or URL/filesystem-unsafe characters (see
/// [validateContainerName]).
///
/// Throws [ArgumentError] if the name is invalid, or an [Exception] if
/// the directory already exists or a network error occurs.

Future<void> createContainer(String parentPath, String folderName) async {
  // Validate the folder name before making any network calls.

  validateContainerName(folderName);

  // Combine parent path and folder name, handling empty parent (POD root).

  final folderPath =
      parentPath.isEmpty ? folderName : '$parentPath/$folderName';
  final dirUrl = await getDirUrl(folderPath);
  await createDir(dirUrl);
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
