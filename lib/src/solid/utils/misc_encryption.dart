/// Encryption / decryption helpers operating on POD resources.
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'dart:convert' show utf8;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/public_sharing_hooks.dart';
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/misc_paths.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Encrypt a given data string and format to TTL
Future<String> getEncTTLStr({
  required String fileUrl,
  required String fileContent,
  required Key key,
  required IV iv,
  String? inheritKeyFrom,
}) async {
  final filePath = await extractResourcePathFromUrl(fileUrl);
  final triples = {
    URIRef(fileUrl): {
      solidTermsNS.ns.withAttr(pathPred): filePath,
      solidTermsNS.ns.withAttr(ivPred): iv.base64,
      if (inheritKeyFrom != null)
        solidTermsNS.ns.withAttr(inheritKeyPred): inheritKeyFrom,
      solidTermsNS.ns.withAttr(encDataPred): encryptData(fileContent, key, iv),
    },
  };

  final bindNS = {solidTermsNS.prefix: solidTermsNS.ns};

  return tripleMapToTurtle(triples, bindNamespaces: bindNS);
}

/// Inspect the on-server content of [fileUrl] and determine whether it is
/// currently in the encrypted TTL format produced by [getEncTTLStr].

Future<bool> isFileContentEncrypted(String fileUrl) async {
  if (!fileUrl.toLowerCase().endsWith('.ttl')) {
    debugPrint('[isFileContentEncrypted] non-ttl url, returning false: '
        '"$fileUrl"');
    return false;
  }
  try {
    if (await checkResourceStatus(fileUrl) != ResourceStatus.exist) {
      debugPrint('[isFileContentEncrypted] resource does not exist: '
          '"$fileUrl"');
      return false;
    }
    final raw = utf8.decode(await getResource(fileUrl));
    final encMap = _extractEncFields(raw, fileUrl);
    if (encMap == null) {
      debugPrint(
        '[isFileContentEncrypted] no iv/encData found for "$fileUrl"',
      );
      return false;
    }
    debugPrint('[isFileContentEncrypted] file IS encrypted: "$fileUrl"');
    return true;
  } on Object catch (e) {
    debugPrint('[isFileContentEncrypted] unable to inspect "$fileUrl": $e');
    return false;
  }
}

/// Look at the triple map produced by [turtleToTripleMap] and return the
/// `(iv, encData)` pair for [fileUrl] if the document is in the encrypted
/// TTL format, or `null` if it is not.

({String iv, String encData})? _extractEncFields(
  String rawTtl,
  String fileUrl,
) {
  final tripleMap = turtleToTripleMap(rawTtl);
  final ivKey = solidTermsNS.ns.withAttr(ivPred).value;
  final encKey = solidTermsNS.ns.withAttr(encDataPred).value;

  ({String iv, String encData})? pickFrom(Map<String, dynamic> m) {
    final iv = m[ivKey];
    final enc = m[encKey];
    if (iv is String && enc is String) {
      return (iv: iv, encData: enc);
    }
    return null;
  }

  final direct = tripleMap[fileUrl];
  if (direct != null) {
    final r = pickFrom(direct);
    if (r != null) return r;
  }

  for (final entry in tripleMap.entries) {
    if (entry.key == fileUrl) continue;
    final r = pickFrom(entry.value);
    if (r != null) {
      debugPrint(
        '[isFileContentEncrypted] iv/encData found under fallback subject '
        '"${entry.key}" instead of "$fileUrl"',
      );
      return r;
    }
  }

  return null;
}

/// Decrypt the content of [fileUrl] in place on the server, replacing the
/// encrypted TTL payload with the plaintext that was originally written.

Future<void> decryptFileInPlace(
  String fileUrl, {
  bool isExternalRes = false,
}) async {
  debugPrint('[decryptFileInPlace] start url="$fileUrl" '
      'isExternalRes=$isExternalRes');
  final raw = utf8.decode(await getResource(fileUrl));
  final encMap = _extractEncFields(raw, fileUrl);

  if (encMap == null) {
    debugPrint(
      '[decryptFileInPlace] file is not in encrypted format, nothing to do: '
      '"$fileUrl"',
    );
    return;
  }

  final indKey = isExternalRes
      ? await KeyManager.getSharedIndividualKey(fileUrl)
      : await KeyManager.getIndividualKey(fileUrl);

  if (indKey == null) {
    throw Exception(
      'No individual encryption key available for "$fileUrl"; '
      'cannot decrypt the file for public/authenticated-user sharing.',
    );
  }

  var plaintext = decryptData(
    encMap.encData,
    indKey,
    IV.fromBase64(encMap.iv),
  );

  // Allow the host app to strip an additional application-level
  // encryption layer before the file is exposed publicly.

  final postHook = PublicSharingHooks.onPublicShareDecrypted;
  if (postHook != null) {
    debugPrint(
      '[decryptFileInPlace] applying app onPublicShareDecrypted hook',
    );
    plaintext = await postHook(fileUrl, plaintext);
  }

  await createResource(
    fileUrl,
    content: plaintext,
    contentType: ResourceContentType.turtleText,
  );
  debugPrint('[decryptFileInPlace] wrote plaintext (${plaintext.length} '
      'bytes) to "$fileUrl"');
}

/// Apply the [PublicSharingHooks.onPublicShareDecrypted] transformer to
/// the current (already-plaintext) bytes of [fileUrl] and write back any
/// resulting change.

Future<void> applyPublicShareDecryptedHookInPlace(String fileUrl) async {
  final hook = PublicSharingHooks.onPublicShareDecrypted;
  if (hook == null) {
    debugPrint(
      '[applyPublicShareDecryptedHookInPlace] no hook registered, '
      'nothing to do: "$fileUrl"',
    );
    return;
  }

  try {
    final current = utf8.decode(await getResource(fileUrl));
    final transformed = await hook(fileUrl, current);
    if (transformed == current) {
      debugPrint(
        '[applyPublicShareDecryptedHookInPlace] hook left content '
        'unchanged: "$fileUrl"',
      );
      return;
    }
    await createResource(
      fileUrl,
      content: transformed,
      contentType: ResourceContentType.turtleText,
    );
    debugPrint(
      '[applyPublicShareDecryptedHookInPlace] hook rewrote content '
      '(${transformed.length} bytes) for "$fileUrl"',
    );
  } on Object catch (e) {
    debugPrint(
      '[applyPublicShareDecryptedHookInPlace] hook failed for "$fileUrl": $e',
    );
  }
}

/// Encrypt the (currently plaintext) content of [fileUrl] in place using
/// the individual encryption key already recorded for the resource.

Future<void> encryptFileInPlace(
  String fileUrl, {
  bool isExternalRes = false,
}) async {
  debugPrint('[encryptFileInPlace] start url="$fileUrl" '
      'isExternalRes=$isExternalRes');
  final indKey = isExternalRes
      ? await KeyManager.getSharedIndividualKey(fileUrl)
      : await KeyManager.getIndividualKey(fileUrl);
  if (indKey == null) {
    debugPrint('[encryptFileInPlace] no individual key for "$fileUrl", '
        'leaving file as plaintext');
    return;
  }

  if (await isFileContentEncrypted(fileUrl)) {
    debugPrint('[encryptFileInPlace] file already encrypted, nothing to do: '
        '"$fileUrl"');
    return;
  }

  var plaintext = utf8.decode(await getResource(fileUrl));

  // Give the host app a chance to restore an inner application-level
  // encryption layer that was peeled off by [decryptFileInPlace] when
  // public/auth-user sharing was granted, so that at-rest state is
  // symmetric with what the app originally wrote via [writePod].

  final preHook = PublicSharingHooks.onPublicShareRevoked;
  if (preHook != null) {
    debugPrint(
      '[encryptFileInPlace] applying app onPublicShareRevoked hook',
    );
    plaintext = await preHook(fileUrl, plaintext);
  }

  final encContent = await getEncTTLStr(
    fileUrl: fileUrl,
    fileContent: plaintext,
    key: indKey,
    iv: IV.fromLength(16),
  );

  await createResource(
    fileUrl,
    content: encContent,
    contentType: ResourceContentType.turtleText,
  );
  debugPrint('[encryptFileInPlace] re-encrypted "$fileUrl"');
}
