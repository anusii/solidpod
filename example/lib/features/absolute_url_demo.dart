/// A page to test read/write/delete on the POD using an absolute URL path.
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

import 'package:solidpod/solidpod.dart'
    show PathType, deleteFile, getDataDirPath, getFileUrl, readPod, writePod;

/// A widget that exercises [writePod], [readPod] and [deleteFile] using an
/// absolute-URL path (`PathType.absoluteUrl`).
///
/// The three core file operations resolve their target through
/// [PathType.absoluteUrl], which simply passes the supplied URL straight
/// through to the REST layer. This page lets a tester confirm that a file can
/// be written, read back and deleted again purely by its absolute URL, without
/// relying on any relative-path resolution.
///
/// The URL field is pre-populated with a sensible default pointing at a plain
/// text file in the current app's data directory, but any writable absolute
/// URL on the logged-in user's own POD may be used.

class AbsoluteUrlDemo extends StatefulWidget {
  const AbsoluteUrlDemo({super.key});

  @override
  State<AbsoluteUrlDemo> createState() => _AbsoluteUrlDemoState();
}

class _AbsoluteUrlDemoState extends State<AbsoluteUrlDemo> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _contentController = TextEditingController(
    text: 'Hello from an absolute URL write at ${DateTime.now()}',
  );

  // Last operation outcome shown to the tester.

  String _status = '';

  @override
  void initState() {
    super.initState();
    _prefillDefaultUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Resolve a default absolute URL inside the current app's data directory so
  /// the tester has a ready-to-use, writable target. A plain `.txt` file is
  /// used so the content round-trips verbatim (no encryption / turtle parsing).

  Future<void> _prefillDefaultUrl() async {
    try {
      final url = await getFileUrl(
        [await getDataDirPath(), 'absolute_url_demo.txt'].join('/'),
      );
      if (mounted) {
        _urlController.text = url;
      }
    } catch (e) {
      // Leave the field empty if the URL cannot be resolved (e.g. not yet
      // logged in); the tester can paste a URL manually.

      debugPrint('Could not resolve default absolute URL: $e');
    }
  }

  /// Write the entered content to the absolute URL via [PathType.absoluteUrl].

  Future<void> _write() async {
    final url = _urlController.text.trim();
    try {
      await writePod(
        url,
        _contentController.text,
        encrypted: false,
        overwrite: true,
        pathType: PathType.absoluteUrl,
      );
      _setStatus('Write OK -> $url');
    } catch (e) {
      _setStatus('Write failed: $e');
    }
  }

  /// Read the file back from the absolute URL via [PathType.absoluteUrl].

  Future<void> _read() async {
    final url = _urlController.text.trim();
    try {
      final content = await readPod(url, pathType: PathType.absoluteUrl);
      _setStatus('Read OK -> $url\n\n$content');
    } catch (e) {
      _setStatus('Read failed: $e');
    }
  }

  /// Delete the file by its absolute URL. [deleteFile] is URL-based, so the
  /// absolute URL can be handed to it directly.

  Future<void> _delete() async {
    final url = _urlController.text.trim();
    try {
      await deleteFile(fileUrl: url);
      _setStatus('Delete OK -> $url');
    } catch (e) {
      _setStatus('Delete failed: $e');
    }
  }

  void _setStatus(String message) {
    if (mounted) {
      setState(() {
        _status = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absolute URL Read/Write/Delete'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This page calls writePod / readPod with '
                'PathType.absoluteUrl, and deleteFile with the same absolute '
                'URL, to verify that all three operations work against a '
                'full resource URL on your own POD.',
                style: TextStyle(fontSize: 16.0, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Absolute resource URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content to write',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: _write,
                    child: const Text('Write (absoluteUrl)'),
                  ),
                  ElevatedButton(
                    onPressed: _read,
                    child: const Text('Read (absoluteUrl)'),
                  ),
                  ElevatedButton(
                    onPressed: _delete,
                    child: const Text('Delete (by URL)'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
