/// Read and write the profile of an arbitrary app folder on the user's POD.
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

import 'dart:convert' show base64, base64Decode, base64Encode, utf8;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:rdflib/rdflib.dart' show Literal, Namespace, URIRef;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/predicates.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart' show AccessMode;
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/enc_in_place.dart'
    show getEncTTLStrWithRandomIV;
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;
import 'package:solidpod/src/solid/utils/pod_paths.dart'
    show extractResourcePathFromUrl;
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;
import 'package:solidpod/src/solid/utils/session.dart'
    show getWebId, isUserLoggedIn;

// This module deliberately operates on an explicit app-root URL (the top-level
// folder of one app/domain on the POD) and an explicit security key, never on
// the global `KeyManager` / `appDirName`. Those globals are bound to the
// currently running app, so reading or writing another app's profile through
// them would either decrypt with the wrong key or corrupt the live session's
// cached key material. Everything here is self-contained: the app's own
// `encryption/enc-keys.ttl` and `encryption/ind-keys.ttl` provide the key
// material needed to decrypt and re-encrypt that app's `profile/` folder.

/// Thrown when an app folder has no `encryption/enc-keys.ttl`, meaning the app
/// has never set up encryption and therefore has no encrypted profile to read
/// with a security key.

class AppEncryptionNotSetupException implements Exception {
  /// Constructor.

  AppEncryptionNotSetupException(this.message);

  /// The error message.

  final String message;

  @override
  String toString() => 'AppEncryptionNotSetupException: $message';
}

/// The verified key material for one app, derived once from its security key.
///
/// Holds the AES master key used to unwrap the app's individual file keys, and
/// the key-derivation scheme [version] (1 = legacy sha256, 2 = Argon2id+HKDF).
/// Resolve it once via [verifyAppSecurityKey] and pass it to [readAppProfile]
/// and [writeAppProfile] so the expensive Argon2id derivation is not repeated.

class PodAppKey {
  /// Constructor.

  PodAppKey({required this.masterKey, required this.version});

  /// The AES master key derived from the app's security key.

  final Key masterKey;

  /// The key-derivation scheme version recorded on the POD.

  final int version;
}

/// The display name, avatar, and privacy of one app's profile.

class PodAppProfile {
  /// Constructor.

  PodAppProfile({this.displayName, this.avatarBytes, this.isPrivate = false});

  /// The display name, or null when none is stored.

  final String? displayName;

  /// The avatar PNG bytes, or null when none is stored.

  final Uint8List? avatarBytes;

  /// Whether the stored profile is encrypted (private) rather than plaintext.

  final bool isPrivate;
}

// Standard relative locations within an app folder.

const String _encKeysRelPath = '$encDir/$encKeyFile';
const String _indKeysRelPath = '$encDir/$indKeyFile';
const String _avatarRelPath = '$profileDir/$profilePictureFile';
const String _displayNameRelPath = '$profileDir/$displayNameFile';

// Ensure an app-root URL ends with a single trailing slash so relative
// resources can be appended directly.

String _normaliseRoot(String appRootUrl) =>
    appRootUrl.endsWith('/') ? appRootUrl : '$appRootUrl/';

// Derive the POD owner's base URL (e.g. `https://server/alice/`) from an
// app-root URL (e.g. `https://server/alice/myapp/`). POD-relative paths stored
// in `ind-keys.ttl` (e.g. `myapp/profile/avatar.ttl`) are anchored on this.

String _podOwnerBase(String appRootUrl) {
  final trimmed = appRootUrl.endsWith('/')
      ? appRootUrl.substring(0, appRootUrl.length - 1)
      : appRootUrl;
  final idx = trimmed.lastIndexOf('/');
  return idx < 0 ? '$trimmed/' : '${trimmed.substring(0, idx)}/';
}

// First string value of a triple object, which rdflib may surface as either a
// bare string or an iterable of strings.

String? _firstString(dynamic value) {
  if (value is String) return value;
  if (value is Iterable && value.isNotEmpty) {
    final first = value.first;
    if (first is String) return first;
  }
  return null;
}

// Find the predicate-object map of the first subject in [tripleMap] that
// carries [predicateUrl], preferring [preferredSubject] when present. This
// tolerates host rewrites where the document's subject URL differs from the
// resource URL it was fetched from.

Map<String, dynamic>? _subjectWith(
  Map<String, Map<String, dynamic>> tripleMap,
  String predicateUrl, {
  String? preferredSubject,
}) {
  if (preferredSubject != null) {
    final direct = tripleMap[preferredSubject];
    if (direct != null && direct.containsKey(predicateUrl)) return direct;
  }
  for (final entry in tripleMap.entries) {
    if (entry.value.containsKey(predicateUrl)) return entry.value;
  }
  return null;
}

/// Whether the app folder at [appRootUrl] has encryption set up (i.e. an
/// `encryption/enc-keys.ttl` file exists). When false the app stores only
/// plaintext data and its profile can be edited without a security key.

Future<bool> appHasEncryption(String appRootUrl) async {
  final encKeysUrl = '${_normaliseRoot(appRootUrl)}$_encKeysRelPath';
  return await checkResourceStatus(encKeysUrl) == ResourceStatus.exist;
}

/// Verify [securityKey] against the verification value stored in the app's
/// `encryption/enc-keys.ttl` and return the derived [PodAppKey].
///
/// Throws [AppEncryptionNotSetupException] if the app has no encryption set up,
/// and [SecurityKeyVerificationException] if the key is incorrect. Legacy
/// (version 1) PODs are read under their existing scheme and are NOT migrated
/// to version 2 here — migration mutates the key files and is the owning app's
/// responsibility at its own login.

Future<PodAppKey> verifyAppSecurityKey(
  String appRootUrl,
  String securityKey,
) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to read from POD');
  }

  final root = _normaliseRoot(appRootUrl);
  final encKeysUrl = '$root$_encKeysRelPath';

  if (await checkResourceStatus(encKeysUrl) != ResourceStatus.exist) {
    throw AppEncryptionNotSetupException(
      'No encryption keys found for the app at $root',
    );
  }

  final tripleMap =
      turtleToTripleMap(utf8.decode(await getResource(encKeysUrl)));
  final map = _subjectWith(
    tripleMap,
    getPredicateUrl(encKeyPred),
    preferredSubject: encKeysUrl,
  );

  if (map == null) {
    throw AppEncryptionNotSetupException(
      'Malformed encryption keys file at $encKeysUrl',
    );
  }

  final verificationKey = _firstString(map[getPredicateUrl(encKeyPred)]);
  if (verificationKey == null) {
    throw AppEncryptionNotSetupException(
      'No verification key found in $encKeysUrl',
    );
  }

  final saltB64 = _firstString(map[getPredicateUrl(saltPred)]);
  final versionStr = _firstString(map[getPredicateUrl(keyVersionPred)]);
  final version = versionStr == null ? 1 : int.parse(versionStr);

  if (version >= 2) {
    if (saltB64 == null) {
      throw Exception('Missing key-derivation salt for a version $version POD');
    }
    final keys = await deriveKeys(securityKey, base64.decode(saltB64));
    if (!constantTimeEquals(verificationKey, keys.verificationKey)) {
      throw SecurityKeyVerificationException(
          'Unable to verify the security key');
    }
    return PodAppKey(masterKey: keys.masterKey, version: version);
  }

  // Legacy (version 1): verify with the old sha224 scheme.

  if (!verifySecurityKey(securityKey, verificationKey)) {
    throw SecurityKeyVerificationException('Unable to verify the security key');
  }
  return PodAppKey(masterKey: genLegacyMasterKey(securityKey), version: 1);
}

// Read the app's `ind-keys.ttl` into a map of absolute-resource-URL ->
// individual-key record. Returns an empty map when the file is absent. Each
// record is re-keyed by the URL derived from its stored POD-relative path so
// lookups are stable regardless of how the subject was serialised.

Future<Map<String, IndKeyRecord>> _loadIndKeyRecords(String root) async {
  final indKeysUrl = '$root$_indKeysRelPath';
  final result = <String, IndKeyRecord>{};

  if (await checkResourceStatus(indKeysUrl) != ResourceStatus.exist) {
    return result;
  }

  final tripleMap =
      turtleToTripleMap(utf8.decode(await getResource(indKeysUrl)));
  final ownerBase = _podOwnerBase(root);

  for (final entry in tripleMap.entries) {
    final v = entry.value;
    final sessionKey = _firstString(v[getPredicateUrl(sessionKeyPred)]);
    final iv = _firstString(v[getPredicateUrl(ivPred)]);
    final relPath = _firstString(v[getPredicateUrl(pathPred)]);
    if (sessionKey == null || iv == null || relPath == null) continue;

    result['$ownerBase$relPath'] = IndKeyRecord(
      resourcePath: relPath,
      encKeyBase64: sessionKey,
      ivBase64: iv,
    );
  }

  return result;
}

// Locate the individual-key record for [fileUrl], tolerating host rewrites by
// also matching on the resource path suffix.

IndKeyRecord? _recordFor(Map<String, IndKeyRecord> records, String fileUrl) {
  final direct = records[fileUrl];
  if (direct != null) return direct;

  final relSuffix = Uri.parse(fileUrl).pathSegments.skip(1).join('/');
  for (final record in records.values) {
    if (relSuffix.endsWith(record.resourcePath) ||
        record.resourcePath.endsWith(relSuffix)) {
      return record;
    }
  }
  return null;
}

// Decrypt an individual key from its record using the master key.

Key _decryptIndKey(IndKeyRecord record, Key masterKey) => Key.fromBase64(
      decryptData(
        record.encKeyBase64,
        masterKey,
        IV.fromBase64(record.ivBase64),
      ),
    );

// Result of reading one profile file: the (decrypted) turtle content and
// whether it was encrypted at rest.

class _FileRead {
  _FileRead(this.content, this.wasEncrypted);
  final String? content;
  final bool wasEncrypted;
}

// Read and, if necessary, decrypt one profile file. Returns null content when
// the file does not exist or cannot be decrypted.

Future<_FileRead> _readProfileFile(
  String fileUrl,
  PodAppKey? key,
  Map<String, IndKeyRecord> indKeys,
) async {
  if (await checkResourceStatus(fileUrl) != ResourceStatus.exist) {
    return _FileRead(null, false);
  }

  final raw = utf8.decode(await getResource(fileUrl));

  Map<String, Map<String, dynamic>> tripleMap;
  try {
    tripleMap = turtleToTripleMap(raw);
  } on Object catch (e) {
    debugPrint('[crossAppProfile] failed to parse "$fileUrl": $e');
    return _FileRead(raw, false);
  }

  // Detect the solidpod encrypted-TTL wrapper (iv + encData). It is normally
  // anchored on the file URL, but fall back to any subject for robustness.

  final encSubject = _subjectWith(
    tripleMap,
    getPredicateUrl(encDataPred),
    preferredSubject: fileUrl,
  );
  final ivStr = encSubject == null
      ? null
      : _firstString(encSubject[getPredicateUrl(ivPred)]);
  final encDataStr = encSubject == null
      ? null
      : _firstString(encSubject[getPredicateUrl(encDataPred)]);

  // Plaintext file.

  if (ivStr == null || encDataStr == null) {
    return _FileRead(raw, false);
  }

  // Encrypted file: unwrap with the individual key.

  if (key == null) {
    debugPrint('[crossAppProfile] "$fileUrl" is encrypted but no key supplied');
    return _FileRead(null, true);
  }

  final record = _recordFor(indKeys, fileUrl);
  if (record == null) {
    debugPrint('[crossAppProfile] no individual key for "$fileUrl"');
    return _FileRead(null, true);
  }

  try {
    final indKey = _decryptIndKey(record, key.masterKey);
    final plaintext = decryptData(encDataStr, indKey, IV.fromBase64(ivStr));
    return _FileRead(plaintext, true);
  } on Object catch (e) {
    debugPrint('[crossAppProfile] failed to decrypt "$fileUrl": $e');
    return _FileRead(null, true);
  }
}

// Find the first display-name literal (foaf:name then vcard:fn) in a profile
// turtle whose subject is the user's WebID.

String? _extractDisplayName(String ttl) {
  Map<String, Map<String, dynamic>> map;
  try {
    map = turtleToTripleMap(ttl);
  } catch (_) {
    return null;
  }
  for (final pred in [FoafPredicate.name.value, VcardPredicate.fn.value]) {
    for (final entry in map.values) {
      final value = _firstString(entry[pred]);
      if (value != null && value.trim().isNotEmpty) return value;
    }
  }
  return null;
}

// Decode the vcard:hasPhoto base64 data URI in a profile turtle to PNG bytes.

Uint8List? _extractAvatarBytes(String ttl) {
  Map<String, Map<String, dynamic>> map;
  try {
    map = turtleToTripleMap(ttl);
  } catch (_) {
    return null;
  }

  String? photo;
  for (final entry in map.values) {
    photo = _firstString(entry[VcardPredicate.hasPhoto.value]);
    if (photo != null && photo.isNotEmpty) break;
  }
  if (photo == null || photo.isEmpty) return null;

  const marker = ';base64,';
  final idx = photo.indexOf(marker);
  if (!photo.startsWith('data:') || idx < 0) return null;

  try {
    return base64Decode(photo.substring(idx + marker.length));
  } catch (e) {
    debugPrint('[crossAppProfile] failed to decode avatar: $e');
    return null;
  }
}

// Build the linked-data turtle for a display name, anchored on the WebID so it
// stays interoperable with other agents. Mirrors solidui's SolidProfileService.

String _buildDisplayNameTtl(String webId, String name) {
  final subject = URIRef(webId.isEmpty ? '#me' : webId);
  final triples = <URIRef, Map<URIRef, dynamic>>{
    subject: {
      FoafPredicate.name.uriRef: Literal(name),
      VcardPredicate.fn.uriRef: Literal(name),
    },
  };
  // rdflib auto-binds foaf:, so only the vcard prefix needs registering.
  return tripleMapToTurtle(
    triples,
    bindNamespaces: {'vcard': Namespace(ns: vcard)},
  );
}

// Build the linked-data turtle embedding the avatar as a base64 data URI.

String _buildAvatarTtl(String webId, Uint8List pngBytes) {
  final subject = URIRef(webId.isEmpty ? '#me' : webId);
  final dataUri = 'data:image/png;base64,${base64Encode(pngBytes)}';
  final triples = <URIRef, Map<URIRef, dynamic>>{
    subject: {
      VcardPredicate.hasPhoto.uriRef: URIRef(dataUri),
    },
  };
  return tripleMapToTurtle(
    triples,
    bindNamespaces: {'vcard': Namespace(ns: vcard)},
  );
}

/// Read the profile (display name + avatar) of the app folder at [appRootUrl].
///
/// Pass [key] (from [verifyAppSecurityKey]) for encryption-enabled apps; pass
/// null for plaintext-only apps. Missing files yield null fields rather than an
/// error, so an app with no profile is a valid empty result.

Future<PodAppProfile> readAppProfile(
  String appRootUrl, {
  PodAppKey? key,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to read from POD');
  }

  final root = _normaliseRoot(appRootUrl);
  final indKeys =
      key == null ? <String, IndKeyRecord>{} : await _loadIndKeyRecords(root);

  final nameRead =
      await _readProfileFile('$root$_displayNameRelPath', key, indKeys);
  final avatarRead =
      await _readProfileFile('$root$_avatarRelPath', key, indKeys);

  return PodAppProfile(
    displayName: nameRead.content == null
        ? null
        : _extractDisplayName(nameRead.content!),
    avatarBytes: avatarRead.content == null
        ? null
        : _extractAvatarBytes(avatarRead.content!),
    isPrivate: nameRead.wasEncrypted || avatarRead.wasEncrypted,
  );
}

/// Write the profile of the app folder at [appRootUrl].
///
/// When [private] is true the files are encrypted with the app's own
/// individual keys (which requires [key]); otherwise they are written as
/// plaintext linked data. The `profile/` folder and its ACL are created if
/// needed and the ACL is set to match [private] (owner-only vs public read).
///
/// - [displayName]: written when non-null. An empty string clears it to empty.
/// - [avatarBytes]: written when non-null and [removeAvatar] is false.
/// - [removeAvatar]: deletes the avatar resource when true.

Future<void> writeAppProfile(
  String appRootUrl, {
  PodAppKey? key,
  String? displayName,
  Uint8List? avatarBytes,
  bool removeAvatar = false,
  required bool private,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException('User must be logged in to write to POD');
  }
  if (private && key == null) {
    throw ArgumentError(
        'A verified key is required to write a private profile');
  }

  final root = _normaliseRoot(appRootUrl);
  final profileDirUrl = '$root$profileDir/';
  final webId = await getWebId() ?? '';

  // Ensure the profile folder exists.

  if (await checkResourceStatus(profileDirUrl, isFile: false) ==
      ResourceStatus.notExist) {
    await createResource(
      profileDirUrl,
      isFile: false,
      contentType: ResourceContentType.directory,
    );
  }

  // Set the folder ACL to match the chosen visibility.

  final aclTurtle = await genAclTurtle(
    profileDirUrl,
    isFile: false,
    publicAccess: private ? const {} : const {AccessMode.read},
  );
  await createResource('$profileDirUrl.acl', content: aclTurtle);

  // Load the app's individual keys once and ensure a key exists for every file
  // we are about to write privately. Persist the key file before the data
  // files so a partially completed write never leaves an undecryptable file.

  final indKeys =
      private ? await _loadIndKeyRecords(root) : <String, IndKeyRecord>{};
  var indKeysChanged = false;

  Future<Key> ensureIndKey(String fileUrl) async {
    final existing = _recordFor(indKeys, fileUrl);
    if (existing != null) return _decryptIndKey(existing, key!.masterKey);

    final indKey = genRandIndividualKey();
    final iv = genRandIV();
    final relPath = await extractResourcePathFromUrl(fileUrl);
    indKeys[fileUrl] = IndKeyRecord(
      resourcePath: relPath,
      encKeyBase64: encryptData(indKey.base64, key!.masterKey, iv),
      ivBase64: iv.base64,
    );
    indKeysChanged = true;
    return indKey;
  }

  // Build the content for each file first (this may register new individual
  // keys), then flush the key file, then write the data files.

  final pending = <({String url, String content})>[];

  Future<String> wrap(String fileUrl, String innerTtl) async => private
      ? await getEncTTLStrWithRandomIV(
          fileUrl: fileUrl,
          fileContent: innerTtl,
          key: await ensureIndKey(fileUrl),
        )
      : innerTtl;

  if (displayName != null) {
    final fileUrl = '$root$_displayNameRelPath';
    final content =
        await wrap(fileUrl, _buildDisplayNameTtl(webId, displayName));
    pending.add((url: fileUrl, content: content));
  }

  if (!removeAvatar && avatarBytes != null) {
    final fileUrl = '$root$_avatarRelPath';
    final content = await wrap(fileUrl, _buildAvatarTtl(webId, avatarBytes));
    pending.add((url: fileUrl, content: content));
  }

  if (indKeysChanged) {
    final indKeysUrl = '$root$_indKeysRelPath';
    await createResource(
      indKeysUrl,
      content: await genIndKeyTTLStr(indKeysUrl, indKeys),
    );
  }

  for (final file in pending) {
    await createResource(
      file.url,
      content: file.content,
      contentType: ResourceContentType.turtleText,
    );
  }

  // Delete the avatar (and any per-file ACL) when requested.

  if (removeAvatar) {
    final avatarUrl = '$root$_avatarRelPath';
    if (await checkResourceStatus(avatarUrl) == ResourceStatus.exist) {
      await deleteResource(avatarUrl, ResourceContentType.turtleText);
      final avatarAclUrl = '$avatarUrl.acl';
      if (await checkResourceStatus(avatarAclUrl) == ResourceStatus.exist) {
        await deleteResource(avatarAclUrl, ResourceContentType.turtleText);
      }
    }
  }
}
