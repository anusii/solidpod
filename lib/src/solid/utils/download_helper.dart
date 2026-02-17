/// Helper functions for downloading multiple resources as a zip archive.
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
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:archive/archive.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/path_type.dart';
import 'package:solidpod/src/solid/models/zip_download_result.dart';
import 'package:solidpod/src/solid/read_pod.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';

/// Strips the `.enc.ttl` suffix added by solidpod's encryption layer,
/// restoring the original file name for display or download purposes.

String cleanEncryptedFileName(String fileName) {
  return fileName.replaceAll('.enc.ttl', '');
}

/// Download multiple files and/or directories from a Solid POD and bundle
/// them into a single zip archive in memory.
///
/// The algorithm first traverses the entire tree structure of the selected
/// items, collecting file entries and detecting empty directories. Empty
/// directories are preserved in the archive by adding explicit directory
/// entries so that the extracted archive faithfully mirrors the original
/// folder structure.
///
/// [parentPath] is the normalised POD-relative path to the directory
/// containing the selected items (e.g. `myapp/data`).
///
/// [fileNames] is a list of file names (not paths) to include from
/// [parentPath].
///
/// [directoryNames] is a list of directory names to include from
/// [parentPath]. Each directory is traversed recursively and all nested
/// files are added to the archive preserving their relative structure.
///
/// [onProgress] is an optional callback invoked after each file is
/// processed, receiving `(completed, total)` counts.
///
/// Returns a [ZipDownloadResult] containing the zip bytes and diagnostic
/// information about successes and failures.

Future<ZipDownloadResult> downloadItemsAsZip({
  required String parentPath,
  List<String> fileNames = const [],
  List<String> directoryNames = const [],
  void Function(int completed, int total)? onProgress,
}) async {
  // Phase 1 – Traverse the tree and collect all file entries together
  // with any empty directories that need explicit zip entries.

  final fileEntries = <_ZipFileEntry>[];
  final emptyDirZipPaths = <String>[];

  debugPrint(
    'downloadItemsAsZip: parentPath="$parentPath", '
    '${fileNames.length} file(s), ${directoryNames.length} dir(s)',
  );

  // Individual files: placed at the zip root with their cleaned name.

  for (final fileName in fileNames) {
    final podPath = parentPath.isEmpty ? fileName : '$parentPath/$fileName';
    fileEntries.add(
      _ZipFileEntry(
        podRelativePath: podPath,
        zipPath: cleanEncryptedFileName(fileName),
      ),
    );
  }

  // Directories: recursively traverse and collect contents.

  for (final dirName in directoryNames) {
    final dirPodPath = parentPath.isEmpty ? dirName : '$parentPath/$dirName';
    final dirUrl = await getDirUrl(dirPodPath);

    debugPrint(
      'downloadItemsAsZip: traversing dir "$dirName" → '
      'podPath="$dirPodPath", url="$dirUrl"',
    );

    await _traverseContainer(
      containerUrl: dirUrl,
      containerPodPath: dirPodPath,
      zipPrefix: dirName,
      fileEntries: fileEntries,
      emptyDirZipPaths: emptyDirZipPaths,
    );
  }

  debugPrint(
    'downloadItemsAsZip: found ${fileEntries.length} file(s), '
    '${emptyDirZipPaths.length} empty dir(s)',
  );

  // Phase 2 – Build the archive.

  final archive = Archive();

  // Add explicit directory entries for empty directories so they are
  // preserved when the archive is extracted.

  for (final dirZipPath in emptyDirZipPaths) {
    // The trailing "/" signals to archive extractors that this entry
    // represents a directory rather than a zero-byte file.

    final entryName = dirZipPath.endsWith('/') ? dirZipPath : '$dirZipPath/';
    archive.addFile(ArchiveFile.directory(entryName));

    debugPrint('downloadItemsAsZip: added empty dir "$entryName"');
  }

  // Read each file from the POD and add it to the archive.

  final total = fileEntries.length;
  var completed = 0;
  var filesAdded = 0;
  final failed = <String, String>{};

  for (final entry in fileEntries) {
    try {
      final content = await readPod(
        entry.podRelativePath,
        pathType: PathType.relativeToPod,
      );
      final bytes = _contentToBytes(content);
      archive.addFile(ArchiveFile.bytes(entry.zipPath, bytes));
      filesAdded++;

      debugPrint(
        'downloadItemsAsZip: added file "${entry.zipPath}" '
        '(${bytes.length} bytes)',
      );
    } catch (e) {
      debugPrint(
        'downloadItemsAsZip: FAILED to read "${entry.podRelativePath}": $e',
      );
      failed[entry.zipPath] = e.toString();
    }
    completed++;
    onProgress?.call(completed, total);
  }

  debugPrint(
    'downloadItemsAsZip: $filesAdded file(s) added, '
    '${failed.length} failed, '
    '${emptyDirZipPaths.length} empty dir(s) added',
  );

  final encoded = ZipEncoder().encode(archive);

  return ZipDownloadResult(
    zipBytes: Uint8List.fromList(encoded),
    entriesFound: fileEntries.length,
    filesAdded: filesAdded,
    emptyDirsAdded: emptyDirZipPaths.length,
    failed: failed,
  );
}

// Private helpers.

/// Represents a file to include in the zip archive.

class _ZipFileEntry {
  /// POD-relative path used by [readPod] (e.g. `myapp/data/file.enc.ttl`).

  final String podRelativePath;

  /// Path inside the zip (e.g. `subdir/file.txt`).

  final String zipPath;

  const _ZipFileEntry({
    required this.podRelativePath,
    required this.zipPath,
  });
}

/// Recursively traverses a container, collecting file entries into
/// [fileEntries] and recording the zip paths of empty directories into
/// [emptyDirZipPaths].
///
/// A directory is considered "empty" when it contains no visible files
/// and no visible subdirectories (hidden items starting with "." are
/// excluded).
///
/// [containerUrl]     – full URL of the container (with trailing `/`).
/// [containerPodPath] – known POD-relative path (e.g. `myapp/data/sub`).
/// [zipPrefix]        – path prefix inside the zip (e.g. `sub`).
/// [fileEntries]      – accumulator for file entries.
/// [emptyDirZipPaths] – accumulator for empty directory zip paths.

Future<void> _traverseContainer({
  required String containerUrl,
  required String containerPodPath,
  required String zipPrefix,
  required List<_ZipFileEntry> fileEntries,
  required List<String> emptyDirZipPaths,
}) async {
  debugPrint(
    '_traverseContainer: url="$containerUrl" '
    'podPath="$containerPodPath" zipPrefix="$zipPrefix"',
  );

  final resources = await getResourcesInContainer(containerUrl);

  // Filter out hidden items (e.g. `.acl`, `.chunks`).

  final visibleFiles = resources.files
      .where((f) => !_extractResourceName(f).startsWith('.'))
      .toList();
  final visibleDirs = resources.subDirs
      .where((d) => !_extractResourceName(d).startsWith('.'))
      .toList();

  debugPrint(
    '  → ${visibleFiles.length} visible file(s), '
    '${visibleDirs.length} visible subdir(s)',
  );

  // If the directory has no visible content at all, record it as empty.

  if (visibleFiles.isEmpty && visibleDirs.isEmpty) {
    emptyDirZipPaths.add(zipPrefix);

    debugPrint('  → empty directory, recorded for zip');

    return;
  }

  // Add file entries.

  for (final fileRef in visibleFiles) {
    final fileName = _extractResourceName(fileRef);
    final podPath = '$containerPodPath/$fileName';
    final zipPath = '$zipPrefix/${cleanEncryptedFileName(fileName)}';

    fileEntries.add(
      _ZipFileEntry(
        podRelativePath: podPath,
        zipPath: zipPath,
      ),
    );
  }

  // Recurse into visible subdirectories.

  for (final dirRef in visibleDirs) {
    final dirName = _extractResourceName(dirRef);

    final subUrl = containerUrl.endsWith('/')
        ? '$containerUrl$dirName/'
        : '$containerUrl/$dirName/';

    await _traverseContainer(
      containerUrl: subUrl,
      containerPodPath: '$containerPodPath/$dirName',
      zipPrefix: '$zipPrefix/$dirName',
      fileEntries: fileEntries,
      emptyDirZipPaths: emptyDirZipPaths,
    );
  }
}

/// Extracts the resource name (last path segment) from a value that may
/// be either a full URL or a plain relative name.
///
/// Handles trailing slashes for directories:
///   `https://pod.example/user/app/data/dir/` → `dir`
///   `dir/` → `dir`
///   `file.ttl` → `file.ttl`

String _extractResourceName(String urlOrName) {
  var cleaned = urlOrName;

  // Strip trailing slash (directories).

  if (cleaned.endsWith('/')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }

  // If it looks like a URL, parse and take the last path segment.

  if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
    final segments = Uri.parse(cleaned).pathSegments;
    return segments.isNotEmpty ? segments.last : cleaned;
  }

  // Otherwise it is already a plain name – take the last segment in case
  // it contains path separators.

  final lastSlash = cleaned.lastIndexOf('/');

  return lastSlash >= 0 ? cleaned.substring(lastSlash + 1) : cleaned;
}

/// Converts the string content returned by [readPod] into raw bytes.
///
/// If the content is valid base64 (typically a binary file that was
/// base64-encoded during encryption), it is decoded to bytes. Otherwise
/// the content is treated as plain text and encoded as UTF-8.

Uint8List _contentToBytes(String content) {
  try {
    return Uint8List.fromList(base64Decode(content));
  } catch (_) {
    return Uint8List.fromList(utf8.encode(content));
  }
}
