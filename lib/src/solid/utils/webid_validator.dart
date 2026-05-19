/// Pure-Dart validation pipeline for candidate Solid WebID URLs.
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

import 'package:solidpod/src/solid/api/rest_api.dart' show checkWebIdProfile;
import 'package:solidpod/src/solid/constants/common.dart' show WebIdStatus;

/// Regular expression matching strings made up solely of decimal digits and
/// dots. Such a host is almost certainly an attempt at an IPv4 literal rather
/// than a domain name and should therefore be validated as IPv4 before any
/// network call is dispatched.

final RegExp _digitsAndDotsOnly = RegExp(r'^[0-9.]+$');

/// Returns true when [host] looks like an attempt to type an IPv4 literal,
/// i.e. it only contains decimal digits and dots. This is intentionally
/// permissive: malformed inputs such as `192`, `192.168`, `192.168.1`,
/// `1.2.3.4.5` and `256.0.0.1` all return true so callers can then reject
/// them via [isValidIpv4].

bool looksLikeIpv4Attempt(String host) {
  if (host.isEmpty) return false;
  return _digitsAndDotsOnly.hasMatch(host);
}

/// Returns true when [host] is a syntactically valid IPv4 address: four
/// dot-separated octets, each a decimal number in the range 0..255 with no
/// leading sign and at most three digits.

bool isValidIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return false;
    final n = int.tryParse(part);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}

/// Outcome of validating a candidate WebID URL.

enum WebIdCheckStatus {
  /// The URL points to a valid Solid WebID profile document.

  valid,

  /// The URL is not a syntactically absolute URL.

  notAbsoluteUrl,

  /// The host looks like an IPv4 literal but is malformed (e.g. `192`,
  /// `192.168.1`, `1.2.3.4.5`, `256.0.0.1`).

  invalidIpv4,

  /// The URL could not be reached (DNS lookup or network failure).

  unreachable,

  /// The URL is reachable and responded 200/204 but the body is not an RDF
  /// profile document (typically a `text/html` page from a regular website).

  notProfile,

  /// The URL returned 404.

  notExist,

  /// Some other HTTP error (e.g. 403, 5xx) — could not determine.

  unknown,
}

/// Structured outcome of [validateWebId].

class WebIdCheckResult {
  const WebIdCheckResult(
    this.status, {
    this.host = '',
    this.error,
  });

  /// The categorised failure mode (or [WebIdCheckStatus.valid] for success).

  final WebIdCheckStatus status;

  /// The host part of the WebID URL (may be empty if the URL was unparseable).

  final String host;

  /// The exception that caused the network failure, if any. Only populated
  /// for [WebIdCheckStatus.unreachable].

  final Object? error;

  /// Convenience: true when [status] is [WebIdCheckStatus.valid].

  bool get isValid => status == WebIdCheckStatus.valid;
}

/// Validate a candidate [webId] URL.
///
/// The validation pipeline is:
///   1. Reject URLs that are not syntactically absolute.
///   2. Reject hosts that look like an IPv4 attempt but are malformed.
///   3. Query [checkWebIdProfile] to confirm the URL points to a real Solid
///      WebID profile document, distinguishing "not a profile", "not found",
///      and "unknown" responses from genuine success.
///   4. Map network exceptions to [WebIdCheckStatus.unreachable] so the
///      caller can surface a clear, actionable message instead of letting
///      the UI hang.

Future<WebIdCheckResult> validateWebId(String webId) async {
  // Fragments such as `#me` are stripped before the absoluteness check
  // because some `Uri.parse` paths treat them as part of the path.

  if (!Uri.parse(webId.replaceAll('#me', '')).isAbsolute) {
    return const WebIdCheckResult(WebIdCheckStatus.notAbsoluteUrl);
  }

  final host = Uri.tryParse(webId)?.host ?? '';

  if (looksLikeIpv4Attempt(host) && !isValidIpv4(host)) {
    return WebIdCheckResult(WebIdCheckStatus.invalidIpv4, host: host);
  }

  WebIdStatus status;
  try {
    status = await checkWebIdProfile(webId);
  } on Exception catch (e) {
    return WebIdCheckResult(
      WebIdCheckStatus.unreachable,
      host: host,
      error: e,
    );
  }

  switch (status) {
    case WebIdStatus.valid:
      return WebIdCheckResult(WebIdCheckStatus.valid, host: host);
    case WebIdStatus.notProfile:
      return WebIdCheckResult(WebIdCheckStatus.notProfile, host: host);
    case WebIdStatus.notExist:
      return WebIdCheckResult(WebIdCheckStatus.notExist, host: host);
    case WebIdStatus.unknown:
      return WebIdCheckResult(WebIdCheckStatus.unknown, host: host);
  }
}
