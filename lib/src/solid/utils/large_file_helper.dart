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

import 'dart:convert' show utf8, base64;
import 'dart:io' show File;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:rdflib/rdflib.dart' show Namespace, URIRef, Literal;

import 'package:solidpod/src/solid/api/rest_api.dart'
    show
        createResource,
        checkResourceStatus,
        getResource,
        deleteResource,
        updateFileByQuery,
        queryRDF;
import 'package:solidpod/src/solid/utils/misc.dart' show deleteAclForResource;
import 'package:solidpod/src/solid/constants/common.dart'
    show ResourceContentType, ResourceStatus;
import 'package:solidpod/src/solid/constants/schema.dart'
    show siiNS, SIIPredicate;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;

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

/// Send data chunks through SPARQL query
Future<void> sendLargeFile({
  required String localFilePath,
  required String remoteFileUrl,
  void Function(int, int)? onProgress,
}) async {
  final file = File(localFilePath);

  final fileUrl = '$remoteFileUrl.ttl';
  if (await checkResourceStatus(fileUrl) == ResourceStatus.exist) {
    throw Exception('Failed to send file $localFilePath.\n'
        '$remoteFileUrl already exists.');
  }

  // Create turtle file with metadata of the (chunked) large file on server

  final sub = URIRef(remoteFileUrl);

  final triples = {
    sub: {
      SIIPredicate.dataSize.uriRef: Literal(file.lengthSync().toString()),
    }
  };

  final bindNS = {
    siiNS.prefix: siiNS.ns,
  };

  await createResource(fileUrl,
      content: tripleMapToTurtle(triples, bindNamespaces: bindNS));

  // Create ACL of the Turtle file
  await createResource('$fileUrl.acl', content: await genAclTurtle(fileUrl));

  var chunkId = 0;
  final preId = SIIPredicate.chunkId.uriRef.value;
  final preData = SIIPredicate.dataChunk.uriRef.value;
  final preCount = SIIPredicate.chunkCount.uriRef.value;
  final totalBytes = await file.length();
  var sentBytes = 0;

  // Got error: {"name":"BadRequestHttpError","message":"Maximum call stack size exceeded","statusCode":400,"errorCode":"H400","details":{}}
  // if using chunkSize: 2 * 1024 * 1024 or even 512 * 1024
  // set chunkSize to 64 * 1024 or even 256 * 1024 seems to work, but it get slower overtime.
  final chunks = _getChunkStream(file.openRead(), chunkSize: 256 * 1024);
  await for (final chunk in chunks) {
    print(chunkId);
    final query = 'INSERT DATA {<$sub> <$preId> "$chunkId"; '
        '<$preData> "${base64.encode(chunk)}".};';

    await updateFileByQuery(fileUrl, query);

    sentBytes += chunk.lengthInBytes;
    if (onProgress != null) {
      onProgress(sentBytes, totalBytes);
    }

    chunkId++;
  }

  final query = 'INSERT DATA {<$sub> <$preCount> "$chunkId".};';

  await updateFileByQuery(fileUrl, query);
}

/// Get large file by querying the RDF
Future<void> getLargeFile({
  required String remoteFileUrl,
  required String localFilePath,
  void Function(int, int)? onProgress,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final fileUrl = '$remoteFileUrl.ttl';

  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist) {
    throw Exception('Failed to get the requested file. \nURL: $remoteFileUrl');
  }

  final chunkPred = SIIPredicate.dataChunk.uriRef.value;
  final idPred = SIIPredicate.chunkId.uriRef.value;
  final countPred = SIIPredicate.chunkCount.uriRef.value;

  final chunkCount = int.parse(await queryRDF(fileUrl, 'SELECT ?$countPred'));
  print(chunkCount);

  // Get the individual chunks, combine them, and save combined to file

  final sink = File(localFilePath).openWrite();
  for (var chunkId = 0; chunkId < chunkCount; chunkId++) {
    final query = 'SELECT ?$chunkPred WHERE ?$idPred "$chunkId";';
    final chunk = await queryRDF(fileUrl, query);
    sink.add(base64.decode(chunk));
    if (onProgress != null) {
      onProgress(chunkId + 1, chunkCount);
    }
  }
  await sink.close();
}

/// Delete large file
Future<void> deleteLargeFile({
  required String remoteFileUrl,
  void Function(int, int)? onProgress,
}) async {
  // Check if the corresponding Turtle file and directory of chunks exist

  final fileUrl = '$remoteFileUrl.ttl';

  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist) {
    debugPrint('The requested file does not exist.');
    return;
  }

  await deleteResource(fileUrl, ResourceContentType.turtleText);
  // await deleteAclForResource(fileUrl);  // this may not be necessary

  if (onProgress != null) {
    onProgress(1, 1);
  }

  debugPrint('Deleted $remoteFileUrl');
}
