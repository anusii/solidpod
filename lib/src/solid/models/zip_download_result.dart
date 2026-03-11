/// Data model representing the outcome of a zip download operation.
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

import 'dart:typed_data';

/// Encapsulates the outcome of a batch zip download operation.
///
/// Contains the zip bytes together with counts of how many files were
/// collected, successfully read and added to the archive, and how many
/// could not be read.

class ZipDownloadResult {
  /// The encoded zip archive bytes.

  final Uint8List zipBytes;

  /// Number of file entries discovered during the collection phase.

  final int entriesFound;

  /// Number of files successfully read and added to the archive.

  final int filesAdded;

  /// Number of empty directories added to the archive.

  final int emptyDirsAdded;

  /// Map of file paths to error messages for files that could not be read.

  final Map<String, String> failed;

  const ZipDownloadResult({
    required this.zipBytes,
    required this.entriesFound,
    required this.filesAdded,
    required this.emptyDirsAdded,
    required this.failed,
  });

  /// Whether the archive contains at least one entry (file or empty
  /// directory).

  bool get hasContent => filesAdded > 0 || emptyDirsAdded > 0;
}
