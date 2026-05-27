/// A demo screen for the `isFileEncrypted` helper exposed by solidpod.
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart'
    show
        EncryptionStatus,
        PathType,
        getFileEncryptionStatus,
        isFileEncrypted,
        writePod;

import 'package:demopod/constants/app.dart';

/// A small demo that lets the user check whether an arbitrary file on the
/// POD is encrypted by solidpod.
///
/// The screen also offers helpers for seeding both an encrypted and a
/// plaintext sample file so that the verification button can be tested
/// without any prior setup.

class CheckFileEncryption extends StatefulWidget {
  /// Default constructor.

  const CheckFileEncryption({super.key});

  @override
  State<CheckFileEncryption> createState() => _CheckFileEncryptionState();
}

class _CheckFileEncryptionState extends State<CheckFileEncryption> {
  // Sample files seeded by the helper buttons. Both live under the app's
  // data directory so the default `relativeToData` path type works out of
  // the box.

  static const String _encryptedSamplePath =
      'encryption-check-demo/encrypted-sample.ttl';
  static const String _plainSamplePath =
      'encryption-check-demo/plain-sample.ttl';

  static const String _sampleContent = '''@prefix demo: <#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

demo:sampleResource a demo:DemoResource ;
    rdfs:label "Encryption check demo" ;
    demo:note "Created by the solidpod example app to exercise isFileEncrypted()." .
''';

  final TextEditingController _pathController =
      TextEditingController(text: _encryptedSamplePath);

  PathType _pathType = PathType.relativeToData;
  bool _isBusy = false;
  String? _lastResult;
  Color _lastResultColor = Colors.black87;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _runCheck() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() {
        _lastResult = 'Please enter a file path before running the check.';
        _lastResultColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _lastResult = null;
    });

    try {
      final status = await getFileEncryptionStatus(
        path,
        pathType: _pathType,
      );

      // Also call the boolean wrapper to demonstrate both APIs.

      final encryptedFlag = await isFileEncrypted(path, pathType: _pathType);

      if (!mounted) return;
      setState(() {
        _lastResult = _formatStatus(status, encryptedFlag);
        _lastResultColor = _colourForStatus(status);
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _lastResult = 'Error: $e';
        _lastResultColor = Colors.red;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _seedSample({required bool encrypted}) async {
    final path = encrypted ? _encryptedSamplePath : _plainSamplePath;
    setState(() {
      _isBusy = true;
      _lastResult = null;
    });

    try {
      await writePod(
        path,
        _sampleContent,
        encrypted: encrypted,

        // Avoid raising an error if the file already exists from a prior run.

        overwrite: true,
      );

      if (!mounted) return;
      setState(() {
        _pathController.text = path;
        _pathType = PathType.relativeToData;
        _lastResult = 'Seeded ${encrypted ? "encrypted" : "plaintext"} '
            'sample at "$path". Press "Check Encryption" to verify.';
        _lastResultColor = Colors.blueGrey;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _lastResult = 'Failed to seed sample: $e';
        _lastResultColor = Colors.red;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String _formatStatus(EncryptionStatus status, bool encryptedFlag) {
    switch (status) {
      case EncryptionStatus.encrypted:
        return 'Encrypted by solidpod.\n'
            'isFileEncrypted() returned $encryptedFlag.';
      case EncryptionStatus.notEncrypted:
        return 'Plaintext (not encrypted by solidpod).\n'
            'isFileEncrypted() returned $encryptedFlag.';
      case EncryptionStatus.notExist:
        return 'The resource does not exist on the POD.';
      case EncryptionStatus.forbidden:
        return 'Access to the resource is forbidden for the current WebID.';
      case EncryptionStatus.unknown:
        return 'Unknown error while inspecting the resource.\n'
            'Check the debug console for details.';
    }
  }

  Color _colourForStatus(EncryptionStatus status) {
    switch (status) {
      case EncryptionStatus.encrypted:
        return Colors.green.shade800;
      case EncryptionStatus.notEncrypted:
        return Colors.orange.shade800;
      case EncryptionStatus.notExist:
      case EncryptionStatus.forbidden:
      case EncryptionStatus.unknown:
        return Colors.red.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: titleBackgroundColor,
        title: const Text('Check File Encryption'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Use this screen to check whether a file on your POD has been '
              'encrypted by SolidPod. SolidPod does not require the '
              '".enc.ttl" suffix for encrypted files, so the suffix alone is '
              'not a reliable indicator. The check inspects the actual '
              'Turtle metadata on the server.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pathController,
              enabled: !_isBusy,
              decoration: const InputDecoration(
                labelText: 'File path or URL',
                border: OutlineInputBorder(),
                helperText:
                    'Example: "encryption-check-demo/encrypted-sample.ttl"',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PathType>(
              // ignore: deprecated_member_use
              value: _pathType,
              decoration: const InputDecoration(
                labelText: 'Path type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: PathType.relativeToData,
                  child: Text('Relative to data dir (default)'),
                ),
                DropdownMenuItem(
                  value: PathType.relativeToApp,
                  child: Text('Relative to app dir'),
                ),
                DropdownMenuItem(
                  value: PathType.relativeToPod,
                  child: Text('Relative to POD root'),
                ),
                DropdownMenuItem(
                  value: PathType.absoluteUrl,
                  child: Text('Absolute URL'),
                ),
              ],
              onChanged: _isBusy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _pathType = value;
                        });
                      }
                    },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _runCheck,
              icon: const Icon(Icons.lock_outlined),
              label: const Text('Check Encryption'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Optional helpers: seed a sample file under the data dir so '
              'that the check above has something to inspect. Each press '
              'overwrites the previous sample.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      _isBusy ? null : () => _seedSample(encrypted: true),
                  icon: const Icon(Icons.lock),
                  label: const Text('Seed Encrypted Sample'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _isBusy ? null : () => _seedSample(encrypted: false),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Seed Plaintext Sample'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isBusy)
              const Center(child: CircularProgressIndicator())
            else if (_lastResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: _lastResultColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastResult!,
                  style: TextStyle(
                    fontSize: 15,
                    color: _lastResultColor,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
