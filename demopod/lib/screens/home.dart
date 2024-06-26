/// A simple key value table for the home screen.
///
// Time-stamp: <Sunday 2024-05-26 11:05:15 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Kevin Wang, Graham Williams

// TODO 20240526 gjw EITHER REPAIR ALL CONTEXT ISSUES OR EXPLAIN WHY NOT?

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:path/path.dart' as path;

import 'package:keypod/screens/data_table.dart';
import 'package:keypod/screens/demo.dart';
import 'package:keypod/utils/constants.dart';
import 'package:keypod/utils/rdf.dart';

class HomeScreen extends StatefulWidget {
  /// Constructor for the home screen.

  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Automatically tap the KEYPODS button when the screen loads.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _writePrivateData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Key Value Pairs... '),
        backgroundColor: titleBackgroundColor,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: titleBackgroundColor,
      body: Stack(
        children: <Widget>[
          _buildMainContent(),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 20),
        Expanded(child: Container()),
      ],
    );
  }

  // TODO 20240524 gjw Is this used? My linter is complaining.
  //
  // Widget _buildButton(String title, VoidCallback onPressed) {
  //   return ElevatedButton(
  //     onPressed: onPressed,
  //     style: ElevatedButton.styleFrom(
  //       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
  //       textStyle: const TextStyle(fontSize: 16),
  //     ),
  //     child: Text(title, style: const TextStyle(fontSize: 16)),
  //   );
  // }

  Future<void> _writePrivateData() async {
    const fileName = dataFile;

    try {
      setState(() {
        // Show the loading indicator.
        _isLoading = true;
      });

      // TODO (dc): Please explain this simulation, why is it necessary?
      // Simulate a network call.

      // await Future.delayed(const Duration(seconds: 2));

      // Navigate or perform additional actions after loading
      final dataDirPath = await getDataDirPath();
      final filePath = path.join(dataDirPath, fileName);

      final fileContent = await readPod(filePath, context, const DemoScreen());
      final pairs = fileContent == null ? null : await parseTTLStr(fileContent);

      // Convert each tuple to a map.

      final keyValuePairs = pairs?.map((pair) {
        return {'key': pair.key, 'value': pair.value};
      }).toList();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KeyValueTable(
            title: 'Key Value Pair Editor',
            fileName: fileName,
            keyValuePairs: keyValuePairs,
            child: const HomeScreen(),
          ),
        ),
      );
    } on Exception catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          // Hide the loading indicator.
          _isLoading = false;
        });
      }
    }
  }
}
