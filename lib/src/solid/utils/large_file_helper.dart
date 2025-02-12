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
/// Authors: Dawei Chen
//
// ignore_for_file: use_build_context_synchronously

library;

import 'dart:io' show File;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:encrypt/encrypt.dart';
import 'package:flutter/widgets.dart' hide Key;
import 'package:rdflib/rdflib.dart' show Namespace, URIRef, Literal;

import 'package:solidpod/src/solid/api/rest_api.dart'
    show createResource, checkResourceStatus, getResource, deleteResource;
import 'package:solidpod/src/solid/utils/misc.dart'
    show deleteAclForResource, deleteFile;
import 'package:solidpod/src/solid/constants/common.dart'
    show ResourceContentType, ResourceStatus;
import 'package:solidpod/src/solid/constants/schema.dart'
    show siiNS, SIIPredicate;
import 'package:solidpod/src/solid/read_pod.dart' show readPod;
import 'package:solidpod/src/solid/utils/key_helper.dart'
    show genRandIndividualKey, genRandIV;
import 'package:solidpod/src/solid/utils/misc.dart'
    show getDataDirPath, getDirUrl, getFileUrl;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;
import 'package:solidpod/src/solid/write_pod.dart' show writePod;

/// Return the URL of directory storing the chunked data
/// A hidden directory (starts with .) to hide the clutter
String _getChunkDirPath(String remoteFilePath) {
  final items = remoteFilePath.split('/');
  final parentUrl = items.getRange(0, items.length - 1).join('/');
  return '$parentUrl/.${items.last}.chunks/';
}

/// Return the name of a data chunk
String _getChunkName(int chunkId) => '$chunkId.bin';
// String _getChunkName(int chunkId, int chunkCount) {
//   assert(chunkId >= 0);
//   assert(chunkId < chunkCount);
//   final prefix = chunkId.toString().padLeft(chunkCount.toString().length, '0');
//   return '$prefix.bin';
// }

/// Transform the stream of file content into a stream of (larger) chunks.
/// [contentStream] is typically set to [file.openRead()]
Stream<Uint8List> _getChunkStream(
  Stream<List<int>> contentStream, {
  int chunkSize = 2 * 1024 * 1024,
}) async* {
  // Dart reads file in blocks of size 64k, see
  // https://github.com/dart-lang/sdk/lib/io/file_impl.dart
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

/// Encrypt binary data using AES with the specified key
Uint8List _encryptBytes(List<int> data, Encrypter encrypter, IV iv) =>
    encrypter.encryptBytes(data, iv: iv).bytes;

/// Decrypt an encrypted binary data
Uint8List _decryptBytes(Uint8List encData, Encrypter encrypter, IV iv) =>
    Uint8List.fromList(encrypter.decryptBytes(Encrypted(encData), iv: iv));

/// Send a large local file with path [localFilePath] to a remote server
/// using name [remoteFileName],
/// encrypt the file content if [encrypted] is true.
Future<void> sendLargeFile({
  required String localFilePath,
  required String remoteFileName,
  required BuildContext context,
  required Widget child,
  void Function(int, int)? onProgress,
  bool encrypted = true,
}) async {
  final file = File(localFilePath);
  final totalBytes = file.lengthSync();
  await post(
    dataStream: file.openRead(),
    remoteFileName: remoteFileName,
    context: context,
    child: child,
    totalBytes: totalBytes,
    onProgress: (sent, total) {
      if (onProgress != null) {
        onProgress(sent, total!);
      }
    },
    encrypted: encrypted,
  );
}

/// Send a stream of data [dataStream] to a remote server
/// using name [remoteFileName],
/// encrypt the file content if [encrypted] is true.
Future<void> post({
  required Stream<List<int>> dataStream,
  required String remoteFileName,
  required BuildContext context,
  required Widget child,
  int? totalBytes,
  void Function(int, int?)? onProgress,
  bool encrypted = true,
}) async {
  // final file = File(localFilePath);
  final remoteFilePath = [await getDataDirPath(), remoteFileName].join('/');
  final chunkDirUrl = await getDirUrl(_getChunkDirPath(remoteFilePath));
  final fileUrl = await getFileUrl('$remoteFilePath.ttl');

  if (await checkResourceStatus(fileUrl) == ResourceStatus.exist ||
      await checkResourceStatus(chunkDirUrl) == ResourceStatus.exist) {
    // throw Exception('Failed to send file $localFilePath.\n'
    //    '$remoteFileName already exists.');
    throw Exception('ERROR: $remoteFileName already exists.');
  }

  // Create the directory for storing chunked data
  await createResource(
    chunkDirUrl,
    fileFlag: false,
    contentType: ResourceContentType.directory,
  );

  // Create ACL of the directory
  await createResource(
    '$chunkDirUrl.acl',
    content: await genAclTurtle(chunkDirUrl, fileFlag: false),
  );

  // Encryption key and IV
  Key? encKey;
  Encrypter? encrypter;
  IV? iv;
  if (encrypted) {
    encKey = genRandIndividualKey();
    encrypter = _getEncrypter(encKey);
    iv = genRandIV();
  }

  var chunkId = 0;
  final chunkUrls = <String>[];
  // final totalBytes = await file.length();
  var sentBytes = 0;
  // final chunks = _getChunkStream(file.openRead());
  final chunks = _getChunkStream(dataStream);
  await for (final chunk in chunks) {
    final chunkUrl = '$chunkDirUrl${_getChunkName(chunkId)}';
    chunkUrls.add(chunkUrl);

    // Create the chunk file
    await createResource(
      chunkUrl,
      content: encrypted ? _encryptBytes(chunk, encrypter!, iv!) : chunk,
      contentType: ResourceContentType.binary,
    );

    // Create ACL of the chunk file
    await createResource(
      '$chunkUrl.acl',
      content: await genAclTurtle(chunkUrl),
    );

    sentBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(sentBytes, totalBytes);
    }

    chunkId++;
  }

  // Create turtle file with metadata of the (chunked) large file on server

  final triples = {
    URIRef(fileUrl): {
      // SIIPredicate.dataSize.uriRef: Literal(file.lengthSync().toString()),
      SIIPredicate.dataSize.uriRef: Literal(sentBytes.toString()),
      SIIPredicate.dataChunk.uriRef: {for (final url in chunkUrls) URIRef(url)},
      if (encrypted) ...{
        SIIPredicate.encryptionKey.uriRef: encKey!.base64,
        SIIPredicate.ivB64.uriRef: iv!.base64,
      },
    },
  };

  final bindNS = {
    siiNS.prefix: siiNS.ns,
    'c': Namespace(ns: chunkDirUrl),
  };

  await writePod(
    '$remoteFileName.ttl',
    tripleMapToTurtle(triples, bindNamespaces: bindNS),
    context,
    child,
  );

  // Create ACL of the Turtle file
  await createResource('$fileUrl.acl', content: await genAclTurtle(fileUrl));
}

/// Get a large file previously sent using [sendLargeFile] with name
/// [remoteFileName] and save it to a local file with path [localFilePath]
Future<void> getLargeFile({
  required String remoteFileName,
  required String localFilePath,
  required BuildContext context,
  required Widget child,
  void Function(int, int)? onProgress,
  bool encrypted = true,
}) async {}

/// Get a large file previously sent using [sendLargeFile] with name
/// [remoteFileName] and save it to a local file with path [localFilePath]
Future<Stream<List<int>> get({
  required String remoteFileName,
  required String localFilePath,
  required BuildContext context,
  required Widget child,
  void Function(int, int)? onProgress,
  bool encrypted = true,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final remoteFilePath = [await getDataDirPath(), remoteFileName].join('/');
  final chunkDirUrl = await getDirUrl(_getChunkDirPath(remoteFilePath));
  final fileUrl = await getFileUrl('$remoteFilePath.ttl');

  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist ||
      await checkResourceStatus(chunkDirUrl) != ResourceStatus.exist) {
    throw Exception('Failed to get the requested file "$remoteFileName');
  }

  // Parse the Turtle file with metadata of the (chunked) large file
  // on server to get the URLs of individual chunks

  final triples = turtleToTripleMap(
    await readPod('$remoteFilePath.ttl', context, child) as String,
  );
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
  if (encrypted) {
    final keyPred = SIIPredicate.encryptionKey.uriRef.value;
    final ivPred = SIIPredicate.ivB64.uriRef.value;
    assert(map!.containsKey(keyPred));
    assert(map!.containsKey(ivPred));
    encrypter = _getEncrypter(Key.fromBase64(map![keyPred]!.first as String));
    iv = IV.fromBase64(map[ivPred]!.first as String);
  }

  // Get the individual chunks, combine them, and save combined to file

  final totalBytes = int.parse(map![sizePred]!.first as String);
  var receivedBytes = 0;
  final chunkUrls = map[chunkPred];
  final sink = File(localFilePath).openWrite();
  for (final url in chunkUrls!) {
    final c = await getResource(url as String);
    final chunk = encrypted ? _decryptBytes(c, encrypter!, iv!) : c;
    sink.add(chunk);
    receivedBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(receivedBytes, totalBytes);
    }
  }
  await sink.close();
}

/// Delete a large file previously sent using [sendLargeFile] with URL
/// [remoteFileName] in POD
Future<void> deleteLargeFile({
  required String remoteFileName,
  required BuildContext context,
  required Widget child,
  void Function(int, int)? onProgress,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final remoteFilePath = [await getDataDirPath(), remoteFileName].join('/');
  final chunkDirUrl = await getDirUrl(_getChunkDirPath(remoteFilePath));
  final fileUrl = await getFileUrl('$remoteFilePath.ttl');

  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist &&
      await checkResourceStatus(chunkDirUrl) != ResourceStatus.exist) {
    debugPrint('The requested file does not exist.');
    return;
  }

  // Parse the Turtle file with metadata of the (chunked) large file
  // on server to get the URLs of individual chunks

  final triples = turtleToTripleMap(
    await readPod('$remoteFilePath.ttl', context, child) as String,
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

  await deleteAclForResource(chunkDirUrl);
  await deleteResource(chunkDirUrl, ResourceContentType.directory);

  // Delete the representing turtle file

  await deleteFile('$remoteFilePath.ttl');

  debugPrint('Deleted $remoteFileName');
}
