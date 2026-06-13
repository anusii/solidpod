/// Helper functions for deleting files and containers from a Solid POD.
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
/// Authors: Anushka Vidanage, Dawei Chen, Tony Chen

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/models/batch_delete_result.dart';
import 'package:solidpod/src/solid/revoke_permission_to_recipients.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/io_helper.dart';
import 'package:solidpod/src/solid/utils/key_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart'
    show extractResourcePathFromUrl, getWebId, normalizeFilePath;

/// Deletes a container (directory) and all of its contents recursively.
///
/// Combines [parentPath] and [folderName] into a relative path, resolves
/// the full directory URL, then removes every nested resource before
/// finally removing the container itself. Solid POD servers typically
/// require a container to be empty before it can be deleted.
///
/// [parentPath] is the relative path to the parent directory, interpreted
/// relative to the app's data directory (`appname/data`), mirroring
/// [createContainer]. An empty string refers to the data directory itself.
/// A path that already begins with `appname/data` is used as-is.
///
/// [folderName] is the name of the directory to delete.
///
/// Throws if the container does not exist or a network error occurs.

Future<void> deleteContainer(String parentPath, String folderName) async {
  final folderPath =
      parentPath.isEmpty ? folderName : '$parentPath/$folderName';
  final dirUrl = await getDirUrl(await normalizeFilePath(folderPath, null));

  await _deleteContainerByUrl(dirUrl);
}

/// Recursively deletes a container identified by its full [containerUrl],
/// including all nested subdirectories and files.

Future<void> _deleteContainerByUrl(String containerUrl) async {
  // Solid servers require a trailing "/" to recognise a DELETE target as
  // a container. The resource listing parser strips trailing slashes
  // from subdirectory names, so we normalise here.

  final url = containerUrl.endsWith('/') ? containerUrl : '$containerUrl/';

  await _deleteContainerContents(url);

  // Attempt to delete the now-empty container.

  try {
    await deleteResource(url, ResourceContentType.directory);
  } catch (_) {
    // The container may still contain unlisted auxiliary resources
    // (e.g. `.acl`, `.meta`). Perform a second pass to clear them.

    debugPrint(
      'Warning: first container delete attempt failed for '
      '$url – running second pass',
    );

    await _deleteContainerContents(url);

    // Final attempt – let any exception propagate.

    await deleteResource(url, ResourceContentType.directory);
  }
}

/// Deletes all listed contents of a container (files and subdirectories)
/// without deleting the container itself. Errors on individual items
/// are caught and logged so that the process continues.
///
/// [getResourcesInContainer] may return either absolute URLs or relative
/// names depending on the Solid server implementation.  All references
/// are resolved to absolute URLs via [_resolveResourceUrl] before being
/// passed to [deleteResource].

Future<void> _deleteContainerContents(String containerUrl) async {
  final base = containerUrl.endsWith('/') ? containerUrl : '$containerUrl/';
  final resources = await getResourcesInContainer(containerUrl);

  // Recursively delete subdirectories first (depth-first).

  for (final subDirRef in resources.subDirs) {
    final subDirAbsUrl = _resolveResourceUrl(subDirRef, base);

    try {
      await _deleteContainerByUrl(subDirAbsUrl);
    } catch (e) {
      debugPrint(
        'Warning: could not delete subdirectory $subDirAbsUrl: $e',
      );
    }
  }

  // Delete every file in this container.

  for (final fileRef in resources.files) {
    final fileAbsUrl = _resolveResourceUrl(fileRef, base);

    // Attempt to remove the associated ACL file first. On some Solid
    // server implementations the ACL is not automatically deleted
    // together with the resource and would block container removal.

    try {
      await deleteResource('$fileAbsUrl.acl', ResourceContentType.any);
    } catch (_) {
      // ACL does not exist – that is fine.
    }

    try {
      await deleteResource(fileAbsUrl, ResourceContentType.any);
    } catch (e) {
      debugPrint('Warning: could not delete file $fileAbsUrl: $e');
    }
  }

  // Also try to delete the container's own ACL file which is typically
  // not included in the resource listing.

  try {
    await deleteResource('$base.acl', ResourceContentType.any);
  } catch (_) {
    // ACL does not exist – that is fine.
  }
}

/// Resolves a resource reference to an absolute URL.
///
/// [getResourcesInContainer] may return either full URLs
/// (e.g. `https://pod.example/user/app/data/file.ttl`) or plain
/// relative names (e.g. `file.ttl`, `subdir/`).  If [ref] is already
/// absolute it is returned as-is; otherwise it is resolved against the
/// container's [baseUrl] (which must include a trailing `/`).

String _resolveResourceUrl(String ref, String baseUrl) {
  if (ref.startsWith('http://') || ref.startsWith('https://')) {
    return ref;
  }

  return '$baseUrl$ref';
}

/// Delete the ACL file for a resource.

Future<void> deleteAclForResource(String resourceUrl) async {
  final aclUrl = '$resourceUrl.acl';
  final status = await checkResourceStatus(aclUrl);

  switch (status) {
    case ResourceStatus.exist:
      await deleteResource(aclUrl, ResourceContentType.turtleText);

    case ResourceStatus.forbidden:
      debugPrint(
        'Access to ACL file "$aclUrl" for "$resourceUrl" is forbidden.',
      );

    case ResourceStatus.notExist:
      debugPrint('ACL file "$aclUrl" for "$resourceUrl" does not exist.');

    case ResourceStatus.unknown:
      throw Exception(
        'Error occurred when checking status of ACL file '
        '"$aclUrl" for "$resourceUrl"',
      );
  }
}

/// Delete a file and its associated resources, after first revoking
/// external access to the file. The file with URL [fileUrl],
/// its ACL file, and its encryption key (if exists) will be deleted.
/// The permission logs of any recipients to the file, will also be
/// updated with a log line recording that permissions have been
/// revoked.
/// Throws an exception if the file does not exist or any error occurs.
///
/// Arguments:
///
/// - [fileUrl] - URL of file to be deleted.
/// - [contentType] - the type of content of the resource. Default:
/// [ResourceContentType.turtleText].
/// - [isKey] - flag describing whether the file to be deleted is a
/// security key. Use this flag if file is a security key to avoid
/// unnecessary operations that are not needed to delete a key.
/// - [ownerWebId] - Optional WebID of the POD owner. When provided and it
/// differs from the current user's WebID, the file is deleted from that
/// owner's (external) POD via [deleteExternalFile] instead of the current
/// user's own POD. In that case the owner-only steps (permission revocation,
/// removing the owner's own encryption key) are skipped and the shared key is
/// removed instead. An [AccessForbiddenException] is thrown if the user lacks
/// delete permission. This makes deleteFile the single entry point for
/// deleting from own and external PODs; [deleteExternalFile] remains available
/// for direct use.

Future<void> deleteFile({
  required String fileUrl,
  ResourceContentType contentType = ResourceContentType.turtleText,
  bool isKey = false,
  String? ownerWebId,
}) async {
  // When [ownerWebId] names another user's POD, delegate to the external-file
  // delete path (removes the shared key, skips owner-only steps).

  if (ownerWebId != null && ownerWebId != await getWebId()) {
    await deleteExternalFile(fileUrl, contentType: contentType);
    return;
  }

  if (await isFileProtected(fileUrl)) {
    throw Exception('Delete protected file is not allowed');
  }

  final filePath = await extractResourcePathFromUrl(fileUrl);

  if (!isKey) {
    // File to be deleted != key => perform all steps.

    // Revoke permission to recipients to avoid the permission log of
    // recipients still showing the recipient as having access to the
    // file that is being deleted.
    // 20260112 jesscmoore: Assumes user is owner which is always true
    // in deleteFile().

    try {
      await revokePermissionToRecipients(fileName: filePath);
    } catch (e) {
      // If the ACL file does not exist (e.g. the file was never shared),
      // revocation is unnecessary – log a warning and proceed with
      // the deletion rather than aborting.

      debugPrint(
        'Warning: could not revoke permissions for "$filePath" '
        '(ACL may not exist): $e',
      );
    }

    await deleteResource(fileUrl, contentType);

    // dc 20260206: ACL file seems to be deleted by the POD server
    // when the file is deleted.
    //
    // await deleteAclForResource(fileUrl);
    await KeyManager.removeIndividualKey(resourcePath: filePath);
  } else {
    // File to be deleted == key => perform delete only.
    await deleteResource(fileUrl, contentType);
  }
}

/// Delete an external file with path [fileUrl] and the shared key
/// if the file is encrypted.
/// Throws an exception if the file does not exist or any error occurs.

Future<void> deleteExternalFile(
  String fileUrl, {
  ResourceContentType contentType = ResourceContentType.turtleText,
}) async {
  await deleteResource(fileUrl, contentType);
  // await deleteAclForResource(fileUrl);
  await KeyManager.removeSharedIndividualKey(fileUrl);

  /// av: Need to add the functionality to remove the log line from
  /// permission log. Otherwise, it will give an error.
}

/// Delete a mixed batch of files and directories from a Solid POD.
///
/// [parentPath] is the normalised relative path to the parent directory
/// containing all items (e.g. `'myapp/data'` or `''` for the POD root).
///
/// [fileNames] is a list of file names to delete from [parentPath].
///
/// [directoryNames] is a list of directory names to delete from
/// [parentPath]. Each directory is deleted recursively, including all
/// nested contents.
///
/// [onProgress] is an optional callback invoked after each item is
/// processed, receiving the number of items completed so far and the
/// total count. Useful for driving a progress indicator in the UI.
///
/// Returns a [BatchDeleteResult] summarising successes and failures.

Future<BatchDeleteResult> deleteItems({
  required String parentPath,
  List<String> fileNames = const [],
  List<String> directoryNames = const [],
  void Function(int completed, int total)? onProgress,
}) async {
  final succeeded = <String>[];
  final failed = <String, String>{};
  final totalCount = fileNames.length + directoryNames.length;
  var completed = 0;

  // Delete files first – they are typically faster than recursive directory
  // deletions and reduce the overall item count quickly.

  for (final fileName in fileNames) {
    try {
      final fullPath = parentPath.isEmpty ? fileName : '$parentPath/$fileName';
      final fileUrl = await getFileUrl(fullPath);
      await deleteFile(fileUrl: fileUrl);
      succeeded.add(fileName);
    } catch (e) {
      // Treat 404 / NotFoundHttpError as success – the file is already
      // gone and the caller's intent is satisfied.

      if (e.toString().contains('404') ||
          e.toString().contains('NotFoundHttpError')) {
        succeeded.add(fileName);
      } else {
        debugPrint('Error deleting file "$fileName": $e');
        failed[fileName] = e.toString();
      }
    }
    completed++;
    onProgress?.call(completed, totalCount);
  }

  // Delete directories (recursively).

  for (final dirName in directoryNames) {
    try {
      await deleteContainer(parentPath, dirName);
      succeeded.add(dirName);
    } catch (e) {
      debugPrint('Error deleting directory "$dirName": $e');
      failed[dirName] = e.toString();
    }
    completed++;
    onProgress?.call(completed, totalCount);
  }

  return BatchDeleteResult(succeeded: succeeded, failed: failed);
}
