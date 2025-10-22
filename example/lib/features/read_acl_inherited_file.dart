/// A page to read resources with ACL inheritance
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show readPod;

// A widget to create a resource with inherited ACL.
//
// The resource will be created inside a parent directory and the ACL of that
// directory will be inherited for that resource.
//
// If resource need to be encrypted, a single encryption key assigned to the
// parent directory will be used for the encryption.
class ReadAclInheritedFile extends StatefulWidget {
  const ReadAclInheritedFile({super.key});

  @override
  ReadAclInheritedFileState createState() => ReadAclInheritedFileState();
}

class ReadAclInheritedFileState extends State<ReadAclInheritedFile> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text fields
  final TextEditingController _resourcePathController = TextEditingController();

  // File content
  String _fileContent = '';

  @override
  void dispose() {
    // Dispose controllers when widget is removed
    _resourcePathController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Retrieve entered values
      String resourcePath = _resourcePathController.text.trim();

      try {
        String fileContent = await readPod(
          resourcePath,
          context,
          widget,
        );

        setState(() {
          _fileContent = fileContent;
        });
      } catch (e) {
        setState(() {
          _fileContent = 'Error reading file: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read a resource with ACL inheritance'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Instruction paragraph
                const Text(
                  'The "Resource Path" field should contain the path '
                  'to the resource itself including the actual resource name '
                  'and extention. An example would be "parentDir/sampleRes.ttl".',
                  style: TextStyle(fontSize: 16.0, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Resource path field
                TextFormField(
                  controller: _resourcePathController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Path',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a resource path';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('read resource'),
                ),

                const SizedBox(height: 10),
                // Display file content if available
                if (_fileContent.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _fileContent,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
