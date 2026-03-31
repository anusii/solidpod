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

/// A notification to be stored in a recipient's POD.
///
/// Each notification is serialised as a JSON file in the recipient's
/// `appDirName/notification/` folder. The file is named after its
/// [timestamp] (Unix epoch milliseconds) for chronological sorting.

class PodNotification {
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

  const PodNotification({
    required this.senderWebId,
    required this.recipientWebId,
    required this.title,
    this.content,
    required this.priority,
    required this.timestamp,
  });

  /// Serialise to a JSON-compatible map.

  Map<String, dynamic> toJson() => {
        'senderWebId': senderWebId,
        'recipientWebId': recipientWebId,
        'title': title,
        if (content != null) 'content': content,
        'priority': priority,
        'timestamp': timestamp,
      };

  /// Deserialise from a JSON-compatible map.

  factory PodNotification.fromJson(Map<String, dynamic> json) =>
      PodNotification(
        senderWebId: json['senderWebId'] as String,
        recipientWebId: json['recipientWebId'] as String,
        title: json['title'] as String,
        content: json['content'] as String?,
        priority: json['priority'] as int,
        timestamp: json['timestamp'] as int,
      );

  @override
  String toString() => 'PodNotification('
      'sender: $senderWebId, '
      'recipient: $recipientWebId, '
      'title: $title, '
      'priority: $priority, '
      'timestamp: $timestamp)';
}
