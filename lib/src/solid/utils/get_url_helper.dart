/// Get URLs related utility functions used across the package.
///
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage, Dawei Chen

library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Generate unique ID for the resource URL
/// In order for the ID to be unique across all webIDs and no one can
/// reverse engineer the resource being shared we also use receiver webId
/// in the ID generation process
String getUniqueIdResUrl(String resourceUrl, String receiverWebId) {
  return sha256.convert(utf8.encode(resourceUrl + receiverWebId)).toString();
}

/// From a given resource path [resourcePath] create its URL
/// [resourcePath] should be relative to the POD, e.g., `myapp/data/abc.ttl`.
/// [isFile] should be true if the resource is a file, otherwise false if it
/// is a directory.
/// [webId] (optionally) specifies the resource's POD (could be external).
/// returns the full resource URL

Future<String> _getResourceUrl(
  String resourcePath, {
  required bool isFile,
  String? webId,
}) async {
  final wId = webId ?? await AuthDataManager.getWebId();

  assert(wId != null);
  assert(wId!.contains(profCard));

  final resourceUrl = wId!.replaceAll(profCard, resourcePath);

  if (!isFile && !resourceUrl.endsWith('/')) {
    return '$resourceUrl/';
  }

  return resourceUrl;
}

/// Create the URL for a file
Future<String> getFileUrl(String filePath, {String? webId}) async =>
    await _getResourceUrl(filePath, isFile: true, webId: webId);

/// Create the URL for a directory (container)
Future<String> getDirUrl(String dirPath, {String? webId}) async =>
    await _getResourceUrl(dirPath, isFile: false, webId: webId);

/// Get resource Url from a filename, with different options for how
/// the filename is provided. If [isExternalRes] or [isFileUrl] is
/// set to true, the filename is already the resource url and is
/// returned unchanged.
///
/// Parameters:
/// - [fileName] - name of file of interest.
/// - [isFile] - flag describing whether the resources is a file or not.
/// If false the [fileName] is a directory. (Default: true).
/// - [isFilePath] - flag describing whether [fileName] includes the
/// directory data path. (Default: false).
/// - [isFileUrl] - flag describing whether [fileName] is the url of the
/// file. (Default: false).
/// - [isExternalRes] - flag describing whether the file is an external
/// file shared with the user. In which case the [fileName] should be
/// the full URL of the file. (Default: false).

Future<String> filenameToResourceUrl({
  required String fileName,
  bool isFile = true,
  bool isFileUrl = false,
  bool isExternalRes = false,
}) async {
  final String resourceUrl;
  final String filePath;

  // Note: external resources always specified by url
  if (isExternalRes) {
    isFileUrl = true;
  }

  // If not already a url, get url
  if (!isExternalRes && !isFileUrl) {
    // Get the file path
    // Ensure path uses correct path separators and
    // has app data dir prepended.
    filePath = await normalizeFilePath(fileName, null);

    // Get the url of the resource by prepending the
    // user = owner webID (excluding profCard)
    if (isFile) {
      resourceUrl = await getFileUrl(filePath);
    } else {
      resourceUrl = await getDirUrl(filePath);
    }
  } else {
    // Use fileName, fileName already the resource url
    resourceUrl = fileName;
  }

  return resourceUrl;
}

/// Derive external POD inherited parent directory url from the resource url
/// and parent directory path
String getExtDirUrl(String resourceUrl, String dirPath) {
  int pathIndex = resourceUrl.indexOf(dirPath);

  String dirUrl = '';
  if (pathIndex != -1) {
    dirUrl = resourceUrl.substring(0, pathIndex + dirPath.length);
    if (!dirUrl.endsWith('/')) {
      dirUrl += '/';
    }
  }

  return dirUrl;
}
