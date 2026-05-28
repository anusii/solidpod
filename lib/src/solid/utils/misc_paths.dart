/// Path-related helpers used across the package.
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

import 'package:path/path.dart' as path;

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';

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
