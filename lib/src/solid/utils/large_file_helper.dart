/// Helper functions to download and upload large files in PODs.
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

import 'dart:io';
import 'dart:typed_data';
import 'package:rdflib/rdflib.dart' show Namespace, URIRef;

import 'package:solidpod/src/solid/api/rest_api.dart' show createResource;
import 'package:solidpod/src/solid/constants/common.dart'
    show ResourceContentType;
import 'package:solidpod/src/solid/constants/schema.dart'
    show siiNS, SIIPredicate;
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/rdf.dart' show tripleMapToTurtle;

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
Stream<Uint8List> _dataChunks(Stream<List<int>> contentStream,
    {int chunkSize = 2 * 1024 * 1024}) async* {
  // Dart reads file in blocks of size 64k, see
  // https://github.com/dart-lang/sdk/lib/io/file_impl.dart
  assert(chunkSize >= 64 * 1024);
  final bytesBuilder = BytesBuilder(copy: false);
  await for (final block in contentStream) {
    if (bytesBuilder.length < chunkSize) {
      bytesBuilder.add(block);
    } else {
      yield bytesBuilder.toBytes();
    }
  }

  // Add final chunks to output stream
  if (bytesBuilder.isNotEmpty) {
    yield bytesBuilder.toBytes();
  }
}

/// Send a large local file with path [localFilePath] to a remote server
/// using URL [remoteFileUrl]
Future<void> sendLargeFile(String localFilePath, String remoteFileUrl) async {
  final file = File(localFilePath);
  final chunkDirUrl = _getChunkDirUrl(remoteFileUrl);

  // Create the directory for storing chunked data
  await createResource(chunkDirUrl,
      fileFlag: false, contentType: ResourceContentType.directory);

  // Create ACL of the directory
  await createResource('$chunkDirUrl/.acl',
      content: await genAclTurtle(chunkDirUrl, fileFlag: false));

  var chunkId = 0;
  // final chunkCount = 0;
  final chunkUrls = <String>[];
  await _dataChunks(file.openRead()).forEach((chunk) async {
    final chunkUrl = '$chunkDirUrl${_getChunkName(chunkId)}';
    chunkUrls.add(chunkUrl);

    // Create the chunk file
    await createResource(chunkUrl,
        content: chunk, contentType: ResourceContentType.binary);

    // Create ACL of the chunk file
    await createResource('$chunkUrl.acl',
        content: await genAclTurtle(chunkUrl));

    print(chunkId);
    chunkId++;
  });

  // Create turtle file with metadata of the (chunked) large file on server

  final fileUrl = '$remoteFileUrl.ttl';
  final triples = {
    URIRef(fileUrl): {
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
