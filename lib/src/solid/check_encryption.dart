/// Function to check if a file in a POD is encrypted by SolidPod.
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
/// Authors: Tony Chen

library;

import 'dart:convert' show utf8;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/constants/schema.dart' show SIIPredicate;
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart' show getPredicateUrl;
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart' show turtleToTripleMap;

/// Outcome of checking whether a resource on a POD is encrypted by solidpod.

enum EncryptionStatus {
  /// The resource exists and was encrypted by solidpod.
  ///
  /// The Turtle representation of the resource includes both the
  /// initialisation vector and the ciphertext predicates produced by
  /// `writePod()` (or the chunked-file equivalent used by `writeLargeFile()`).

  encrypted,

  /// The resource exists but is stored as plaintext (not encrypted by
  /// solidpod). Non-Turtle files always fall into this bucket because
  /// solidpod only encrypts content as Turtle.

  notEncrypted,

  /// The resource does not exist on the POD.

  notExist,

  /// The current user is not allowed to access the resource.

  forbidden,

  /// An unexpected error occurred while inspecting the resource. Inspect
  /// debug logs for further details.

  unknown,
}

/// Check whether the resource [filePath] on the POD is encrypted by solidpod.
///
/// This is a convenience wrapper around [getFileEncryptionStatus] that
/// returns `true` only when the resource exists and was encrypted by
/// solidpod. Any other outcome (plaintext, missing, forbidden, or an
/// unexpected error) returns `false`. Callers that need to distinguish
/// these cases should use [getFileEncryptionStatus] instead.
///
/// solidpod does not require the `.enc.ttl` suffix for encrypted resources,
/// so the suffix on its own is not a reliable indicator. This function
/// inspects the actual Turtle metadata on the server, matching the same
/// signal that `readPod()` uses to decide whether decryption is needed.
///
/// Examples:
/// - `isFileEncrypted('abc.ttl')` checks `appname/data/abc.ttl`.
/// - `isFileEncrypted('appname/data/abc.ttl', pathType: PathType.relativeToPod)`
///    checks the same resource via a POD-relative path.
/// - `isFileEncrypted('https://pods.example.com/me/myapp/data/abc.ttl',
///    pathType: PathType.absoluteUrl)` checks the resource by absolute URL.
///
/// Arguments:
/// - [filePath]: The path to the file to inspect.
/// - [pathType]: Optional override for how [filePath] should be resolved.
///   Defaults to `PathType.relativeToData`.

Future<bool> isFileEncrypted(
  String filePath, {
  PathType pathType = PathType.relativeToData,
}) async {
  final status = await getFileEncryptionStatus(filePath, pathType: pathType);
  return status == EncryptionStatus.encrypted;
}

/// Inspect the resource [filePath] on the POD and return a detailed
/// [EncryptionStatus] describing whether it is encrypted by solidpod.
///
/// Unlike [isFileEncrypted], this function preserves the distinction
/// between plaintext, missing, forbidden, and unknown outcomes so that
/// callers can react appropriately (e.g. prompting the user to log in or
/// reporting a 404). The function never attempts to decrypt the resource.
///
/// Arguments mirror [isFileEncrypted].

Future<EncryptionStatus> getFileEncryptionStatus(
  String filePath, {
  PathType pathType = PathType.relativeToData,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to check encryption status of a POD resource',
    );
  }

  final fileUrl = await generateResourceUrlFromPath(
    resourcePath: filePath,
    pathType: pathType,
  );

  final fileStatus = await checkResourceStatus(fileUrl);

  switch (fileStatus) {
    case ResourceStatus.notExist:
      return EncryptionStatus.notExist;
    case ResourceStatus.forbidden:
      return EncryptionStatus.forbidden;
    case ResourceStatus.unknown:
      return EncryptionStatus.unknown;
    case ResourceStatus.exist:
      // Fall through to inspect the body below.
      break;
  }

  // solidpod only encrypts content stored as Turtle. Anything else is
  // treated as plaintext, mirroring the behaviour of `readPod()`.

  if (!fileUrl.toLowerCase().endsWith('.ttl')) {
    return EncryptionStatus.notEncrypted;
  }

  try {
    final fileContent = utf8.decode(await getResource(fileUrl));
    return isContentEncrypted(fileUrl: fileUrl, content: fileContent)
        ? EncryptionStatus.encrypted
        : EncryptionStatus.notEncrypted;
  } on Object catch (e, trace) {
    debugPrint('getFileEncryptionStatus() failed for "$fileUrl": $e');
    debugPrint(trace.toString());
    return EncryptionStatus.unknown;
  }
}

/// Inspect raw Turtle [content] for solidpod's encryption markers.
///
/// This is the synchronous core that [getFileEncryptionStatus] uses once
/// the resource body has been fetched. It is exposed so that callers who
/// already hold the content (e.g. when batch-processing a directory dump
/// or writing unit tests) can avoid an additional network round-trip.
///
/// solidpod marks an encrypted Turtle resource by writing the
/// initialisation vector and the ciphertext as RDF triples against the
/// resource's own URL. Two layouts are recognised:
///
/// 1. The single-payload layout produced by `writePod()`, which uses the
///    `iv` and `encData` predicates from the `solidcommunity.au` terms
///    namespace.
/// 2. The chunked layout produced by `writeLargeFile()`, which uses the
///    `ivB64` and `encryptionKey` predicates from the SII namespace.
///
/// Returns `true` when either layout is detected and `false` otherwise
/// (including when [content] is not parseable Turtle).

bool isContentEncrypted({
  required String fileUrl,
  required String content,
}) {
  // A non-Turtle payload cannot match either layout, so short-circuit.

  if (!fileUrl.toLowerCase().endsWith('.ttl')) {
    return false;
  }

  Map<String, Map<String, dynamic>> tripleMap;
  try {
    tripleMap = turtleToTripleMap(content);
  } on Object catch (e) {
    // A parse failure means the file is not solidpod-encrypted Turtle;
    // treat it as plaintext rather than propagating the error.

    debugPrint('isContentEncrypted() failed to parse Turtle: $e');
    return false;
  }

  final map = tripleMap[fileUrl];
  if (map == null) {
    return false;
  }

  // Layout 1: small-file encryption written by `writePod()`.

  final ivStr = map[getPredicateUrl(ivPred)];
  final encDataStr = map[getPredicateUrl(encDataPred)];
  if (ivStr != null && encDataStr != null) {
    return true;
  }

  // Layout 2: chunked-file encryption written by `writeLargeFile()`.

  final ivB64Pred = SIIPredicate.ivB64.uriRef.value;
  final encKeyPred = SIIPredicate.encryptionKey.uriRef.value;
  if (map.containsKey(ivB64Pred) && map.containsKey(encKeyPred)) {
    return true;
  }

  return false;
}
