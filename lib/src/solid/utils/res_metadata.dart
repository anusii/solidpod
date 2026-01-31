/// Metadata model.
///
/// Copyright (C) 2024-2026, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage
///
library;

class ResourceMetadata {
  // The size, in bytes, of the message body that
  // would have been sent had the request been a GET method
  final int contentLength;

  // Original media type (MIME type) of the resource
  final String contentType;

  // Date and time when the origin server believes the
  // resource was last modified
  final DateTime lastModified;

  // The date and time at which the message originate
  final DateTime lastAccessed;

  // A unique string identifying the version of the resource
  final String eTag;

  // Which media types the server is able to understand
  // in a PATCH request
  final String acceptPatch;

  // Web Access Control (WAC) privileges a user has for
  // the resource
  final String wacAllow;

  ResourceMetadata({
    required this.contentLength,
    required this.contentType,
    required this.lastModified,
    required this.eTag,
    required this.lastAccessed,
    required this.acceptPatch,
    required this.wacAllow,
  });
}
