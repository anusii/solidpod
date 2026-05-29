/// Data model for POD notifications.
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

/// A single notification exchanged between two PODs.
///
/// Each notification is delivered as a stand-alone encrypted file in the
/// recipient's `appDirName/notifications/` folder (via the container's
/// public-Append ACL). The sender keeps a mirror copy in their own POD
/// under the same convention so the two PODs "form a pair" of records,
/// and each per-pair AES key K_AB is stored in both PODs' encryption
/// folders as `notification-<otherPairId>.json`.
///
/// The [readStatus] flag is informational only — read/dismissed state is
/// owned by the recipient's UI (typically tracked locally in
/// SharedPreferences keyed by [id]) because the recipient holds no write
/// permission on the sender's mirror file.

class PodNotification {
  /// Identifier of the notification, unique within a pair file. Used both
  /// to deduplicate while polling and as the key for local read-state
  /// persistence.

  final String id;

  /// WebID of the user who sent the notification.

  final String senderWebId;

  /// WebID of the intended recipient.

  final String recipientWebId;

  /// Short summary of the notification.

  final String title;

  /// Optional detailed body text.

  final String? content;

  /// Priority level (0 = low, 1 = medium, 2 = high).

  final int priority;

  /// Unix timestamp in milliseconds when the notification was created.

  final int timestamp;

  /// Whether the recipient has read this notification. Authoritative state
  /// lives on the recipient device; this field is included so that the
  /// sender can render an aggregate "seen" indicator in future iterations.

  final bool readStatus;

  const PodNotification({
    required this.id,
    required this.senderWebId,
    required this.recipientWebId,
    required this.title,
    this.content,
    required this.priority,
    required this.timestamp,
    this.readStatus = false,
  });

  /// Create a new notification with a freshly generated [id] based on the
  /// current timestamp. The id includes the sender hash to make it
  /// pair-unique even when two senders produce a notification within the
  /// same millisecond.

  factory PodNotification.create({
    required String senderWebId,
    required String recipientWebId,
    required String title,
    String? content,
    int priority = 0,
    int? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final senderHash =
        senderWebId.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return PodNotification(
      id: '$ts-$senderHash',
      senderWebId: senderWebId,
      recipientWebId: recipientWebId,
      title: title,
      content: content,
      priority: priority,
      timestamp: ts,
    );
  }

  /// Returns a copy with [readStatus] set to [read].

  PodNotification copyWithRead(bool read) => PodNotification(
        id: id,
        senderWebId: senderWebId,
        recipientWebId: recipientWebId,
        title: title,
        content: content,
        priority: priority,
        timestamp: timestamp,
        readStatus: read,
      );

  /// Serialise to a JSON-compatible map.

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderWebId': senderWebId,
        'recipientWebId': recipientWebId,
        'title': title,
        if (content != null) 'content': content,
        'priority': priority,
        'timestamp': timestamp,
        'readStatus': readStatus,
      };

  /// Deserialise from a JSON-compatible map.

  factory PodNotification.fromJson(Map<String, dynamic> json) {
    final timestamp = (json['timestamp'] as num).toInt();
    final senderWebId = (json['senderWebId'] ?? '') as String;
    final id = (json['id'] as String?) ??
        '$timestamp-${senderWebId.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0')}';

    return PodNotification(
      id: id,
      senderWebId: senderWebId,
      recipientWebId: (json['recipientWebId'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      content: json['content'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      timestamp: timestamp,
      readStatus: (json['readStatus'] as bool?) ?? false,
    );
  }

  @override
  String toString() => 'PodNotification('
      'id: $id, '
      'sender: $senderWebId, '
      'recipient: $recipientWebId, '
      'title: $title, '
      'priority: $priority, '
      'timestamp: $timestamp, '
      'read: $readStatus)';
}
