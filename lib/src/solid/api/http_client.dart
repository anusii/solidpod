/// A shared, connection-pooling HTTP client for all POD requests.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:http/http.dart' as http;

/// The process-wide client used for every request to a POD server.
///
/// The top-level helpers in `package:http` (`http.get()`, `http.put()`, ...)
/// build a brand new [http.Client] for each call and close it again as soon as
/// the response arrives. On `dart:io` platforms that means a new `HttpClient`
/// with its own, immediately discarded, connection pool: every request pays a
/// fresh TCP handshake plus a full TLS handshake, so a single write to a POD
/// (which issues several requests) costs several extra round trips. The cost
/// scales with the network distance to the POD server and with how fast the
/// platform's TLS stack is, which is why the same operation can feel instant
/// against a nearby server and painfully slow against a distant one.
///
/// Sharing one client keeps the underlying connections alive (the `Connection:
/// keep-alive` header the API already sends finally means something), so only
/// the first request to a host pays for the handshakes.
///
/// On the web `http.Client()` is a `BrowserClient` and connection reuse is the
/// browser's business; sharing the instance is still correct and avoids
/// allocating a client per request.

http.Client get podHttpClient =>
    _podHttpClient ??= _RetryIdleConnectionClient(http.Client());

http.Client? _podHttpClient;

/// Close and drop the shared client.
///
/// Call on logout so no authenticated connection is kept open. The next
/// request transparently creates a new client.

void closePodHttpClient() {
  _podHttpClient?.close();
  _podHttpClient = null;
}

/// Replace the shared client, closing any existing one.
///
/// Intended for tests, which can inject a `MockClient` here.

void setPodHttpClient(http.Client client) {
  _podHttpClient?.close();
  _podHttpClient = client;
}

/// Retries a request once when the connection dies before any response
/// arrives.
///
/// This is the cost of keeping connections alive: a server (or an intervening
/// proxy) may close an idle connection at the very moment the client picks it
/// up for the next request, which surfaces as a [http.ClientException] such as
/// "Connection closed before full header was received". Nothing was served, so
/// re-sending on a fresh connection is safe and invisible to the caller.
///
/// Only methods that can be repeated without changing the outcome are retried.
/// POST and PATCH are left alone: a POST that did reach the server would
/// create a second resource, and a retry of a partly applied PATCH is not
/// equivalent to the original.

class _RetryIdleConnectionClient extends http.BaseClient {
  _RetryIdleConnectionClient(this._inner);

  final http.Client _inner;

  static const _retryableMethods = {'GET', 'HEAD', 'PUT', 'DELETE'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // A request can only be sent once, so a retry needs a fresh copy. Only
    // in-memory requests can be copied; a streamed body cannot be replayed.

    final copy = _retryableMethods.contains(request.method.toUpperCase())
        ? _copyOf(request)
        : null;

    try {
      return await _inner.send(request);
    } on http.ClientException catch (e) {
      if (copy == null) rethrow;

      debugPrint(
        'Retrying ${request.method} ${request.url} after connection error: '
        '${e.message}',
      );

      return await _inner.send(copy);
    }
  }

  /// A resendable duplicate of [request], or null if its body cannot be
  /// replayed.

  static http.BaseRequest? _copyOf(http.BaseRequest request) {
    if (request is! http.Request) return null;

    return http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..bodyBytes = request.bodyBytes;
  }

  @override
  void close() => _inner.close();
}
