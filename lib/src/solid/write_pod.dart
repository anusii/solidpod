/// Function to write data to a private file in PODs.
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
/// Authors: Dawei Chen, Anushka Vidanage, Ashley Tang

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart' show Key;
import 'package:mime/mime.dart' as mime;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/io_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/key_inheritance.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;

/// Write [filePath] with content [fileContent] to POD in the
/// data directory (within potential subdirectories encoded in [filePath]).
/// [fileContent] will be encrypted by default.
///
/// Examples:
/// - `writePod('abc.ttl', content)` writes to `appname/data/abc.ttl`
/// - `writePod('movies/abc.ttl', content)` writes to `appname/data/movies/abc.ttl`
/// - `writePod('movies/classical/cde.ttl', content, inheritKeyFrom: 'movies/')`
///   writes to `appname/data/movies/classical/abc.ttl` and uses the encryption key
///   for `appname/data/movies/` to encrypt the content.
///
/// Arguments:
/// - [filePath]: The path (relative to appname/data/) of the file to write
/// - [fileContent]: The content to write to the file
/// - [encrypted]: Whether to encrypt the file content (default: true)
/// - [createAcl]: Whether to create a separate acl for the resource (default: true)
/// - [overwrite]: Whether to overwrite the content of an existing file (default: true)
/// - [pathType]: Optional type of file path (for both [filePath] and [inheritKeyFrom])
///     to override the default (relative to `appname/data` directory)
/// - [inheritKeyFrom] - Optional parameter to set a parent directory for the key to
///     be inherited from. If this is set
///     1. a single encryption key associated with the given directory is used to
///        encrypt the resource.
///     2. [fileContent] will be encrypted regardless of [encrypted] is True or False.
///     3. [inheritKeyFrom] is assumed to be a path relative to appname/data/

Future<void> writePod(
  String filePath,
  String fileContent, {
  bool encrypted = true,
  bool createAcl = true,
  bool overwrite = false,
  PathType pathType = PathType.relativeToData,
  String? inheritKeyFrom,
}) async {
  await checkLoggedIn(
    errorMessage: 'User must be logged in to write to POD',
  );

  final fileUrl = await generateResourceUrlFromPath(
    resourcePath: filePath,
    pathType: pathType,
  );

  if (await isFileProtected(fileUrl)) {
    throw Exception('Write to protected file is not allowed');
  }

  if (mime.lookupMimeType(fileUrl) == null) {
    throw Exception('Unable to determine content type of file $filePath');
  }

  Key? encKey;

  if (encrypted || inheritKeyFrom != null) {
    if (!fileUrl.endsWith('.ttl')) {
      throw Exception('Encrypted text file should be in turtle format, '
          'but the extension of provided filename "$filePath" is not ".ttl"');
    }

    encKey = await configureEncKey(fileUrl, inheritKeyFrom);
  }

  switch (await checkResourceStatus(fileUrl)) {
    case ResourceStatus.exist:
      if (overwrite) {
        debugPrint('WARNING: Overwrite existing file "$filePath"');
      } else {
        throw Exception('File "$filePath" already exists and '
            'overwrite=$overwrite, writePod() aborted');
      }

    case ResourceStatus.unknown:
      throw Exception(
        'Unable to determine if file "$fileUrl" exists, writePod() aborted',
      );

    case ResourceStatus.forbidden:
      throw AccessForbiddenException(
        'Access to file "$fileUrl" is forbidden, writePod() aborted',
      );

    case ResourceStatus.notExist: // Empty case falls through.
      // debugPrint('File "$fileUrl" does not exist');
      {}
  }

  final content = encKey == null
      ? fileContent
      : await getEncTTLStr(
          [await getDataDirPath(), filePath].join('/'),
          fileContent,
          encKey,
          genRandIV(),
          inheritKeyFrom: inheritKeyFrom == null
              ? null
              : [await getDataDirPath(), inheritKeyFrom].join('/'),
        );

  // Create file on server

  await createResource(
    fileUrl,
    content: content,
    contentType: encKey == null
        ? ResourceContentType.auto
        : ResourceContentType.turtleText,
  );

  // Create the ACL file for the data file if necessary

  if (createAcl) {
    final aclFileUrl = '$fileUrl.acl';
    if (await checkResourceStatus(aclFileUrl) == ResourceStatus.notExist) {
      await createResource(aclFileUrl, content: await genAclTurtle(fileUrl));
    }
  }
}
