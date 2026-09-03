// Rendering the instructions in solidpod/README.md.
//
// Copyright (C) 2026, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://opensource.org/license/gpl-3-0.
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
//
// Authors: Dawei Chen

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solidpod Readme',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const ReadmeViewer(),
    );
  }
}

class ReadmeViewer extends StatefulWidget {
  const ReadmeViewer({super.key});

  @override
  State<ReadmeViewer> createState() => _ReadmeViewerState();
}

class _ReadmeViewerState extends State<ReadmeViewer> {
  late Future<String> _markdownDataFuture;

  final defaultMessage =
      'solidpod is a low-level library, consider using solidui instead.';

  final String _url =
      'https://raw.githubusercontent.com/anusii/solidpod/refs/heads/dev/README.md';

  @override
  void initState() {
    super.initState();
    _markdownDataFuture = fetchReadme(_url);
  }

  // Network request logic to fetch raw file data
  Future<String> fetchReadme(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body; // Returns raw Markdown string
      } else {
        throw Exception('Failed to load Readme: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _markdownDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return Markdown(
            data: snapshot.data ?? defaultMessage,
            selectable: true,
          );
        },
      ),
    );
  }
}
