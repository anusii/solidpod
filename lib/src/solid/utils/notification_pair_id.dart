/// Utilities for deriving the per-pair identifier used in notification
/// file and key names.
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

import 'package:crypto/crypto.dart';

import 'package:solidpod/src/solid/constants/common.dart';

/// Derive a stable, filename-safe identifier for the POD addressed by
/// [webId]. The identifier is used to name the pair-specific notification
/// file (e.g. `notifications/<id>.json`) and the corresponding encryption
/// key file (`encryption/notification-<id>.ttl`).
///
/// The identifier is the first 16 hex characters of the SHA-256 of
/// `<host>/<pod-name>`. Hashing the (host, pod) pair gives us collision
/// resistance across servers, so two unrelated PODs that happen to share
/// the same username on different Solid servers never alias to the same
/// pair file. 64 bits of entropy is more than sufficient for a per-user
/// address book.
///
/// Returns an empty string when [webId] is null, empty or cannot be parsed
/// as an absolute URL — callers should treat that as a programmer error.

String derivePairId(String? webId) {
  if (webId == null || webId.isEmpty) return '';

  // Strip the canonical Solid profile fragment (`profile/card#me`) so the
  // input is the POD root path; this keeps the derived id independent of
  // any fragment that callers happen to pass through.

  var normalised = webId.trim();
  if (normalised.contains('#')) {
    normalised = normalised.substring(0, normalised.indexOf('#'));
  }
  normalised = normalised.replaceAll('/$profCard', '');
  normalised = normalised.replaceFirst(RegExp('^https?://'), '');

  // Strip a trailing slash so two equivalent inputs (with and without
  // trailing slash) hash to the same id.

  if (normalised.endsWith('/')) {
    normalised = normalised.substring(0, normalised.length - 1);
  }

  if (normalised.isEmpty) return '';

  final digest = sha256.convert(utf8.encode(normalised));
  return digest.toString().substring(0, 16);
}

/// Returns a human-readable label for the POD addressed by [webId], used
/// purely for UI surfacing (notification centre listings, error dialogs).
///
/// Currently this is the first non-trivial path segment of the WebID
/// (typically the POD name) — `john-doe` for
/// `https://pods.solidcommunity.au/john-doe/profile/card#me`. Falls back
/// to the WebID itself when the URL cannot be parsed.

String derivePairDisplayName(String? webId) {
  if (webId == null || webId.isEmpty) return '';
  try {
    final uri = Uri.parse(webId);
    for (final segment in uri.pathSegments) {
      if (segment.isEmpty) continue;
      if (segment == 'profile' || segment == 'card') continue;
      if (segment.startsWith('#')) continue;
      return segment;
    }
    return webId;
  } on FormatException {
    return webId;
  }
}
