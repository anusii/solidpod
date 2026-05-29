/// Read/write the per-pair encrypted notification file in the current
/// user's POD.
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

import 'dart:convert';

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart' show AccessMode;
import 'package:solidpod/src/solid/models/pod_notification.dart';
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart' show genRandIV;
import 'package:solidpod/src/solid/utils/notification_pair_id.dart';
import 'package:solidpod/src/solid/utils/permission.dart' show genAclTurtle;

/// Read/write protocol for a single-file-per-pair encrypted notification
/// outbox.
///
/// Each pair (A, B) has exactly **one** encrypted JSON file in each POD:
///   - In A's POD: `appDir/notifications/<derivePairId(B)>.json` —
///     contains every notification A has ever sent to B.
///   - In B's POD: `appDir/notifications/<derivePairId(A)>.json` —
///     contains every notification B has ever sent to A.
///
/// On every send the owner performs a read-decrypt-append-encrypt-write
/// cycle on their own outbox file. This is safe because the file lives
/// in the sender's own POD where they hold full Write access. The
/// partner reads it via a fully-authenticated cross-POD GET, made
/// possible by a per-file ACL that grants the partner Read access while
/// preserving owner-only Write/Control.
///
/// On-disk wrapper (the envelope that travels cross-POD):
/// ```json
/// {
///   "v": 1,
///   "iv": "<base64 AES IV>",
///   "data": "<base64 AES-encrypted payload>"
/// }
/// ```
///
/// Decrypted payload:
/// ```json
/// {
///   "notifications": [
///     {"id": ..., "title": ..., ...},
///     ...
///   ]
/// }
/// ```

class NotificationPairOutbox {
  /// POD-relative path of the outbox file whose partner has [pairId].

  static String _outboxPath(String pairId) =>
      [appDirName, notificationDir, '$pairId.json'].join('/');

  /// URL of the *current user's* outbox file for [partnerWebId].

  static Future<String> outboxUrlFor(String partnerWebId) async {
    final pairId = derivePairId(partnerWebId);
    return getFileUrl(_outboxPath(pairId));
  }

  /// URL of the *partner's* outbox file as written by them and read by
  /// us. By the symmetric naming convention this file lives in the
  /// partner's POD and is named after the current user's pairId.

  static String partnerOutboxUrl({
    required String partnerWebId,
    required String selfWebId,
  }) {
    final selfPairId = derivePairId(selfWebId);
    return partnerWebId.replaceAll(
      profCard,
      '$appDirName/$notificationDir/$selfPairId.json',
    );
  }

  /// Decode the on-disk wrapper produced by [_wrap] back into an
  /// (iv, ciphertext) pair.

  static ({IV iv, String data}) _unwrap(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (
      iv: IV.fromBase64(json['iv'] as String),
      data: json['data'] as String,
    );
  }

  /// Encode an encrypted payload along with its IV into a stable JSON
  /// envelope. Bump `v` and keep readers backwards-compatible when the
  /// envelope shape changes.

  static String _wrap(IV iv, String ciphertext) => jsonEncode({
        'v': 1,
        'iv': iv.base64,
        'data': ciphertext,
      });

  /// GET and AES-decrypt the notifications stored at [outboxUrl] using
  /// [pairKey]. [outboxUrl] may belong to a different POD — the caller's
  /// authenticated GET handles cross-POD reads transparently as long as
  /// the file's ACL grants the caller Read access.
  ///
  /// Returns an empty list when the file does not exist yet (the normal
  /// "no messages have been sent in this direction" state).

  static Future<List<PodNotification>> readNotifications({
    required String outboxUrl,
    required Key pairKey,
  }) async {
    final status = await checkResourceStatus(outboxUrl);
    if (status != ResourceStatus.exist) return const [];

    final raw = utf8.decode(await getResource(outboxUrl));
    if (raw.trim().isEmpty) return const [];

    final wrapper = _unwrap(raw);
    final plain = decryptData(wrapper.data, pairKey, wrapper.iv);
    final json = jsonDecode(plain) as Map<String, dynamic>;
    return (json['notifications'] as List? ?? const [])
        .map((e) => PodNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Append [notification] to the *current user's* outbox file for the
  /// pair identified by [partnerWebId] and persist the encrypted result.
  ///
  /// Performs a read-decrypt-append-encrypt-write cycle as required: the
  /// existing notifications are loaded and decrypted, the new entry is
  /// appended, and the entire array is re-encrypted with a fresh IV
  /// before being PUT back to the same URL. This is only safe to call
  /// for the *sender's own* outbox — cross-POD writes against a
  /// partner's outbox would 403 (no Write access).

  static Future<void> appendNotification({
    required String partnerWebId,
    required Key pairKey,
    required PodNotification notification,
  }) async {
    final url = await outboxUrlFor(partnerWebId);

    final existing = await readNotifications(
      outboxUrl: url,
      pairKey: pairKey,
    );

    final updated = [...existing, notification];
    final body = jsonEncode({
      'notifications': [for (final n in updated) n.toJson()],
    });

    final iv = genRandIV();
    final ciphertext = encryptData(body, pairKey, iv);

    // PUT (replaceIfExist: true) so the same file is overwritten in
    // place rather than a new file being created beside it.

    await createResource(
      url,
      content: _wrap(iv, ciphertext),
      contentType: ResourceContentType.auto,
    );
  }

  /// Ensure the outbox file at [outboxUrl] has a per-file ACL that
  /// grants the partner Read access while keeping owner-only Write/
  /// Control. Idempotent — overwriting an existing ACL with the same
  /// content is harmless and tolerates the user editing the ACL out of
  /// band.
  ///
  /// Errors are logged but never propagated: a failure to write the ACL
  /// degrades the partner's ability to read but does not invalidate the
  /// stored notification, and the next send call will retry the ACL.

  static Future<void> ensureOutboxAcl({
    required String outboxUrl,
    required String partnerWebId,
  }) async {
    try {
      final aclUrl = '$outboxUrl.acl';
      final acl = await genAclTurtle(
        outboxUrl,
        thirdPartyAccess: {
          partnerWebId: {AccessMode.read},
        },
      );
      await createResource(aclUrl, content: acl);
    } on Object catch (e) {
      debugPrint(
        'NotificationPairOutbox: failed to write outbox ACL for $outboxUrl: $e',
      );
    }
  }
}
