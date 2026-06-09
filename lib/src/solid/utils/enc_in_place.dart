/// In-place encryption and decryption helpers for the public/auth-user
/// sharing lifecycle.
///
// Time-stamp: <Thursday 2026-01-22 11:12:44 +1100 Graham Williams>
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
import 'package:solidpod/src/solid/utils/key_helper.dart' show getPredicateUrl;
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/pod_paths.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Encrypt a given data string and format to TTL.

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

/// Extract the `(iv, encData)` pair from the encrypted-TTL wrapper written
/// by [getEncTTLStr] for [fileUrl], or return `null` if [rawTtl] is not a
/// solidpod-encrypted document. Used by the in-place sharing-lifecycle
/// helpers below to recover the ciphertext alongside its IV in one pass.

({String iv, String encData})? _extractEncFields(
  String rawTtl,
  String fileUrl,
) {
  Map<String, Map<String, dynamic>> tripleMap;
  try {
    tripleMap = turtleToTripleMap(rawTtl);
  } on Object catch (e) {
    debugPrint('[_extractEncFields] failed to parse "$fileUrl": $e');
    return null;
  }

  final ivKey = getPredicateUrl(ivPred);
  final encKey = getPredicateUrl(encDataPred);

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

  // Fall back to any subject in the document. This covers ttl that was
  // written under a slightly different subject URL (e.g. due to a host
  // rewrite between writePod and the current read).

  for (final entry in tripleMap.entries) {
    if (entry.key == fileUrl) continue;
    final r = pickFrom(entry.value);
    if (r != null) {
      debugPrint(
        '[_extractEncFields] iv/encData found under fallback subject '
        '"${entry.key}" instead of "$fileUrl"',
      );
      return r;
    }
  }

  return null;
}

/// Decrypt the content of [fileUrl] in place on the server, replacing the
/// encrypted TTL payload with the plaintext that was originally written.
///
/// Intended for use by [grantPermission] when sharing a file with the
/// Public or Authenticated User class: those recipients cannot be issued
/// a per-recipient encryption key, so the only way for them to actually
/// read the resource by navigating to its URL is for the file itself to
/// be plaintext on the server. The individual key is intentionally kept
/// in `ind-keys.ttl` so that the file can be re-encrypted later by
/// [encryptFileInPlace] if public/auth-user access is revoked.
///
/// After unwrapping solidpod's own encrypted-TTL layer, the
/// [PublicSharingHooks.onPublicShareDecrypted] hook (if registered) is
/// applied so that a host app can also strip an application-level
/// encryption layer (e.g. NotePod's per-note noteContent ciphertext)
/// before the bytes are exposed to anonymous readers.
///
/// No-op when the file is not currently in the encrypted TTL format.
/// Throws when the individual encryption key cannot be obtained — the
/// caller is responsible for deciding whether to surface that to the
/// user or skip the publish step.

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
///
/// Used by [grantPermission] when the outer encrypted-TTL wrapper has
/// already been removed (e.g. by an older solidpod that decrypted the
/// file but didn't run the application-level hook). Without this, a
/// file that was left in such a mixed state would never have its inner
/// ciphertext stripped.

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
///
/// The counterpart of [decryptFileInPlace], called by [revokePermission]
/// when public/auth-user access is removed so that the resource's
/// at-rest representation is restored to what the host app originally
/// wrote via `writePod`. No-op when the file is already in the
/// encrypted TTL format or when no individual key is available
/// (i.e. the file was always plaintext at rest).
///
/// The [PublicSharingHooks.onPublicShareRevoked] hook (if registered)
/// is applied before re-wrapping so that the host app can restore the
/// application-level encryption layer that [decryptFileInPlace] peeled
/// off when sharing was granted.

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

  final raw = utf8.decode(await getResource(fileUrl));
  if (_extractEncFields(raw, fileUrl) != null) {
    debugPrint('[encryptFileInPlace] file already encrypted, nothing to do: '
        '"$fileUrl"');
    return;
  }

  var plaintext = raw;

  // Give the host app a chance to restore an inner application-level
  // encryption layer that was peeled off by [decryptFileInPlace] when
  // public/auth-user sharing was granted, so that at-rest state is
  // symmetric with what the app originally wrote via writePod.

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

/// Returns `true` when [fileUrl] currently holds an encrypted-TTL payload
/// written by [getEncTTLStr]. Cheaper than [getFileEncryptionStatus] when
/// the caller only needs the boolean and is happy to silently treat any
/// fetch / parse failure as "not encrypted".

Future<bool> isFileContentEncrypted(String fileUrl) async {
  if (!fileUrl.toLowerCase().endsWith('.ttl')) {
    return false;
  }
  try {
    if (await checkResourceStatus(fileUrl) != ResourceStatus.exist) {
      return false;
    }
    final raw = utf8.decode(await getResource(fileUrl));
    return _extractEncFields(raw, fileUrl) != null;
  } on Object catch (e) {
    debugPrint('[isFileContentEncrypted] unable to inspect "$fileUrl": $e');
    return false;
  }
}
