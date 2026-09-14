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

import 'package:encrypter_plus/encrypter_plus.dart' show Key;
import 'package:mime/mime.dart' as mime;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/io_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show genRandIndividualKey;
import 'package:solidpod/src/solid/utils/key_inheritance.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/write_external_pod.dart'
    show writeExternalPod;

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
/// - [overwrite]: Whether to overwrite the content of an existing file (default: false)
/// - [pathType]: Optional type of relative path (for both [filePath] and [inheritKeyFrom])
///     to override the default (relative to `appname/data` directory)
/// - [inheritKeyFrom] - Optional parameter to set a parent directory for the key to
///     be inherited from. If this is set, then
///     1. a single encryption key associated with the given directory is used to
///        encrypt the resource.
///     2. [fileContent] will be encrypted regardless of [encrypted] is True or False.
/// - [ownerWebId] - Optional WebID of the POD owner. When provided and it differs
///     from the current user's WebID, the content is written to that owner's
///     (external) POD via [writeExternalPod] instead of the current user's own
///     POD. In that case the resource inherits the ACL of the shared parent
///     directory (no separate ACL is created, so [createAcl] is ignored), and an
///     [AccessForbiddenException] is thrown if the user lacks write permission.
///     This makes writePod the single entry point for writing to own and
///     external PODs; [writeExternalPod] remains available for direct use.

Future<void> writePod(
  String filePath,
  String fileContent, {
  bool encrypted = true,
  bool createAcl = true,
  bool overwrite = false,
  PathType pathType = PathType.relativeToData,
  String? inheritKeyFrom,
  String? ownerWebId,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to write to POD');
  }

  // When [ownerWebId] names another user's POD, delegate to the external-POD
  // write path. It uses the shared encryption key, never creates an ACL (the
  // resource inherits the shared parent directory's ACL), and throws
  // AccessForbiddenException if the user lacks write permission.

  if (await isExternalOwner(ownerWebId)) {
    final externalFileUrl = await generateResourceUrlFromPath(
      resourcePath: filePath,
      pathType: pathType,
      webId: ownerWebId,
    );
    await writeExternalPod(
      externalFileUrl,
      fileContent,
      ownerWebId!, // Non-null because isExternalOwner() returned true.
      encrypted: encrypted,
      overwrite: overwrite,
      inheritKeyFrom: inheritKeyFrom,
    );
    return;
  }

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

  if (inheritKeyFrom != null &&
      !validateInheritKeyPath(inheritKeyFrom, pathType: pathType)) {
    throw Exception(
      'inheritKeyFrom="$inheritKeyFrom" is not valid w.r.t. pathType="$pathType"',
    );
  }

  Key? encKey;
  String? inheritKeyUrl;
  if (inheritKeyFrom != null) {
    inheritKeyUrl = await generateResourceUrlFromPath(
      resourcePath: inheritKeyFrom,
      pathType: pathType,
      isFile: false,
    );
  }

  if (encrypted || inheritKeyFrom != null) {
    if (!fileUrl.endsWith('.ttl')) {
      throw Exception(
        'Encrypted text file should be in turtle format, '
        'but the extension of provided filename "$filePath" is not ".ttl"',
      );
    }

    encKey = await configureEncKey(fileUrl, inheritKeyUrl: inheritKeyUrl);
  }

  // Whether the file is known not to exist yet. Only meaningful when we
  // actually probed for it below; null means "not checked".

  bool? fileExisted;

  // With overwrite=true the PUT below replaces whatever is there, so probing
  // first only costs a round trip (and, before checkResourceStatus grew a
  // HEAD path, a full download of the file we are about to replace). A 403
  // still surfaces as AccessForbiddenException, raised by createResource().

  if (!overwrite) {
    switch (await checkResourceStatus(fileUrl, useHead: true)) {
      case ResourceStatus.exist:
        throw Exception(
          'File "$filePath" already exists and '
          'overwrite=$overwrite, writePod() aborted',
        );

      case ResourceStatus.unknown:
        throw Exception(
          'Unable to determine if file "$fileUrl" exists, writePod() aborted',
        );

      case ResourceStatus.forbidden:
        throw AccessForbiddenException(
          'Access to file "$fileUrl" is forbidden, writePod() aborted',
        );

      case ResourceStatus.notExist:
        fileExisted = false;
    }
  }

  final content = encKey == null
      ? fileContent
      : await getEncTTLStrWithRandomIV(
          fileUrl: fileUrl,
          fileContent: fileContent,
          key: encKey,
          inheritKeyFrom: inheritKeyFrom == null
              ? null
              : await extractResourcePathFromUrl(inheritKeyUrl!),
        );

  // Create file on server

  final writeStatus = await createResource(
    fileUrl,
    content: content,
    contentType: encKey == null
        ? ResourceContentType.auto
        : ResourceContentType.turtleText,
  );

  // Create the ACL file for the data file if necessary.

  if (createAcl) {
    final aclFileUrl = '$fileUrl.acl';

    // When the data file did not exist a moment ago, neither does its ACL, so
    // the probe can be skipped. We know that either because we checked above
    // (overwrite=false) or because the server answered the PUT with 201
    // Created. Servers that answer 200 for a newly created resource simply
    // fall back to the probe, which is correct, just one round trip slower.

    final isNewFile = fileExisted == false || writeStatus == 201;

    if (isNewFile ||
        await checkResourceStatus(aclFileUrl, useHead: true) ==
            ResourceStatus.notExist) {
      await createResource(aclFileUrl, content: await genAclTurtle(fileUrl));
    }
  }
}

/// Register encryption keys for [filePaths] up front, in a single request.
///
/// [writePod] gives every encrypted file its own individual key and stores all
/// of them in one file, `encryption/ind-keys.ttl`, which has to be rewritten
/// in full whenever a key is added. Writing a batch of files one by one
/// therefore re-uploads that file once per file, and it carries an entry for
/// every encrypted file in the POD — so importing N records uploads O(N^2)
/// bytes of key material on top of the data itself, and gets slower the more
/// data the POD already holds.
///
/// Calling this first adds all the missing keys in one go. The subsequent
/// [writePod] calls then find their key already registered and skip the key
/// file entirely, which also makes them independent of each other and safe to
/// run concurrently.
///
/// Paths are interpreted exactly as [writePod] interprets its `filePath`, so
/// pass the same values (and the same [pathType]). Paths that already have a
/// key are skipped. A key registered here for a file that is never written is
/// harmless: it is simply unused.

Future<void> prepareEncryptionKeys(
  List<String> filePaths, {
  PathType pathType = PathType.relativeToData,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to write to POD');
  }

  final newKeys = <String, Key>{};

  for (final filePath in filePaths) {
    final fileUrl = await generateResourceUrlFromPath(
      resourcePath: filePath,
      pathType: pathType,
    );

    if (await KeyManager.hasIndividualKey(fileUrl)) {
      continue;
    }

    final resourcePath = await extractResourcePathFromUrl(fileUrl);

    // Guard against duplicates within [filePaths] itself: two entries for the
    // same file would otherwise generate two keys, the second of which would
    // not match content encrypted with the first.

    newKeys.putIfAbsent(resourcePath, genRandIndividualKey);
  }

  await KeyManager.addIndividualKeys(indKeys: newKeys);
}
