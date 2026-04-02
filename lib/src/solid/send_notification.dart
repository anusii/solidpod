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

import 'package:flutter/foundation.dart' show debugPrint;

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

Future<void> sendNotification({
  required String recipientWebId,
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

  // debugPrint('[sendNotification] Writing to: $fileUrl');

  // POST the notification JSON to the recipient's notification container.
  // replaceIfExist: false triggers POST (instead of PUT), which only
  // requires Append access on the container — matching the public Append
  // ACL configured during POD initialisation.

  await createResource(
    fileUrl,
    content: jsonContent,
    contentType: ResourceContentType.auto,
    replaceIfExist: false,
  );
}
