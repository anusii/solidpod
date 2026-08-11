/// Web-only secure cache for the security key.
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

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const String _dbName = 'solidpod_secure';
const String _storeName = 'kv';
const String _wrapKeyId = 'security_key_wrap_key';
const String _ivId = 'security_key_iv';
const String _ctId = 'security_key_ct';

/// Web implementation of the security-key cache (see the library doc comment).

class WebSecureKeyCache {
  static web.SubtleCrypto get _subtle => web.window.crypto.subtle;

  // JS object literals for the Web Crypto algorithm parameters. Built with
  // setProperty rather than an extension-type factory so the sunset
  // dart_code_metrics unused-code check (which cannot parse extension types)
  // does not report false positives.

  static JSObject _aesKeyGenParams() => JSObject()
    ..setProperty('name'.toJS, 'AES-GCM'.toJS)
    ..setProperty('length'.toJS, 256.toJS);

  static JSObject _aesGcmParams(JSAny iv) => JSObject()
    ..setProperty('name'.toJS, 'AES-GCM'.toJS)
    ..setProperty('iv'.toJS, iv);

  // IndexedDB helpers.

  static Future<web.IDBDatabase> _openDb() {
    final completer = Completer<web.IDBDatabase>();
    final req = web.window.indexedDB.open(_dbName, 1);
    req.onupgradeneeded = ((web.Event _) {
      final db = req.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }).toJS;
    req.onsuccess = ((web.Event _) {
      completer.complete(req.result as web.IDBDatabase);
    }).toJS;
    req.onerror = ((web.Event _) {
      completer.completeError(StateError('IndexedDB open failed'));
    }).toJS;
    return completer.future;
  }

  static Future<JSAny?> _await(web.IDBRequest req) {
    final completer = Completer<JSAny?>();
    req.onsuccess = ((web.Event _) {
      completer.complete(req.result);
    }).toJS;
    req.onerror = ((web.Event _) {
      completer.completeError(StateError('IndexedDB request failed'));
    }).toJS;
    return completer.future;
  }

  static Future<void> _put(web.IDBDatabase db, String id, JSAny value) async {
    final tx = db.transaction(_storeName.toJS, 'readwrite');
    await _await(tx.objectStore(_storeName).put(value, id.toJS));
  }

  static Future<JSAny?> _get(web.IDBDatabase db, String id) async {
    final tx = db.transaction(_storeName.toJS, 'readonly');
    return _await(tx.objectStore(_storeName).get(id.toJS));
  }

  // Wrapping key.

  static Future<web.CryptoKey> _getOrCreateWrapKey(web.IDBDatabase db) async {
    final existing = await _get(db, _wrapKeyId);
    if (existing != null) {
      // Only CryptoKey objects are ever stored under this id.

      return existing as web.CryptoKey;
    }
    final key = (await _subtle
        .generateKey(
          _aesKeyGenParams(),
          false, // extractable: false — bytes can never be exported.
          <JSString>['encrypt'.toJS, 'decrypt'.toJS].toJS,
        )
        .toDart) as web.CryptoKey;
    await _put(db, _wrapKeyId, key);
    return key;
  }

  // Public API.

  /// Encrypt and persist [securityKey] under the non-extractable wrapping key.

  static Future<void> write(String securityKey) async {
    final db = await _openDb();
    final wrapKey = await _getOrCreateWrapKey(db);

    final iv =
        (web.window.crypto.getRandomValues(Uint8List(12).toJS) as JSUint8Array)
            .toDart;
    final ctBuf = (await _subtle
        .encrypt(
          _aesGcmParams(iv.toJS),
          wrapKey,
          Uint8List.fromList(utf8.encode(securityKey)).toJS,
        )
        .toDart) as JSArrayBuffer;

    await _put(db, _ivId, iv.toJS);
    await _put(db, _ctId, ctBuf.toDart.asUint8List().toJS);
  }

  /// Decrypt and return the cached security key, or null if none/undecryptable.

  static Future<String?> read() async {
    final db = await _openDb();
    final keyAny = await _get(db, _wrapKeyId);
    final ivAny = await _get(db, _ivId);
    final ctAny = await _get(db, _ctId);
    if (keyAny == null || ivAny == null || ctAny == null) {
      return null;
    }
    final ptBuf = (await _subtle
        .decrypt(
          _aesGcmParams(ivAny),
          keyAny as web.CryptoKey,
          ctAny as JSUint8Array,
        )
        .toDart) as JSArrayBuffer;
    return utf8.decode(ptBuf.toDart.asUint8List());
  }

  /// Remove all cached security-key material (key handle, IV, ciphertext).

  static Future<void> delete() async {
    final db = await _openDb();
    for (final id in const [_wrapKeyId, _ivId, _ctId]) {
      final tx = db.transaction(_storeName.toJS, 'readwrite');
      await _await(tx.objectStore(_storeName).delete(id.toJS));
    }
  }

  /// Whether a wrapped security key is currently cached.

  static Future<bool> has() async {
    final db = await _openDb();
    final key = await _get(db, _wrapKeyId);
    final ct = await _get(db, _ctId);
    return key != null && ct != null;
  }
}
