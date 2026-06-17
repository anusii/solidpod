/// A page to create and delete folders (containers) that carry their own ACL.
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

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show createContainer, deleteContainer;

/// A widget to create or delete a folder (container) on the POD.
///
/// Folders created here are given their own `.acl` file (via [createContainer])
/// so that the folder, and any resources placed within it, can be shared
/// independently of the parent folder.

class ManageAclFolder extends StatefulWidget {
  const ManageAclFolder({super.key});

  @override
  ManageAclFolderState createState() => ManageAclFolderState();
}

class ManageAclFolderState extends State<ManageAclFolder> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text fields.

  final TextEditingController _parentPathController = TextEditingController();
  final TextEditingController _folderNameController = TextEditingController();

  // Whether an operation is currently running, used to disable the buttons.

  bool _busy = false;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed.

    _parentPathController.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  // Creates the folder together with its `.acl` file.

  Future<void> _createFolder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parentPath = _parentPathController.text.trim();
    final folderName = _folderNameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      // createAcl defaults to true, so the new folder receives its own `.acl`.

      await createContainer(parentPath, folderName);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Folder "$folderName" created with an ACL file.'),
        ),
      );
    } on Object catch (e, trace) {
      debugPrint(e.toString());
      debugPrint(trace.toString());

      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create folder: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Deletes the folder and all of its contents (including its `.acl`).

  Future<void> _deleteFolder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parentPath = _parentPathController.text.trim();
    final folderName = _folderNameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    // Ask for confirmation since deletion is recursive and irreversible.

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'This will permanently delete the folder "$folderName" and all of '
          'its contents, including its ACL file. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await deleteContainer(parentPath, folderName);

      messenger.showSnackBar(
        SnackBar(content: Text('Folder "$folderName" deleted.')),
      );
    } on Object catch (e, trace) {
      debugPrint(e.toString());
      debugPrint(trace.toString());

      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete folder: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create / delete a folder with ACL'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction paragraph.

              const Text(
                'Create a folder (container) on your Pod. The folder is given '
                'its own ACL file so it can be shared independently of its '
                'parent folder. The "Parent Path" is the folder, relative to '
                'your app data directory, that will contain the new folder '
                '(leave it empty to create the folder directly in the data '
                'directory). The "Folder Name" is the name of the folder to '
                'create or delete.',
                style: TextStyle(fontSize: 16.0, height: 1.5),
              ),
              const SizedBox(height: 24),

              // Parent path field (optional).

              TextFormField(
                controller: _parentPathController,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Parent Path (optional)',
                  hintText: 'e.g. myfolder  (empty = data directory root)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Folder name field (required).

              TextFormField(
                controller: _folderNameController,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'e.g. shared',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a folder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Create button.

              ElevatedButton(
                onPressed: _busy ? null : _createFolder,
                child: const Text('Create folder (with ACL)'),
              ),
              const SizedBox(height: 12),

              // Delete button.

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: _busy ? null : _deleteFolder,
                child: const Text('Delete folder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
