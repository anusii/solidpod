/// Helper functions to upload, download, and delete large files in PODs.
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
/// Authors: Dawei Chen, Anushka Vidanage

library;

import 'dart:async';
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:flutter/foundation.dart' hide Key;

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:rdflib/rdflib.dart' show Namespace, URIRef, Literal;
import 'package:universal_io/io.dart' show File;

import 'package:solidpod/src/solid/api/rest_api.dart'
    show createResource, checkResourceStatus, getResource, deleteResource;
import 'package:solidpod/src/solid/constants/common.dart'
    show ResourceContentType, ResourceStatus;
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/constants/schema.dart'
    show siiNS, SIIPredicate;
import 'package:solidpod/src/solid/read_external_pod.dart' show readExternalPod;
import 'package:solidpod/src/solid/read_pod.dart' show readPod;
import 'package:solidpod/src/solid/revoke_permission_to_recipients.dart'
    show revokePermissionToRecipients;
import 'package:solidpod/src/solid/utils/delete_helper.dart'
    show deleteAclForResource;
import 'package:solidpod/src/solid/utils/exceptions.dart'
    show NotLoggedInException;
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show genRandIndividualKey, genRandIV;
import 'package:solidpod/src/solid/utils/misc.dart' show getDataDirPath;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;
import 'package:solidpod/src/solid/utils/session.dart'
    show isUserLoggedIn, resolveExternalOwner;
import 'package:solidpod/src/solid/write_external_pod.dart'
    show writeExternalPod;
import 'package:solidpod/src/solid/write_pod.dart' show writePod;

/// Get a large file previously sent using [writeLargeFile] with name
/// [remoteFilePath] (relative to appname/data directory) and save it
/// to a local file with path [localFilePath].
///
/// Set [isPodRelativePath] to true when [remoteFilePath] is relative to the
/// POD root (e.g. `demopod/data/file.pdf`) rather than the current app's data
/// directory. This is required to read a large file from a POD whose
/// application directory differs from the current app (see [writeLargeFile]).
Future<void> readLargeFile({
  required String remoteFilePath,
  required String localFilePath,
  String? ownerWebId,
  bool isPodRelativePath = false,
  void Function(int, int)? onProgress,
}) async {
  final chunks = fetch(
    remoteFilePath: remoteFilePath,
    ownerWebId: ownerWebId,
    isPodRelativePath: isPodRelativePath,
    onProgress: onProgress,
  );
  final sink = File(localFilePath).openWrite();
  await for (final chunk in chunks) {
    sink.add(chunk);
  }
  await sink.flush();
  await sink.close();
}

/// Get a large file previously sent using [writeLargeFile] with name
/// [remoteFilePath] (relative to appname/data directory) and return
/// it as bytes.
Future<Uint8List> readLargeFileAsBytes({
  required String remoteFilePath,
  String? ownerWebId,
  bool isPodRelativePath = false,
  void Function(int, int)? onProgress,
}) async {
  final chunks = fetch(
    remoteFilePath: remoteFilePath,
    ownerWebId: ownerWebId,
    isPodRelativePath: isPodRelativePath,
    onProgress: onProgress,
  );
  final builder = BytesBuilder();

  await for (final chunk in chunks) {
    builder.add(chunk);
  }

  return builder.toBytes();
}

/// Send a large local file with path [localFilePath] to a remote server
/// using name [remoteFilePath] (relative to appname/data directory),
/// encrypt the file content if [encrypted] is true.
///
/// By default the file is written to the current user's own POD. To write to
/// the POD of another owner (e.g. a note or community POD shared with the
/// user), provide that owner's WebID via [ownerWebId]. This mirrors the
/// [ownerWebId] parameter of [readLargeFile] and the [fileOwnerWebId]
/// parameter of [writeExternalPod]. When writing to an external POD with
/// encryption, [inheritKeyFrom] must point to a directory whose encryption
/// key is shared with the user (the same contract as [writeExternalPod]),
/// otherwise the per-file encryption key would be stored unencrypted.
///
/// Set [isPodRelativePath] to true when [remoteFilePath] is relative to the
/// POD root (e.g. `demopod/data/file.pdf`) rather than the current app's data
/// directory. This is required to write a large file to a POD whose
/// application directory differs from the current app (for instance when the
/// destination URL supplied by the user names a different app).
Future<void> writeLargeFile({
  required String localFilePath,
  required String remoteFilePath,
  String? ownerWebId,
  String? inheritKeyFrom,
  bool createAcl = true,
  bool isPodRelativePath = false,
  void Function(int, int)? onProgress,
  bool encrypted = true,
}) async {
  final file = File(localFilePath);
  final totalBytes = file.lengthSync();
  await send(
    dataStream: file.openRead(),
    remoteFilePath: remoteFilePath,
    totalBytes: totalBytes,
    ownerWebId: ownerWebId,
    inheritKeyFrom: inheritKeyFrom,
    createAcl: createAcl,
    isPodRelativePath: isPodRelativePath,
    onProgress: (sent, total) {
      if (onProgress != null) {
        onProgress(sent, total!);
      }
    },
    encrypted: encrypted,
  );
}

/// Delete a large file previously sent using [writeLargeFile] with URL
/// [remoteFilePath] (relative to appname/data directory) in POD.
///
/// By default the file is deleted from the current user's own POD. To delete
/// a large file owned by another user, provide that owner's WebID via
/// [ownerWebId] (consistent with [writeLargeFile] and [readLargeFile]).
Future<void> deleteLargeFile({
  required String remoteFilePath,
  String? ownerWebId,
  bool isPodRelativePath = false,
  void Function(int, int)? onProgress,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final externWebId = await resolveExternalOwner(ownerWebId);

  final filePath = isPodRelativePath
      ? remoteFilePath
      : [await getDataDirPath(), remoteFilePath].join('/');
  final chunkDirUrl = await getDirUrl(
    _getChunkDirPath(filePath),
    webId: externWebId,
  );
  final fileUrl = await getFileUrl('$filePath.ttl', webId: externWebId);

  if (await checkResourceStatus(fileUrl, isFile: true) !=
          ResourceStatus.exist &&
      await checkResourceStatus(chunkDirUrl, isFile: false) !=
          ResourceStatus.exist) {
    debugPrint('The requested file does not exist.');
    return;
  }

  // For a large file on the user's OWN POD, revoke any recipients' access to
  // the file's shareable resources (the metadata file and the chunk directory)
  // before deleting them, so the recipients' permission logs no longer show
  // access to a file that no longer exists. This mirrors deleteFile() for
  // regular files. Revocation rewrites ACLs and is therefore only possible on
  // the user's own POD, so it is skipped for external deletions.

  if (externWebId == null) {
    await _revokeLargeFileRecipients(fileUrl, isFile: true);
    await _revokeLargeFileRecipients(chunkDirUrl, isFile: false);
  }

  // Parse the Turtle file with metadata of the (chunked) large file
  // on server to get the URLs of individual chunks

  final triples = turtleToTripleMap(
    externWebId == null
        ? await readPod(fileUrl, pathType: PathType.absoluteUrl)
        : await readExternalPod(fileUrl),
  );
  assert(triples.length == 1);
  assert(triples.containsKey(fileUrl));

  final map = triples[fileUrl];
  final chunkPred = SIIPredicate.dataChunk.uriRef.value;
  assert(map!.containsKey(chunkPred));

  // Delete the individual chunks

  final chunkUrls = map![chunkPred];
  final chunkCount = chunkUrls!.length;
  var deleted = 0;

  for (final url in chunkUrls) {
    final chunkUrl = url as String;
    await deleteResource(chunkUrl, ResourceContentType.binary);
    // await deleteAclForResource(chunkUrl);  // this may not be necessary

    deleted += 1;

    if (onProgress != null) {
      onProgress(deleted, chunkCount);
    }
  }

  // Delete the directory with individual chunks
  await deleteResource(
    '$chunkDirUrl${_getChunkDirInitFileName()}',
    ResourceContentType.turtleText,
  );
  await deleteAclForResource(chunkDirUrl);
  await deleteResource(chunkDirUrl, ResourceContentType.directory);

  // Delete the representing turtle file

  await deleteResource(fileUrl, ResourceContentType.turtleText);

  debugPrint('Deleted $remoteFilePath');
}

// Revoke any recipients' access to a large file's resource identified by its
// full [resourceUrl] (the metadata file when [isFile] is true, or the chunk
// directory when false). A resource that was never shared has no recipients to
// revoke (and may have no ACL), so any error is logged and swallowed rather
// than aborting the surrounding deletion.

Future<void> _revokeLargeFileRecipients(
  String resourceUrl, {
  required bool isFile,
}) async {
  try {
    await revokePermissionToRecipients(
      fileName: resourceUrl,
      isFile: isFile,
      isFileUrl: true,
    );
  } catch (e) {
    debugPrint(
      'Warning: could not revoke permissions for "$resourceUrl" '
      '(ACL may not exist or it was never shared): $e',
    );
  }
}

// Return the URL of directory storing the chunked data
// A hidden directory (starts with .) to hide the clutter
String _getChunkDirPath(String remoteFilePath) {
  final items = remoteFilePath.split('/');
  final parentUrl = items.getRange(0, items.length - 1).join('/');
  return '$parentUrl/.${items.last}.chunks/';
}

// Chunk directory initialisation file name
String _getChunkDirInitFileName() => '.init.ttl';

// Return the name of a data chunk
String _getChunkName(int chunkId) => '$chunkId.bin';
// String _getChunkName(int chunkId, int chunkCount) {
//   assert(chunkId >= 0);
//   assert(chunkId < chunkCount);
//   final prefix = chunkId.toString().padLeft(chunkCount.toString().length, '0');
//   return '$prefix.bin';
// }

// Transform the stream of file content into a stream of (larger) chunks.
// [contentStream] is typically set to [file.openRead()]
Stream<Uint8List> _getChunkStream(
  Stream<List<int>> contentStream, {
  int chunkSize = 2 * 1024 * 1024,
}) async* {
  // Dart reads file in blocks of size 64k, see
  // https://github.com/dart-lang/sdk/blob/main/sdk/lib/io/file_impl.dart
  assert(chunkSize >= 64 * 1024);

  final bytesBuilder = BytesBuilder();

  await for (final block in contentStream) {
    if (bytesBuilder.length < chunkSize) {
      bytesBuilder.add(block);
    } else {
      final chunk = bytesBuilder.takeBytes();
      bytesBuilder.add(block);
      yield chunk;
    }
  }

  // Add final chunks to output stream
  if (bytesBuilder.isNotEmpty) {
    yield bytesBuilder.takeBytes();
  }
}

Encrypter _getEncrypter(Key key, {AESMode mode = AESMode.sic}) =>
    Encrypter(AES(key, mode: mode));

// Encrypt binary data using AES with the specified key
Uint8List _encryptBytes(List<int> data, Encrypter encrypter, IV iv) =>
    encrypter.encryptBytes(data, iv: iv).bytes;

// Decrypt an encrypted binary data
Uint8List _decryptBytes(Uint8List encData, Encrypter encrypter, IV iv) =>
    Uint8List.fromList(encrypter.decryptBytes(Encrypted(encData), iv: iv));

/// Send a stream of data [dataStream] to a remote server
/// using name [remoteFilePath],
/// encrypt the file content if [encrypted] is true.
///
/// If [ownerWebId] is provided and differs from the current user's WebID, the
/// data (chunks and metadata) is written to that owner's external POD instead
/// of the user's own POD. See [writeLargeFile] for the encryption contract
/// when writing to an external POD.
Future<void> send({
  required Stream<List<int>> dataStream,
  required String remoteFilePath,
  int? totalBytes,
  String? ownerWebId,
  String? inheritKeyFrom,
  bool createAcl = true,
  bool isPodRelativePath = false,
  void Function(int, int?)? onProgress,
  bool encrypted = true,
}) async {
  if (onProgress != null) {
    assert(
      totalBytes != null,
      'totalBytes is required in order to use the onProgress() callback',
    );
  }

  // A valid session is required to obtain the DPoP/access tokens used for
  // every write below (mirrors writeExternalPod()).

  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to write to a POD.');
  }

  // Determine whether we are writing to an external owner's POD.
  final externWebId = await resolveExternalOwner(ownerWebId);

  // When writing to an external POD we must NOT create explicit ACL files.
  // Writing an `.acl` resource requires acl:Control on the target, which the
  // sender does not hold — they were only granted Read/Write/Append on the
  // shared parent directory (whose acl:default the chunk directory, chunks and
  // metadata file then inherit). Attempting to PUT an `.acl` here would be
  // rejected by the server with a 403 ForbiddenHttpError ("Failed to create
  // resource"). ACL creation therefore only applies to writes into the user's
  // own POD.

  final effectiveCreateAcl = externWebId == null && createAcl;

  // When isPodRelativePath is true, remoteFilePath already includes the
  // application directory (e.g. demopod/data/file.pdf), so it must NOT be
  // prefixed with the current app's data directory.

  final filePath = isPodRelativePath
      ? remoteFilePath
      : [await getDataDirPath(), remoteFilePath].join('/');
  final chunkDirUrl = await getDirUrl(
    _getChunkDirPath(filePath),
    webId: externWebId,
  );
  final fileUrl = await getFileUrl('$filePath.ttl', webId: externWebId);

  if (await checkResourceStatus(fileUrl, isFile: true) ==
          ResourceStatus.exist ||
      await checkResourceStatus(chunkDirUrl, isFile: false) ==
          ResourceStatus.exist) {
    throw Exception('ERROR: $remoteFilePath already exists.');
  }

  // Create the directory that holds the chunked data.

  await createResource(
    chunkDirUrl,
    isFile: false,
    replaceIfExist: false,
    contentType: ResourceContentType.directory,
  );

  // Create an empty TTL file in chunkDir/.init.ttl so the (chunked) large
  // file always has a representative resource inside its chunk directory
  // (deleteLargeFile() relies on this file being present).

  await createResource('$chunkDirUrl${_getChunkDirInitFileName()}');

  // Create ACL of the directory if ACL is not inherited (own POD only;
  // external writes inherit the shared parent directory's ACL).
  if (effectiveCreateAcl) {
    await createResource(
      '$chunkDirUrl.acl',
      content: await genAclTurtle(
        chunkDirUrl,
        isFile: false,
        externalWebId: externWebId ?? '',
      ),
    );
  }

  // Encryption key and IV for data chunks
  Key? encKey;
  Encrypter? encrypter;
  IV? iv;
  if (encrypted || inheritKeyFrom != null) {
    encKey = genRandIndividualKey();
    encrypter = _getEncrypter(encKey);
    iv = genRandIV();
  }

  var chunkId = 0;
  final chunkUrls = <String>[];
  var sentBytes = 0;
  final chunks = _getChunkStream(dataStream);
  await for (final chunk in chunks) {
    final chunkUrl = '$chunkDirUrl${_getChunkName(chunkId)}';
    chunkUrls.add(chunkUrl);

    // Create the chunk file
    await createResource(
      chunkUrl,
      content: encrypter != null ? _encryptBytes(chunk, encrypter, iv!) : chunk,
      contentType: ResourceContentType.binary,
    );

    // Create ACL of the chunk file if ACL is not inherited (own POD only;
    // external writes inherit the shared parent directory's ACL).
    if (effectiveCreateAcl) {
      await createResource(
        '$chunkUrl.acl',
        content: await genAclTurtle(chunkUrl, externalWebId: externWebId ?? ''),
      );
    }

    sentBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(sentBytes, totalBytes);
    }

    chunkId++;
  }

  // Create turtle file with metadata of the (chunked) large file on server

  final triples = {
    URIRef(fileUrl): {
      SIIPredicate.dataSize.uriRef: Literal(sentBytes.toString()),
      SIIPredicate.dataChunk.uriRef: {for (final url in chunkUrls) URIRef(url)},
      if (encrypter != null) ...{
        SIIPredicate.encryptionKey.uriRef: encKey!.base64,
        SIIPredicate.ivB64.uriRef: iv!.base64,
      },
    },
  };

  final bindNS = {siiNS.prefix: siiNS.ns, 'c': Namespace(ns: chunkDirUrl)};
  final metadataTurtle = tripleMapToTurtle(triples, bindNamespaces: bindNS);

  if (externWebId == null) {
    // For a POD-relative path the metadata file lives outside the current
    // app's data directory, so address it relative to the POD root rather
    // than letting writePod() prepend the app's data directory.
    await writePod(
      isPodRelativePath ? '$filePath.ttl' : '$remoteFilePath.ttl',
      metadataTurtle,
      encrypted: encrypted,
      inheritKeyFrom: inheritKeyFrom,
      createAcl: effectiveCreateAcl,
      pathType:
          isPodRelativePath ? PathType.relativeToPod : PathType.relativeToData,
    );
  } else {
    // Write the metadata file to the external owner's POD. The ACL of the
    // metadata file is handled by writeExternalPod (inherited from the shared
    // parent directory when inheritKeyFrom is provided).
    await writeExternalPod(
      fileUrl,
      metadataTurtle,
      externWebId,
      encrypted: encrypted,
      inheritKeyFrom: inheritKeyFrom,
    );
  }
}

/// Get a large file previously sent using [writeLargeFile] with name
/// [remoteFilePath] and return a stream of bytes.
Stream<List<int>> fetch({
  required String remoteFilePath,
  String? ownerWebId,
  bool isPodRelativePath = false,
  void Function(int, int)? onProgress,
}) async* {
  // Check if the corresponding Turtle file and directory of chunks exist

  final externWebId = await resolveExternalOwner(ownerWebId);

  final filePath = isPodRelativePath
      ? remoteFilePath
      : [await getDataDirPath(), remoteFilePath].join('/');
  final chunkDirUrl = await getDirUrl(
    _getChunkDirPath(filePath),
    webId: externWebId,
  );

  final fileUrl = await getFileUrl('$filePath.ttl', webId: externWebId);

  debugPrint('fileUrl: $fileUrl');
  debugPrint('chunkDirUrl: $chunkDirUrl');

  if (await checkResourceStatus(fileUrl, isFile: true) !=
          ResourceStatus.exist ||
      await checkResourceStatus(chunkDirUrl, isFile: false) !=
          ResourceStatus.exist) {
    throw Exception('Failed to get the requested file "$remoteFilePath');
  }

  // Parse the Turtle file with metadata of the (chunked) large file
  // on server to get the URLs of individual chunks

  String content;
  if (externWebId == null) {
    content = await readPod(fileUrl, pathType: PathType.absoluteUrl);
  } else {
    content = await readExternalPod(fileUrl);
  }

  final triples = turtleToTripleMap(content);
  assert(triples.length == 1);
  assert(triples.containsKey(fileUrl));

  final map = triples[fileUrl];
  final chunkPred = SIIPredicate.dataChunk.uriRef.value;
  final sizePred = SIIPredicate.dataSize.uriRef.value;
  assert(map!.containsKey(chunkPred));
  assert(map!.containsKey(sizePred));

  // Get the encryption key and IV

  Encrypter? encrypter;
  IV? iv;
  final keyPred = SIIPredicate.encryptionKey.uriRef.value;
  final ivPred = SIIPredicate.ivB64.uriRef.value;

  if (map!.containsKey(keyPred)) {
    assert(map.containsKey(ivPred));
    encrypter = _getEncrypter(Key.fromBase64(map[keyPred] as String));
    iv = IV.fromBase64(map[ivPred] as String);
  }

  // Get the individual chunks, combine them, and save combined to file

  final totalBytes = int.parse(map[sizePred] as String);
  var receivedBytes = 0;
  final chunkUrls = map[chunkPred];
  assert(chunkUrls != null);
  final urls = chunkUrls is Iterable
      ? (chunkUrls as List).map((e) => e as String).toList()
      : [chunkUrls as String];

  for (final url in urls) {
    final c = await getResource(url);
    final chunk = encrypter != null ? _decryptBytes(c, encrypter, iv!) : c;
    receivedBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(receivedBytes, totalBytes);
    }
    yield chunk;
  }
}
