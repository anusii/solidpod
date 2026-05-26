/// Application-level hooks for the public/authenticated-user sharing lifecycle.
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

/// Signature of a transformer that rewrites the (plaintext) content of a
/// resource as part of the public/authenticated-user sharing lifecycle.

typedef PublicSharingContentTransformer = Future<String> Function(
  String resourceUrl,
  String content,
);

/// Hook points that let host applications layer additional content
/// transformations on top of solidpod's own encrypted-TTL wrapper when
/// files are shared with the Public or Authenticated User classes.

class PublicSharingHooks {
  PublicSharingHooks._();

  /// Invoked by [decryptFileInPlace] after solidpod has unwrapped the
  /// outer encrypted-TTL layer, immediately before writing the result
  /// back to the server. The returned value is what gets persisted.

  static PublicSharingContentTransformer? onPublicShareDecrypted;

  /// Invoked by [encryptFileInPlace] before solidpod re-wraps a file
  /// in its outer encrypted-TTL layer (e.g. after public/auth-user
  /// access is revoked). The returned value is what then gets fed
  /// into [getEncTTLStr] to produce the encrypted payload at rest.

  static PublicSharingContentTransformer? onPublicShareRevoked;

  /// Reset all registered hooks. Primarily intended for tests.

  static void clear() {
    onPublicShareDecrypted = null;
    onPublicShareRevoked = null;
  }
}
