/// Individual key management for encrypted resources.
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

import 'dart:async' show Completer;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Manages individual encryption keys for resources.

class IndividualKeyManager {
  // URL of the file with encrypted individual keys.

  static String? _indKeyUrl;

  // The encrypted (and decrypted) individual keys.
  // Dictionary key: URL of resource.

  static Map<String, IndKeyRecord>? _indKeyMap;

  // Serialises changes to the key file. Every change rewrites the file in
  // full, so two overlapping changes would race: the later PUT could land
  // first and be overwritten by an earlier, smaller snapshot of the map,
  // losing a key and with it the ability to decrypt the file it belongs to.
  // Holding this chain across both the in-memory update and the upload keeps
  // each upload a superset of the one before.

  static Future<void> _keyFileLock = Future<void>.value();

  // The load in progress, if any, so that concurrent readers share one
  // request for the key file rather than each fetching their own copy.

  static Future<void>? _loadInProgress;

  /// Clear all cached individual keys.

  static void clear() {
    _indKeyUrl = null;
    _indKeyMap = null;
    _loadInProgress = null;
  }

  /// Load encrypted individual keys.

  static Future<void> loadIndividualKeys({bool forceReload = false}) async {
    if (_indKeyMap != null && !forceReload) {
      return;
    }

    final pending = _loadInProgress;
    if (pending != null && !forceReload) {
      return pending;
    }

    final load = readIndKeyFile().then((map) {
      _indKeyMap = map;
    });

    _loadInProgress = load;

    try {
      await load;
    } finally {
      if (identical(_loadInProgress, load)) {
        _loadInProgress = null;
      }
    }
  }

  /// Run [action] with exclusive access to the key file.

  static Future<void> _withKeyFileLock(Future<void> Function() action) {
    final done = Completer<void>();
    final previous = _keyFileLock;
    _keyFileLock = done.future;

    return previous.then((_) => action()).whenComplete(done.complete);
  }

  /// Generate the content of indKeyFile and save it (on server).

  static Future<void> saveIndividualKeys(
    Map<String, IndKeyRecord>? indKeyMap,
  ) async {
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    await createResource(
      _indKeyUrl!,
      content: await genIndKeyTTLStr(_indKeyUrl!, indKeyMap),
    );
  }

  /// Retrieve the (decrypted) individual key for an existing resource.
  ///
  /// Return null if the corresponding key does not exist.

  static Future<Key?> getIndividualKey(
    String resourceUrl,
    Key masterKey,
  ) async {
    if (_indKeyMap == null) {
      await loadIndividualKeys();
    }

    assert(_indKeyMap != null);

    if (!_indKeyMap!.containsKey(resourceUrl)) {
      // Key not in own key map — allow caller to fall back to shared key map.
      return null;
    }

    final record = _indKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      record.key = Key.fromBase64(
        decryptData(
          record.encKeyBase64,
          masterKey,
          IV.fromBase64(record.ivBase64),
        ),
      );
      _indKeyMap![resourceUrl] = record;
    }
    return record.key!;
  }

  /// Add the (encrypted) individual key for file.

  static Future<void> addIndividualKey({
    required String resourcePath,
    required Key indKey,
    required Key masterKey,
    bool isFile = true,
  }) async {
    await addIndividualKeys(
      indKeys: {resourcePath: indKey},
      masterKey: masterKey,
      isFile: isFile,
    );
  }

  /// Add the (encrypted) individual keys for several resources at once,
  /// persisting the key file a single time.
  ///
  /// Every individual key lives in one file, `encryption/ind-keys.ttl`, which
  /// is rewritten in full on each change (a SPARQL PATCH is not usable here:
  /// CSS servers may answer 200 without persisting the triples). Registering
  /// keys one at a time therefore re-uploads the whole file per resource, and
  /// the file grows by one entry per encrypted file in the POD — so writing N
  /// new files costs O(N^2) bytes and N round trips of pure overhead. Adding
  /// the whole batch in one go reduces that to a single upload.

  static Future<void> addIndividualKeys({
    required Map<String, Key> indKeys,
    required Key masterKey,
    bool isFile = true,
  }) async {
    if (indKeys.isEmpty) {
      return;
    }

    await _withKeyFileLock(() async {
      if (_indKeyMap == null) {
        await loadIndividualKeys();
      }
      assert(_indKeyMap != null);

      for (final entry in indKeys.entries) {
        final resourcePath = entry.key;
        final resourceUrl =
            await (isFile ? getFileUrl : getDirUrl)(resourcePath);

        final iv = genRandIV();
        final encIndKey = encryptData(entry.value.base64, masterKey, iv);

        _indKeyMap![resourceUrl] = IndKeyRecord(
          resourcePath: resourcePath,
          encKeyBase64: encIndKey,
          ivBase64: iv.base64,
        )..key = entry.value;
      }

      // Use full PUT overwrite instead of SPARQL PATCH — CSS servers may
      // accept the PATCH request (HTTP 200) without actually persisting the
      // triples.
      await saveIndividualKeys(_indKeyMap);
    });
  }

  /// Whether an individual key is already registered for [resourceUrl].
  ///
  /// Loads the key file if it has not been read yet, but never writes.

  static Future<bool> hasIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await loadIndividualKeys();
    }
    return _indKeyMap!.containsKey(resourceUrl);
  }

  /// Remove the (encrypted) individual key for file.

  static Future<void> removeIndividualKey({
    required String resourcePath,
    bool isFile = true,
  }) async {
    final resourceUrl = await (isFile ? getFileUrl : getDirUrl)(resourcePath);

    await _withKeyFileLock(() async {
      if (_indKeyMap == null) {
        await loadIndividualKeys();
      }
      assert(_indKeyMap != null);

      if (_indKeyMap!.containsKey(resourceUrl)) {
        _indKeyMap!.remove(resourceUrl);

        // Use full PUT overwrite instead of SPARQL PATCH.
        await saveIndividualKeys(_indKeyMap);

        debugPrint('Deleted individual key for $resourcePath');
      } else {
        debugPrint(
          'Individual key for "$resourcePath" does not exist, do nothing.',
        );
      }
    });
  }

  /// Re-encrypt all individual keys with a new master key.

  static Future<void> reEncryptIndividualKeys(
    Key oldMasterKey,
    Key newMasterKey,
  ) async {
    if (_indKeyMap == null) {
      await loadIndividualKeys();
    }

    assert(_indKeyMap != null);

    if (_indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final resourceUrl = entry.key;
        final record = entry.value;

        // Decrypt with old key
        record.key ??= await getIndividualKey(resourceUrl, oldMasterKey);

        // Encrypt with new key
        final iv = genRandIV();
        final indKey = record.key;
        assert(indKey != null);

        record.ivBase64 = iv.base64;
        record.encKeyBase64 = encryptData(indKey!.base64, newMasterKey, iv);

        _indKeyMap![resourceUrl] = record;
      }
    }

    // Save the re-encrypted keys.

    await saveIndividualKeys(_indKeyMap);
  }

  /// Clear decrypted keys from memory.

  static void clearDecryptedKeys() {
    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final record in _indKeyMap!.values) {
        record.key = null;
      }
    }
  }

  /// Get the current individual key map.

  static Map<String, IndKeyRecord>? getIndKeyMap() => _indKeyMap;
}
