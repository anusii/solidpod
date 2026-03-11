/// Data model representing the outcome of a batch delete operation.
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

/// Encapsulates the outcome of a batch delete operation on a Solid POD.
///
/// Contains the names of items that were successfully deleted and a map of
/// items that could not be deleted together with their error messages.

class BatchDeleteResult {
  /// Names of items that were successfully deleted.

  final List<String> succeeded;

  /// Map of item names to their error messages for items that failed.

  final Map<String, String> failed;

  const BatchDeleteResult({
    required this.succeeded,
    required this.failed,
  });

  /// Whether any item failed to delete.

  bool get hasFailures => failed.isNotEmpty;

  /// Whether every item was successfully deleted.

  bool get allSucceeded => failed.isEmpty;

  /// Total number of items that were processed (both successes and failures).

  int get total => succeeded.length + failed.length;
}
