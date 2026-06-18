/// Utility to ensure a Pod resource exists before performing actions on it.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart'
    show
        ResourceStatus,
        checkResourceStatus,
        createContainer,
        filenameToResourceUrl,
        writePod;

import 'package:solidpodeg/dialogs/alert.dart';

/// Ensures the resource at [relativePath] exists in the user's Pod.
///
/// The [relativePath] is interpreted relative to the app's data directory
/// (e.g. `keyvalue/key-value.ttl`). When the resource is missing on the Pod,
/// a new file is created using [defaultContent] (encrypted by default) so
/// downstream actions such as granting permissions do not fail.
///
/// Returns `true` when the resource is available (already existed or was
/// just created), and `false` otherwise.

Future<bool> ensurePodResourceExists(
  BuildContext context, {
  required String relativePath,
  required String defaultContent,
  bool encrypted = true,
}) async {
  try {
    final fileUrl = await filenameToResourceUrl(fileName: relativePath);

    final status = await checkResourceStatus(fileUrl);

    switch (status) {
      case ResourceStatus.exist:
        return true;

      case ResourceStatus.notExist:
        await _ensureParentContainerWithAcl(relativePath);
        await writePod(relativePath, defaultContent, encrypted: encrypted);

        if (context.mounted) {
          await alert(
            context,
            'The resource "$relativePath" did not exist on your Pod, '
            'so a new file with placeholder content has been created '
            'automatically.',
          );
        }
        return true;

      case ResourceStatus.forbidden:
        if (context.mounted) {
          await alert(
            context,
            'Access to "$relativePath" is forbidden. Please check the '
            'permissions on your Pod and try again.',
          );
        }
        return false;

      case ResourceStatus.unknown:
        if (context.mounted) {
          await alert(
            context,
            'Unable to determine whether "$relativePath" exists on your Pod. '
            'Please try again in a moment.',
          );
        }
        return false;
    }
  } on Object catch (e) {
    debugPrint('ensurePodResourceExists() failed: $e');
    if (context.mounted) {
      await alert(
        context,
        'Failed to ensure "$relativePath" exists on your Pod: $e',
      );
    }
    return false;
  }
}

/// Ensures the parent folder of [relativePath] exists on the Pod with its own
/// `.acl` file.
///
/// [relativePath] is a file path relative to the app's data directory (e.g.
/// `keyvalue/key-value.ttl`). When the path contains no folder component the
/// file sits directly in the data root and there is nothing to create.
///
/// If the parent folder already exists it is left untouched (it may already
/// carry an `.acl`); otherwise [createContainer] creates it together with a
/// default `.acl` so the folder can be shared.

Future<void> _ensureParentContainerWithAcl(String relativePath) async {
  final slash = relativePath.lastIndexOf('/');
  if (slash < 0) return;

  final dirPath = relativePath.substring(0, slash);

  // Resolve the directory URL relative to the app data directory (the same
  // convention used by writePod and createContainer). filenameToResourceUrl
  // prepends `appname/data` and is idempotent for paths that already include
  // it.

  final dirUrl = await filenameToResourceUrl(
    fileName: dirPath,
    isFile: false,
  );

  // Skip creation if the folder already exists; createContainer would fail on
  // an existing container, and an existing folder may already have its `.acl`.

  if (await checkResourceStatus(dirUrl, isFile: false) ==
      ResourceStatus.exist) {
    return;
  }

  // Split the directory path into its parent path and leaf folder name as
  // expected by createContainer.

  final sep = dirPath.lastIndexOf('/');
  final parentPath = sep < 0 ? '' : dirPath.substring(0, sep);
  final folderName = sep < 0 ? dirPath : dirPath.substring(sep + 1);

  await createContainer(parentPath, folderName);
}
