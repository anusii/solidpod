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

import 'dart:convert';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/models/pod_notification.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/misc.dart' show isUserLoggedIn;

/// Send a notification to a specified recipient's POD.
///
/// The notification is written as an unencrypted JSON file to the recipient's
/// notification folder (`appDirName/notification/`). The file is named using
/// the current Unix timestamp in milliseconds for chronological sorting.
///
/// This function writes directly via [createResource] using an HTTP POST
/// (not PUT) to the notification container. POST is used because the
/// notification directory's ACL grants public **Append** access, and the
/// Solid Protocol requires only `acl:Append` for POST requests to a
/// container, whereas PUT requires `acl:Write`. A `Slug` header suggests
/// the desired file name.
///
/// [writePod] is intentionally avoided because its pre-flight GET request
/// may return 403 on another user's POD, aborting before the write is ever
/// attempted.
///
/// Arguments:
/// - [recipientWebId]: The full WebID of the notification recipient
///   (e.g. `https://pods.solidcommunity.au/john-doe/profile/card#me`)
/// - [title]: The notification title
/// - [content]: Optional notification body text
/// - [priority]: Notification priority level (default: 0).
///   Convention: 0 = low, 1 = medium, 2 = high
///
/// Throws [NotLoggedInException] if the user is not authenticated.
/// Throws [RecipientNotReadyException] if the recipient's WebID does not
/// exist or their Pod lacks the notification folder for this app.

Future<void> sendNotification({
  required String recipientWebId,
  String appName = 'this app',
  required String title,
  String? content,
  int priority = 0,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to send notifications',
    );
  }

  final senderWebId = await AuthDataManager.getWebId();
  if (senderWebId == null || senderWebId.isEmpty) {
    throw NotLoggedInException('Unable to retrieve sender WebID');
  }

  // Pre-flight checks.

  // 1. Verify the recipient's WebID exists (unauthenticated GET to the
  //    public profile document).

  final webIdStatus = await checkWebIdExists(recipientWebId);
  if (webIdStatus == ResourceStatus.notExist) {
    throw RecipientNotReadyException(
      'The recipient WebID does not exist: $recipientWebId. '
      'Please check the WebID is correct.',
    );
  }

  // 2. Verify the recipient has initialised their Pod for this app.
  //    checkPodInitialised performs an authenticated GET on the recipient's
  //    shared directory — the same check used in the grant-permissions
  //    workflow. If it returns false the recipient has never set up the app.

  final podReady = await checkPodInitialised(recipientWebId);
  if (!podReady) {
    throw RecipientNotReadyException(
      '$recipientWebId has not logged in to $appName recently. Ask them to login to $appName, '
      'which will create the notification '
      'folder. Then you can send them notifications.',
    );
  }

  // Build and send the notification.

  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final notification = PodNotification(
    senderWebId: senderWebId,
    recipientWebId: recipientWebId,
    title: title,
    content: content,
    priority: priority,
    timestamp: timestamp,
  );

  // Build the absolute file URL in the recipient's notification folder.
  // WebID format: https://host/pod-name/profile/card#me
  // Target:      https://host/pod-name/appDirName/notification/<timestamp>.json

  final notificationPath = '$appDirName/$notificationDir/$timestamp.json';
  final fileUrl = recipientWebId.replaceAll(profCard, notificationPath);

  final jsonContent = jsonEncode(notification.toJson());

  // POST the notification JSON to the recipient's notification container.
  // replaceIfExist: false triggers POST (instead of PUT), which only
  // requires Append access on the container — matching the public Append
  // ACL configured during POD initialisation.
  //
  // If the POST still fails (e.g. the notification folder was added in a
  // newer app version that the recipient has not yet run), convert the
  // error into a RecipientNotReadyException with actionable guidance.

  try {
    await createResource(
      fileUrl,
      content: jsonContent,
      contentType: ResourceContentType.auto,
      replaceIfExist: false,
    );
  } on Exception catch (e) {
    final errStr = e.toString();
    if (errStr.contains('403') || errStr.contains('Forbidden')) {
      throw RecipientNotReadyException(
        'The recipient ($recipientWebId) does not have a notification '
        'folder for $appName. This typically happens when the recipient '
        'has not run the latest version of $appName. They need to log in '
        'to setup their Pod before you can send '
        'notifications to them.',
      );
    }
    rethrow;
  }
}
