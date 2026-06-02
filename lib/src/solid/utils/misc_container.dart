/// Helpers for creating and validating POD container (directory) resources.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';

/// Create a directory with the given URL.

Future<void> createDir(String dirUrl) async {
  assert(dirUrl.endsWith('/'));
  await createResource(
    dirUrl,
    isFile: false,
    replaceIfExist: false,
    contentType: ResourceContentType.directory,
  );
}

/// Characters that are forbidden in container (folder) names.
///
/// These characters are either URL-unsafe (causing percent-encoding issues
/// such as spaces becoming `%20`) or filesystem-unsafe on common platforms.

final RegExp _invalidContainerNameChars = RegExp(
  r'''[ /#?%&+@=<>"|*:!\\]''',
);

/// Validates that [folderName] is a safe container name.
///
/// Throws [ArgumentError] if the name is empty, starts with a dot, or
/// contains characters that would be percent-encoded in a URL or are
/// otherwise unsafe for use as a directory name.

void validateContainerName(String folderName) {
  if (folderName.trim().isEmpty) {
    throw ArgumentError('Folder name cannot be empty.');
  }
  if (folderName.startsWith('.')) {
    throw ArgumentError('Folder name cannot start with a dot.');
  }
  final match = _invalidContainerNameChars.firstMatch(folderName);
  if (match != null) {
    final char = match.group(0);
    final label = char == ' ' ? 'spaces' : '"$char"';
    throw ArgumentError(
      'Folder name cannot contain $label. '
      'Avoid spaces and special characters: '
      r'/ \ # ? % & + @ = < > " | * : !',
    );
  }
}

/// Creates a new container (directory) on the POD from a relative path.
///
/// Combines [parentPath] and [folderName] into a relative path, resolves
/// the full directory URL via [getDirUrl], and creates the container.
///
/// [parentPath] is the normalised relative path to the parent directory
/// (e.g. `'myapp/data'` or `''` for the POD root).
///
/// [folderName] is the name of the new directory to create. It must not
/// contain spaces or URL/filesystem-unsafe characters (see
/// [validateContainerName]).
///
/// Throws [ArgumentError] if the name is invalid, or an [Exception] if
/// the directory already exists or a network error occurs.

Future<void> createContainer(String parentPath, String folderName) async {
  // Validate the folder name before making any network calls.

  validateContainerName(folderName);

  // Combine parent path and folder name, handling empty parent (POD root).

  final folderPath =
      parentPath.isEmpty ? folderName : '$parentPath/$folderName';
  final dirUrl = await getDirUrl(folderPath);
  await createDir(dirUrl);
}
