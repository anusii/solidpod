/// Custom exception classes
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage, Tony Chen, Dawei Chen

library;

class AccessForbiddenException implements Exception {
  final String message;

  AccessForbiddenException(this.message);

  @override
  String toString() => 'AccessForbiddenException: $message';
}

class AccessFailedException implements Exception {
  final String message;

  AccessFailedException(this.message);

  @override
  String toString() => 'AccessFailedException: $message';
}

class ResourceNotExistException implements Exception {
  final String message;

  ResourceNotExistException(this.message);

  @override
  String toString() => 'ResourceNotExistException: $message';
}

class ResourceNotDecryptableException implements Exception {
  final String message;

  ResourceNotDecryptableException(this.message);

  @override
  String toString() => 'ResourceNotDecryptableException: $message';
}

class NotLoggedInException implements Exception {
  final String message;

  NotLoggedInException(this.message);

  @override
  String toString() => 'NotLoggedInException: $message';
}

class SecurityKeyNotAvailableException implements Exception {
  final String message;

  SecurityKeyNotAvailableException(this.message);

  @override
  String toString() => 'SecurityKeyNotAvailableException: $message';
}

/// Thrown when a provided security key fails verification against the
/// verification value stored on the POD (i.e. the key is wrong). Distinct from
/// transient errors (network, missing file) so callers can decide to forget
/// the stored security key only on a genuine mismatch.

class SecurityKeyVerificationException implements Exception {
  final String message;

  SecurityKeyVerificationException(this.message);

  @override
  String toString() => 'SecurityKeyVerificationException: $message';
}

/// Thrown when a notification cannot be delivered because the recipient's Pod
/// is not ready — either their WebID does not exist, they have not set up the
/// app, or their notification folder has not yet been created.

class RecipientNotReadyException implements Exception {
  final String message;

  RecipientNotReadyException(this.message);

  @override
  String toString() => 'RecipientNotReadyException: $message';
}

/// Thrown by [solidAuthenticate] when the in-flight authentication is aborted
/// by [cancelSolidAuthenticate]. Callers can catch this to distinguish a
/// deliberate cancellation from a genuine authentication failure such as a
/// network error.

class SolidAuthCancelledException implements Exception {
  final String message;

  SolidAuthCancelledException([this.message = 'Authentication was cancelled']);

  @override
  String toString() => 'SolidAuthCancelledException: $message';
}

/// Thrown by [changeCssAccountPassword] when the Solid server does not expose
/// the Community Solid Server (CSS v7+) account management JSON API at
/// `/.account/` (e.g. NSS, ESS, or older CSS versions). Callers should inform
/// the user that password changes are not supported on their server.

class CssAccountApiNotSupportedException implements Exception {
  final String message;

  CssAccountApiNotSupportedException(this.message);

  @override
  String toString() => 'CssAccountApiNotSupportedException: $message';
}

/// Thrown by [changeCssAccountPassword] when the CSS account API rejects the
/// given email/password combination (i.e. the credentials are wrong). Distinct
/// from transient errors (network, server) so callers can keep the dialog open
/// and let the user correct their input.

class CssWrongCredentialsException implements Exception {
  final String message;

  CssWrongCredentialsException(this.message);

  @override
  String toString() => 'CssWrongCredentialsException: $message';
}

/// Thrown by [createCssAccount] when the email address is already registered
/// on the server. Callers should keep the dialog open and let the user choose
/// a different email or navigate to the login screen.

class CssEmailAlreadyRegisteredException implements Exception {
  final String message;

  CssEmailAlreadyRegisteredException(this.message);

  @override
  String toString() => 'CssEmailAlreadyRegisteredException: $message';
}

/// Thrown by [writePod] when a write would encrypt a resource whose ACL
/// still grants the Public or Authenticated User agent class access — a
/// grant that only works while the resource stays plaintext (those agent
/// classes cannot be issued an individual decryption key). This usually
/// means the resource was deliberately decrypted in place for sharing (see
/// `decryptFileInPlace`) and the caller passed an explicit `encrypted: true`
/// (or `inheritKeyFrom`) without meaning to undo that sharing grant.
///
/// To fix: call `revokePermission` to remove the Public/Authenticated grant
/// first (it re-encrypts the resource as part of revocation), or omit
/// `encrypted` / pass `encrypted: false` to preserve the current plaintext
/// state.

class PublicShareEncryptionConflictException implements Exception {
  final String message;

  PublicShareEncryptionConflictException(this.message);

  @override
  String toString() => 'PublicShareEncryptionConflictException: $message';
}
