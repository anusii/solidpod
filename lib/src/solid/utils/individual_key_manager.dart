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

  /// Clear all cached individual keys.

  static void clear() {
    _indKeyUrl = null;
    _indKeyMap = null;
  }

  /// Load encrypted individual keys.

  static Future<void> loadIndividualKeys({bool forceReload = false}) async {
    if (_indKeyMap != null && !forceReload) {
      return;
    }

    _indKeyMap = await readIndKeyFile();
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
    if (_indKeyMap == null || _indKeyMap!.isEmpty) {
      await loadIndividualKeys();
    }

    assert(_indKeyMap != null);

    // [20260408 jesscmoore] Require individual key map _indKeyMap
    // to contain IndividualKeyRecord object for resourceUrl,
    // to avoid readPod returning undecrypted files if
    // it fails to find a IndividualKeyRecord.
    //
    // if (!_indKeyMap!.containsKey(resourceUrl)) {
    //   return null;
    // }

    assert(
      _indKeyMap!.containsKey(resourceUrl),
      'Individual key map does not contain resourceUrl: $resourceUrl\n${_indKeyMap.toString()}',
    );

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
    final resourceUrl = await (isFile ? getFileUrl : getDirUrl)(resourcePath);

    if (_indKeyMap == null) {
      await loadIndividualKeys();
    }
    assert(_indKeyMap != null);

    final iv = genRandIV();
    final encIndKey = encryptData(indKey.base64, masterKey, iv);

    final record = IndKeyRecord(
      resourcePath: resourcePath,
      encKeyBase64: encIndKey,
      ivBase64: iv.base64,
    );
    _indKeyMap![resourceUrl] = record;

    final query = await getIndKeyQuery(
      record,
      operation: SparqlOperation.insert,
      isFile: isFile,
    );
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    await updateFileByQuery(_indKeyUrl!, query);
  }

  /// Remove the (encrypted) individual key for file.

  static Future<void> removeIndividualKey({
    required String resourcePath,
    bool isFile = true,
  }) async {
    final resourceUrl = await (isFile ? getFileUrl : getDirUrl)(resourcePath);
    if (_indKeyMap == null) {
      await loadIndividualKeys();
    }
    assert(_indKeyMap != null);

    if (_indKeyMap!.containsKey(resourceUrl)) {
      final record = _indKeyMap!.remove(resourceUrl);
      assert(record != null);

      final query = await getIndKeyQuery(
        record!,
        operation: SparqlOperation.delete,
        isFile: isFile,
      );
      _indKeyUrl ??= await getFileUrl(await getIndKeyPath());
      await updateFileByQuery(_indKeyUrl!, query);

      debugPrint('Deleted $record');
    } else {
      debugPrint(
        'Individual key for "$resourcePath" does not exist, do nothing.',
      );
    }
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
