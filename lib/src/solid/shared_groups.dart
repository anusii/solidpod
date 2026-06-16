/// Persistence for recipient groups used when sharing resources.
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

import 'package:flutter/foundation.dart' show debugPrint, immutable;

import 'package:solidpod/src/solid/read_pod.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/write_pod.dart';

/// Name of the file (within `appname/data/`) that stores the list of
/// recipient groups the user has previously shared resources with. The
/// file is a small JSON document acting as a convenience cache, so it is
/// stored unencrypted to avoid prompting for the security key merely to
/// populate the sharing dialog.

const sharedGroupsFileName = 'shared_groups.json';

/// A named group of recipient WebIDs the user has shared a resource with.
///
/// Groups are remembered so that, when sharing a new resource, the user can
/// pick a previously used group and have its name and members filled in
/// automatically rather than re-typing them.

@immutable
class SharedGroup {
  /// Create a group with the given [name] and member [webIds].

  const SharedGroup({required this.name, required this.webIds});

  /// Build a group from its JSON representation. Unknown or malformed
  /// entries yield an empty member list rather than throwing.

  factory SharedGroup.fromJson(Map<String, dynamic> json) => SharedGroup(
        name: (json['name'] ?? '').toString(),
        webIds: (json['webIds'] is List)
            ? (json['webIds'] as List).map((e) => e.toString()).toList()
            : <String>[],
      );

  /// Human-readable name of the group.

  final String name;

  /// The recipient WebIDs that make up the group.

  final List<String> webIds;

  /// The JSON representation of this group.

  Map<String, dynamic> toJson() => {'name': name, 'webIds': webIds};

  @override
  bool operator ==(Object other) =>
      other is SharedGroup &&
      other.name == name &&
      other.webIds.length == webIds.length &&
      _listEquals(other.webIds, webIds);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(webIds));

  static bool _listEquals(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Read the list of previously used recipient groups from the user's POD.
///
/// Returns an empty list when no groups have been saved yet, or when the
/// cache file cannot be read or parsed. Errors are swallowed deliberately:
/// a missing or corrupt convenience cache should never block the sharing
/// dialog from opening.

Future<List<SharedGroup>> getSharedGroups() async {
  String content;
  try {
    content = await readPod(sharedGroupsFileName);
  } on ResourceNotExistException {
    // No groups have been saved yet.
    return [];
  } on Object catch (e) {
    debugPrint('Unable to read saved groups: $e');
    return [];
  }

  if (content.trim().isEmpty) {
    return [];
  }

  try {
    final decoded = jsonDecode(content);
    final rawGroups = (decoded is Map && decoded['groups'] is List)
        ? decoded['groups'] as List
        : const <dynamic>[];
    return rawGroups
        .whereType<Map>()
        .map((e) => SharedGroup.fromJson(Map<String, dynamic>.from(e)))
        .where((g) => g.name.isNotEmpty && g.webIds.isNotEmpty)
        .toList();
  } on Object catch (e) {
    debugPrint('Unable to parse saved groups: $e');
    return [];
  }
}

/// Save (insert or update) a recipient [group] in the user's POD.
///
/// Any existing group with the same name (case-insensitive) is replaced,
/// and the group is moved to the front of the list so that the most
/// recently used group appears first in the sharing dialog.

Future<void> saveSharedGroup(SharedGroup group) async {
  final name = group.name.trim();
  if (name.isEmpty || group.webIds.isEmpty) {
    return;
  }

  final groups = await getSharedGroups()
    ..removeWhere((g) => g.name.toLowerCase() == name.toLowerCase());
  groups.insert(0, SharedGroup(name: name, webIds: group.webIds));

  await _writeSharedGroups(groups);
}

/// Remove the saved group named [name] (case-insensitive) from the user's
/// POD. Does nothing when no such group exists.

Future<void> deleteSharedGroup(String name) async {
  final target = name.trim().toLowerCase();
  if (target.isEmpty) {
    return;
  }

  final groups = await getSharedGroups();
  final remaining =
      groups.where((g) => g.name.toLowerCase() != target).toList();
  if (remaining.length == groups.length) {
    // Nothing matched; avoid a redundant write.
    return;
  }

  await _writeSharedGroups(remaining);
}

/// Overwrite the saved groups cache file with [groups].

Future<void> _writeSharedGroups(List<SharedGroup> groups) async {
  final content =
      jsonEncode({'groups': groups.map((g) => g.toJson()).toList()});
  await writePod(
    sharedGroupsFileName,
    content,
    encrypted: false,
    overwrite: true,
  );
}
