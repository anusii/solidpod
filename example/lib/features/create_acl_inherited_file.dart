/// A page to create resources with ACL inheritance
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

import 'package:solidpod/solidpod.dart' show SolidFunctionCallStatus, writePod;
import 'package:demopod/constants/app.dart';

// A widget to create a resource with inherited ACL.
//
// The resource will be created inside a parent directory and the ACL of that
// directory will be inherited for that resource.
//
// If resource need to be encrypted, a single encryption key assigned to the
// parent directory will be used for the encryption.
class CreateAclInheritedFile extends StatefulWidget {
  const CreateAclInheritedFile({super.key});

  @override
  CreateAclInheritedFileState createState() => CreateAclInheritedFileState();
}

class CreateAclInheritedFileState extends State<CreateAclInheritedFile> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text fields
  final TextEditingController _resourcePathController = TextEditingController();
  final TextEditingController _parentDirectoryController =
      TextEditingController();

  // Toggle switch value
  bool _isEncrypted = true;

  @override
  void dispose() {
    // Dispose controllers when widget is removed
    _resourcePathController.dispose();
    _parentDirectoryController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Retrieve entered values
      String resourcePath = _resourcePathController.text.trim();
      String parentDirectory = _parentDirectoryController.text.trim();

      final demoTtlContent = createDemoTtlStr(resourcePath);

      if (context.mounted) {
        final result = await writePod(
            resourcePath, demoTtlContent, context, widget,
            encrypted: _isEncrypted, inheritedFrom: parentDirectory);

        if (result == SolidFunctionCallStatus.success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resource created successfully!')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'There was a problem creating resource! Please try again later.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a resource with ACL inheritance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Instruction paragraph
              const Text(
                'Fill out the following two text fields according to the below '
                'instructions. The "Resource Path" field should contain the path '
                'to the resource itself including the actual resource name. An '
                'example would be "parentDir/sampleRes.ttl". The "Parent Dir"'
                'should contain the path to the actual parent directory where the '
                'resource will inherit the ACL file from. An example would be '
                '"parentDir".',
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
              const SizedBox(height: 16),

              // Parent directory field
              TextFormField(
                controller: _parentDirectoryController,
                decoration: const InputDecoration(
                  labelText: 'Parent Directory',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a parent directory';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Encrypted Toggle Switch
              SwitchListTile(
                title: const Text(
                  'Encrypted',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isEncrypted
                      ? 'This resource content will be stored in encrypted form.'
                      : 'This resource content will not be encrypted.',
                ),
                value: _isEncrypted,
                onChanged: (bool value) {
                  setState(() {
                    _isEncrypted = value;
                  });
                },
                thumbColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.green;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create resource'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
