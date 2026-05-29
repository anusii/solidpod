/// Functions to fetch (i.e. receive) notifications from every paired
/// sender's POD.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/models/pod_notification.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart' show isUserLoggedIn;
import 'package:solidpod/src/solid/utils/notification_pair_key_manager.dart';
import 'package:solidpod/src/solid/utils/notification_pair_outbox.dart';

/// Pull every notification visible to the currently logged-in user.
///
/// Flow:
///   1. Scan the user's own `notifications/` folder for pending
///      `invite-from-<pairId>.json` files dropped by senders during
///      their first contact, decrypt each one with the user's RSA
///      private key, persist the recovered K_AB under the encryption
///      folder, and delete the consumed invite.
///   2. Enumerate the user's encryption folder for known pair keys.
///      Each `notification-<pairId>.json` file records the partner
///      WebID and is what makes the pair durable across logins.
///   3. For every known partner, perform a cross-POD authenticated GET
///      against the partner's outbox file (which lives in their POD at
///      `<partnerPOD>/<appDir>/notifications/<selfPairId>.json`),
///      AES-decrypt the body with K_AB, and merge the notifications
///      into the returned list.
///
/// Returns an empty list when the user is not logged in.

Future<List<PodNotification>> fetchNotifications() async {
  if (!await isUserLoggedIn()) return const [];

  final selfWebId = await AuthDataManager.getWebId();
  if (selfWebId == null || selfWebId.isEmpty) return const [];

  await _processPendingInvites();

  final pairs = await _listKnownPairs();
  final all = <PodNotification>[];

  for (final pair in pairs) {
    try {
      final outboxUrl = NotificationPairOutbox.partnerOutboxUrl(
        partnerWebId: pair.partnerWebId,
        selfWebId: selfWebId,
      );

      final notifications = await NotificationPairOutbox.readNotifications(
        outboxUrl: outboxUrl,
        pairKey: pair.key,
      );
      all.addAll(notifications);
    } on Object catch (e) {
      // Failures for one partner should not stop the rest. Surfaced to
      // the console only — UI shows whatever decoded successfully.

      debugPrint(
        'fetchNotifications: failed to read pair with ${pair.partnerWebId}: $e',
      );
    }
  }

  return all;
}

/// Walk the current user's notifications folder, decrypt every pending
/// `invite-from-<pairId>.json`, persist the recovered key under the
/// encryption folder, then delete the consumed invite. Best-effort: any
/// failure during processing of a single invite is logged and the file
/// left in place for retry on the next poll.

Future<void> _processPendingInvites() async {
  final notifDir =
      await getDirUrl([appDirName, notificationDir].join('/'));

  final status = await checkResourceStatus(notifDir, isFile: false);
  if (status != ResourceStatus.exist) return;

  late final ({List<String> subDirs, List<String> files}) listing;
  try {
    listing = await getResourcesInContainer(notifDir);
  } on AccessForbiddenException {
    // Should never happen — the user owns their own notifications
    // folder. Skip rather than crash if some out-of-band ACL change
    // has locked us out.

    return;
  }

  for (final file in listing.files) {
    if (!file.startsWith('invite-from-')) continue;
    if (!file.endsWith('.json')) continue;

    final fileUrl = '$notifDir$file';
    try {
      final raw = utf8.decode(await getResource(fileUrl));
      final decrypted =
          await NotificationPairKeyManager.decryptInvitePayload(raw);
      if (decrypted == null) {
        debugPrint(
          'fetchNotifications: dropping un-decryptable invite $file',
        );
        await _silentDelete(fileUrl);
        continue;
      }

      await NotificationPairKeyManager.saveKey(
        partnerWebId: decrypted.senderWebId,
        pairKey: decrypted.key,
      );
      await _silentDelete(fileUrl);
    } on Object catch (e) {
      debugPrint('fetchNotifications: failed to process invite $file: $e');
    }
  }
}

/// Enumerate the current user's encryption folder and pull back every
/// stored pair key. Files that do not match the
/// `notification-<pairId>.json` convention are ignored.

Future<List<({String partnerWebId, dynamic key})>> _listKnownPairs() async {
  final encDirUrl = await getDirUrl([appDirName, encDir].join('/'));

  final status = await checkResourceStatus(encDirUrl, isFile: false);
  if (status != ResourceStatus.exist) return const [];

  late final ({List<String> subDirs, List<String> files}) listing;
  try {
    listing = await getResourcesInContainer(encDirUrl);
  } on AccessForbiddenException {
    return const [];
  }

  final result = <({String partnerWebId, dynamic key})>[];
  for (final file in listing.files) {
    if (!file.startsWith('notification-')) continue;
    if (!file.endsWith('.json')) continue;

    try {
      // Read the plaintext partnerWebId field directly from the key
      // envelope (it travels alongside the encrypted key for exactly
      // this purpose) then delegate to the manager to do the master-
      // key decryption in a single place.

      final partnerWebId = await _partnerWebIdFromFile('$encDirUrl$file');
      if (partnerWebId == null) continue;

      final pair = await NotificationPairKeyManager.loadKey(partnerWebId);
      if (pair == null) continue;

      result.add((partnerWebId: pair.partnerWebId, key: pair.key));
    } on Object catch (e) {
      debugPrint(
        'fetchNotifications: failed to load key file $file: $e',
      );
    }
  }
  return result;
}

/// Extract the partner WebID from a stored pair key file. The file is a
/// JSON envelope whose `partnerWebId` field is plaintext, so we can
/// peek at it without touching the master key.

Future<String?> _partnerWebIdFromFile(String fileUrl) async {
  try {
    final raw = utf8.decode(await getResource(fileUrl));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final partner = json['partnerWebId'] as String?;
    if (partner == null || partner.isEmpty) return null;
    return partner;
  } on Object catch (e) {
    debugPrint(
      'fetchNotifications: failed to read partner WebID from $fileUrl: $e',
    );
    return null;
  }
}

/// Delete a resource, swallowing failures. Used after consuming an
/// invite: a delete failure is non-critical because the invite will be
/// detected and ignored on the next poll as a duplicate (the pair key
/// for that sender will already exist).

Future<void> _silentDelete(String url) async {
  try {
    await deleteResource(url, ResourceContentType.any);
  } on Object catch (e) {
    debugPrint('fetchNotifications: deleteResource($url) failed: $e');
  }
}
