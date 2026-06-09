/// Function to send a notification to a recipient's POD.
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

import 'package:encrypter_plus/encrypter_plus.dart' show Key;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/models/pod_notification.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/misc.dart'
    show getAppNameVersion, isUserLoggedIn;
import 'package:solidpod/src/solid/utils/notification_pair_id.dart';
import 'package:solidpod/src/solid/utils/notification_pair_key_manager.dart';
import 'package:solidpod/src/solid/utils/notification_pair_outbox.dart';

/// Send a notification to the POD identified by [recipientWebId].
///
/// Arguments:
///  - [recipientWebId]: WebID of the recipient POD.
///  - [title]: required short title shown in the notification card.
///  - [content]: optional longer body.
///  - [priority]: 0 = low, 1 = medium, 2 = high.
///
/// Throws:
///  - [NotLoggedInException] when the caller is not authenticated.
///  - [RecipientNotReadyException] when the recipient WebID does not
///    resolve, or when the invite POST is rejected (typically because
///    the recipient has not yet logged in to the upgraded app so the
///    Update Wizard has not had a chance to create their notifications
///    folder).

Future<void> sendNotification({
  required String recipientWebId,
  required String title,
  String? content,
  int priority = 0,
}) async {
  final appName = (await getAppNameVersion()).name;

  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to send notifications',
    );
  }

  final senderWebId = await AuthDataManager.getWebId();
  if (senderWebId == null || senderWebId.isEmpty) {
    throw NotLoggedInException('Unable to retrieve sender WebID');
  }

  // Pre-flight: confirm the recipient WebID is a real profile document.

  final webIdStatus = await checkWebIdExists(recipientWebId);
  if (webIdStatus == ResourceStatus.notExist) {
    throw RecipientNotReadyException(
      'The recipient WebID does not exist: $recipientWebId. '
      'Please check the WebID is correct.',
    );
  }

  // Get (or lazily create) the AES key for this pair. Stored under the
  // sender's encryption folder so subsequent sends reuse it.

  final keyInfo = await NotificationPairKeyManager.getOrCreateKey(
    recipientWebId,
  );

  final notification = PodNotification.create(
    senderWebId: senderWebId,
    recipientWebId: recipientWebId,
    title: title,
    content: content,
    priority: priority,
  );

  // Append into the single-file outbox living in the sender's own POD.
  // This is the read-decrypt-append-encrypt-write step.

  await NotificationPairOutbox.appendNotification(
    partnerWebId: recipientWebId,
    pairKey: keyInfo.pair.key,
    notification: notification,
  );

  // Refresh the per-file ACL so the partner keeps Read access. This is
  // idempotent; rewriting the same ACL is harmless and recovers from
  // any out-of-band ACL edits.

  final outboxUrl = await NotificationPairOutbox.outboxUrlFor(recipientWebId);
  await NotificationPairOutbox.ensureOutboxAcl(
    outboxUrl: outboxUrl,
    partnerWebId: recipientWebId,
  );

  // First send for this pair: deliver an RSA-encrypted invite so the
  // recipient learns K_AB and the outbox URL on their next poll. Any
  // 403/404 here is bubbled up as a RecipientNotReadyException because
  // it means the recipient's notifications folder is missing or
  // refuses cross-POD writes — both fixable by asking the recipient to
  // log in once and let the Update Wizard run.

  if (keyInfo.created) {
    try {
      await _deliverInvite(
        senderWebId: senderWebId,
        recipientWebId: recipientWebId,
        pairKey: keyInfo.pair.key,
        outboxUrl: outboxUrl,
      );
    } on Object catch (e) {
      final errStr = e.toString();
      if (errStr.contains('403') ||
          errStr.contains('Forbidden') ||
          errStr.contains('404')) {
        throw RecipientNotReadyException(
          'Could not deliver the notification invite to $recipientWebId '
          'for $appName. Their notifications folder is either missing or '
          'does not accept cross-Pod writes. Ask them to log in to '
          '$appName so the Update Wizard can create or repair the folder.',
        );
      }
      rethrow;
    }
  }
}

/// POST an RSA-encrypted invite into the recipient's notifications
/// folder. The folder ACL is expected to grant public Append, which is
/// exactly what is needed to POST a new file from a different POD.

Future<void> _deliverInvite({
  required String senderWebId,
  required String recipientWebId,
  required Key pairKey,
  required String outboxUrl,
}) async {
  final payload = await NotificationPairKeyManager.buildInvitePayload(
    senderWebId: senderWebId,
    partnerWebId: recipientWebId,
    pairKey: pairKey,
    outboxUrl: outboxUrl,
  );

  final senderPairId = derivePairId(senderWebId);
  final inviteFileName =
      NotificationPairKeyManager.inviteFileName(senderPairId);
  final inviteUrl = recipientWebId.replaceAll(
    profCard,
    '$appDirName/$notificationDir/$inviteFileName',
  );

  // POST so the recipient folder's public Append ACL is sufficient
  // (PUT would require Write which third parties do not have).

  await createResource(
    inviteUrl,
    content: payload,
    contentType: ResourceContentType.auto,
    replaceIfExist: false,
  );
}
