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
    show ResourceStatus, checkResourceStatus, filenameToResourceUrl, writePod;

import 'package:demopod/dialogs/alert.dart';

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
