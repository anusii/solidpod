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

library;

import 'dart:convert' show utf8;
import 'dart:io' show File;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:rdflib/rdflib.dart' show Namespace, URIRef, Literal;
import 'package:solidpod/solidpod.dart';

import 'package:solidpod/src/solid/api/rest_api.dart'
    show createResource, checkResourceStatus, getResource, deleteResource;
import 'package:solidpod/src/solid/constants/common.dart'
    show ResourceContentType, ResourceStatus;
import 'package:solidpod/src/solid/constants/schema.dart'
    show siiNS, SIIPredicate;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;

/// Return the URL of directory storing the chunked data
/// A hidden directory (starts with .) to hide the clutter
String _getChunkDirUrl(String fileUrl) {
  final items = fileUrl.split('/');
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
Stream<Uint8List> _getChunkStream(Stream<List<int>> contentStream,
    {int chunkSize = 2 * 1024 * 1024}) async* {
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

/// Send a large local file with path [localFilePath] to a remote server
/// using URL [remoteFileUrl]
Future<void> sendLargeFile({
  required String localFilePath,
  required String remoteFileUrl,
  void Function(int, int)? onProgress,
}) async {
  final file = File(localFilePath);
  final chunkDirUrl = _getChunkDirUrl(remoteFileUrl);

  final fileUrl = '$remoteFileUrl.ttl';
  if (await checkResourceStatus(fileUrl) == ResourceStatus.exist ||
      await checkResourceStatus(chunkDirUrl) == ResourceStatus.exist) {
    throw Exception('Failed to send file $localFilePath.\n'
        '$remoteFileUrl already exists.');
  }

  // Create the directory for storing chunked data
  await createResource(chunkDirUrl,
      fileFlag: false, contentType: ResourceContentType.directory);

  // Create ACL of the directory
  await createResource('$chunkDirUrl/.acl',
      content: await genAclTurtle(chunkDirUrl, fileFlag: false));

  var chunkId = 0;
  final chunkUrls = <String>[];
  final totalBytes = await file.length();
  var sentBytes = 0;
  final chunks = _getChunkStream(file.openRead());
  await for (final chunk in chunks) {
    final chunkUrl = '$chunkDirUrl${_getChunkName(chunkId)}';
    chunkUrls.add(chunkUrl);

    // Create the chunk file
    await createResource(chunkUrl,
        content: chunk, contentType: ResourceContentType.binary);

    // Create ACL of the chunk file
    await createResource('$chunkUrl.acl',
        content: await genAclTurtle(chunkUrl));

    sentBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(sentBytes, totalBytes);
    }

    chunkId++;
  }

  // Create turtle file with metadata of the (chunked) large file on server

  final triples = {
    URIRef(remoteFileUrl): {
      SIIPredicate.dataSize.uriRef: Literal(file.lengthSync().toString()),
      SIIPredicate.dataChunk.uriRef: {for (final url in chunkUrls) URIRef(url)},
    }
  };

  final bindNS = {
    siiNS.prefix: siiNS.ns,
    'c': Namespace(ns: chunkDirUrl),
  };

  await createResource(fileUrl,
      content: tripleMapToTurtle(triples, bindNamespaces: bindNS));

  // Create ACL of the Turtle file
  await createResource('$fileUrl.acl', content: await genAclTurtle(fileUrl));
}

/// Get a large file previously sent using [sendLargeFile] with URL
/// [remoteFileUrl] and save it to a local file with path [localFilePath]
Future<void> getLargeFile({
  required String remoteFileUrl,
  required String localFilePath,
  void Function(int, int)? onProgress,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final fileUrl = '$remoteFileUrl.ttl';
  final chunkDirUrl = _getChunkDirUrl(remoteFileUrl);

  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist ||
      await checkResourceStatus(chunkDirUrl) != ResourceStatus.exist) {
    throw Exception('Failed to get the requested file. \nURL: $remoteFileUrl');
  }

  // Parse the Turtle file with metadata of the (chunked) large file
  // on server to get the URLs of individual chunks

  final triples = turtleToTripleMap(utf8.decode(await getResource(fileUrl)));
  assert(triples.length == 1);
  assert(triples.containsKey(remoteFileUrl));

  final map = triples[remoteFileUrl];
  final chunkPred = SIIPredicate.dataChunk.uriRef.value;
  final sizePred = SIIPredicate.dataSize.uriRef.value;
  assert(map!.containsKey(chunkPred));
  assert(map!.containsKey(sizePred));

  // Get the individual chunks, combine them, and save combined to file

  final totalBytes = map![sizePred]!.first as int;
  var receivedBytes = 0;
  final chunkUrls = map[chunkPred];
  final sink = File(localFilePath).openWrite();
  for (final url in chunkUrls!) {
    final chunk = await getResource(url as String);
    sink.add(chunk);
    receivedBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(receivedBytes, totalBytes);
    }
  }
  await sink.close();
}

/// Delete a large file previously sent using [sendLargeFile] with URL
/// [remoteFileUrl] in POD
Future<void> deleteLargeFile({
  required String remoteFileUrl,
  void Function(int, int)? onProgress,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final fileUrl = '$remoteFileUrl.ttl';
  final chunkDirUrl = _getChunkDirUrl(remoteFileUrl);

  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist &&
      await checkResourceStatus(chunkDirUrl) != ResourceStatus.exist) {
    debugPrint('The requested file does not exist.');
    return;
  }

  // Parse the Turtle file with metadata of the (chunked) large file
  // on server to get the URLs of individual chunks

  final triples = turtleToTripleMap(utf8.decode(await getResource(fileUrl)));
  assert(triples.length == 1);
  assert(triples.containsKey(remoteFileUrl));

  final map = triples[remoteFileUrl];
  final chunkPred = SIIPredicate.dataChunk.uriRef.value;
  assert(map!.containsKey(chunkPred));

  await deleteResource(fileUrl, ResourceContentType.turtleText);
  // await deleteAclForResource(fileUrl);  // this may not be necessary

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

  await deleteAclForResource(chunkDirUrl);
  await deleteResource(chunkDirUrl, ResourceContentType.directory);

  debugPrint('Deleted $remoteFileUrl');
}
