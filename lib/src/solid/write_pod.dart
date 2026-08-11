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

import 'dart:convert' show utf8;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart' show Key;
import 'package:mime/mime.dart' as mime;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/check_encryption.dart'
    show isContentEncrypted;
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/io_helper.dart';
import 'package:solidpod/src/solid/utils/key_inheritance.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/permission.dart'
    show genAclTurtle, hasPublicOrAuthUserGrant;
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
/// - [encrypted]: Whether to encrypt the file content. Defaults to `null`,
///     meaning "not specified by the caller": for a new file (or when
///     [overwrite] is false) this behaves as `true`; when [overwrite] is true
///     and the file already exists, the file's *current* at-rest state on the
///     server is mirrored instead (plaintext stays plaintext, ciphertext stays
///     ciphertext). This matters for a resource that was decrypted in place
///     for Public/Authenticated User sharing (see `decryptFileInPlace`) —
///     without this, an unrelated edit would silently re-encrypt it and break
///     that sharing grant, since a class-based ACL grant has no key to
///     decrypt with.
///
///     Passing `true`/`false` explicitly (or setting [inheritKeyFrom])
///     overrides the mirroring above and forces that encryption state,
///     because some callers genuinely need to — e.g. toggling a resource's
///     privacy, or restoring a backed-up encryption state. Leave [encrypted]
///     unset whenever you're only touching content and not intentionally
///     changing whether it's encrypted. If forcing encryption would break an
///     active Public/Authenticated sharing grant (i.e. the resource's ACL
///     still grants that class access), the call throws
///     [PublicShareEncryptionConflictException] instead of silently
///     stranding the grant — call `revokePermission` to remove the grant
///     first (it handles re-encrypting the resource itself).
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
  bool? encrypted,
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

  final status = await checkResourceStatus(fileUrl);

  // Resolve the effective encryption flag. When the caller didn't specify
  // [encrypted] and this is an overwrite of an existing file, mirror the
  // file's current at-rest state instead of assuming `true` — otherwise an
  // unrelated edit would silently re-encrypt a file that was deliberately
  // decrypted in place for Public/Authenticated User sharing (see
  // `decryptFileInPlace`), stranding a resource whose ACL still promises
  // open access but whose bytes no longer are.

  var resolvedEncrypted = encrypted ?? true;
  if (encrypted == null &&
      inheritKeyFrom == null &&
      overwrite &&
      status == ResourceStatus.exist) {
    final currentContent = utf8.decode(await getResource(fileUrl));
    // Determine current encryption state
    resolvedEncrypted =
        isContentEncrypted(fileUrl: fileUrl, content: currentContent);
  }

  // Refuse to write ciphertext over a resource whose ACL still grants the
  // Public or Authenticated User agent class access. That grant only works
  // while the resource stays plaintext (those agent classes cannot be
  // issued an individual decryption key), so a resource in this state was
  // deliberately decrypted in place for sharing (see `decryptFileInPlace`).
  // This only fires when [resolvedEncrypted] was forced to `true` by an
  // explicit `encrypted: true` or by [inheritKeyFrom] — the auto-detect
  // path above already mirrors the resource's actual current state, so it
  // never trips this for a resource that's genuinely still plaintext.

  if (overwrite &&
      status == ResourceStatus.exist &&
      (resolvedEncrypted || inheritKeyFrom != null) &&
      await hasPublicOrAuthUserGrant(fileUrl)) {
    throw PublicShareEncryptionConflictException(
      'Refusing to write encrypted content to "$filePath": its ACL grants '
      'Public/Authenticated User access, which requires the resource to '
      'stay plaintext. Call revokePermission() to remove that grant '
      '(it re-encrypts the resource as part of revocation), or omit '
      '"encrypted" (or pass encrypted: false) to preserve its current '
      'plaintext state.',
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

  if (resolvedEncrypted || inheritKeyFrom != null) {
    if (!fileUrl.endsWith('.ttl')) {
      throw Exception(
        'Encrypted text file should be in turtle format, '
        'but the extension of provided filename "$filePath" is not ".ttl"',
      );
    }

    encKey = await configureEncKey(fileUrl, inheritKeyUrl: inheritKeyUrl);
  }

  switch (status) {
    case ResourceStatus.exist:
      if (overwrite) {
        debugPrint('NOTE: Overwriting existing file "$filePath"');
      } else {
        throw Exception(
          'File "$filePath" already exists and '
          'overwrite=$overwrite, writePod() aborted',
        );
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
      : await getEncTTLStrWithRandomIV(
          fileUrl: fileUrl,
          fileContent: fileContent,
          key: encKey,
          inheritKeyFrom: inheritKeyFrom == null
              ? null
              : await extractResourcePathFromUrl(inheritKeyUrl!),
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
