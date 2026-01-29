/// Utilities for parsing permission json data into data model.
///
// Time-stamp: <Thursday 2026-01-29 13:26:16 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/models/permission.dart';

/// Helper class for permission data operations.

class PermissionHelper {
  PermissionHelper();

  /// Parses permission map into permission data object of type [Permission].
  ///
  /// Arguments:
  /// - [recipientWebId] - WebId of recipient.
  /// - [permMap] - Map of permissions of a single recipient with
  /// this[recipientWebId].
  ///

  static Permission? extractPermission({
    required Map permMap,
    required String recipientWebId,
  }) {
    try {
      List<String>? permList;
      String? agentType;
      String? recipientType;
      String? recipientName;

      for (final entry in permMap.entries) {
        final predicate = entry.key.toString();
        final value = entry.value.toString();

        if (predicate.contains(agentStr)) {
          // Extract agentType
          agentType = value;
        } else if (predicate.contains(permStr)) {
          // Extract permission list as list of strings;
          permList = value
              .replaceAll('[', '')
              .replaceAll(']', '') // strip off enclosing brackets
              .split(',')
              .map(
                (item) => item.trim(),
              ) // Remove leading/trailing white space from each item
              .toList();
        }
      }

      // Derive recipient type description
      recipientType = getRecipientType(agentType!, recipientWebId).description;

      // Derive recipient name
      recipientName = getRecipientName(recipientWebId);

      // Create the external note details object

      return Permission(
        recipientWebId: recipientWebId,
        recipientName: recipientName,
        recipientType: recipientType,
        agentType: agentType,
        permList: permList!,
      );
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}

List<Permission> permMapToList(Map map) {
  final List<Permission> permissions = [];

  if (map.isNotEmpty) {
    debugPrint('Full map: ${map.toString()}');

    for (final recipientWebId in map.keys) {
      debugPrint('recipientWebId: $recipientWebId');
      debugPrint('map: ${map[recipientWebId]}');

      // Deserialise permission record
      try {
        final Permission? permission;

        // Extract to Permission object
        permission = PermissionHelper.extractPermission(
          permMap: map[recipientWebId],
          recipientWebId: recipientWebId,
        );

        if (permission != null) {
          permissions.add(permission);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  return permissions;
}
