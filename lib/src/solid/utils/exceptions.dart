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
