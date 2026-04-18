/// A widget demonstrating sharing of multiple files.
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
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart' show GrantPermissionUi;

// import 'package:demopod/widgets/permission_demo_widgets.dart';

/// A widget demonstrating sharing of multiple resources.

class MultiResourceShareDemo extends StatefulWidget {
  const MultiResourceShareDemo({required this.child, super.key});

  final Widget child;

  @override
  State<MultiResourceShareDemo> createState() => _MultiResourceShareDemoState();
}

class _MultiResourceShareDemoState extends State<MultiResourceShareDemo> {
  // Status tracking variables.

  // bool _workflowCompleted = false;
  // int _currentStep = 1;
  String _statusMessage = 'Ready to start granting permission to file list';

  // Sample files to demonstrate batch permission granting.
  // All files will be auto-created for the demo.

  final List<String> _sampleFiles = [
    'callback-demo/sample-1.ttl',
    'callback-demo/sample-2.ttl',
    'callback-demo/sample-3.ttl',
  ];

  int _currentFileIndex = 0;

  // Reset the demo state.

  void _resetDemo() {
    setState(() {
      // _workflowCompleted = false;
      // _currentStep = 1;
      _currentFileIndex = 0;
      _statusMessage = 'Ready to start granting permission to file list';
    });
  }

  // Create all demo files automatically.

  Future<void> _ensureDemoFilesExist() async {
    try {
      for (int i = 0; i < _sampleFiles.length; i++) {
        final fileName = _sampleFiles[i];

        // Create rich demo content with different data for each file
        final fileNumber = i + 1;
        final demoContent = '''@prefix demo: <#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

demo:sampleData$fileNumber a demo:DemoResource ;
    rdfs:label "Multiple File Sharing Demo File $fileNumber" ;
    demo:created "${DateTime.now().toIso8601String()}" ;
    demo:purpose "Demonstrating sharing of multiple files" ;
    demo:fileNumber "$fileNumber" ;
    demo:description "This is a sameple file for demonstrating sharing multiple files sequentially." ;
    foaf:maker "SolidPod Multi Resource Share Demo" .

demo:exampleData$fileNumber
    demo:sampleProperty "Sample value $fileNumber" ;
    demo:category "demo-data" ;
    demo:testValue ${fileNumber * 100} .
''';

        // Always create/overwrite the demo file for consistency.

        if (!mounted) return;

        await writePod(fileName, demoContent);
      }
    } catch (e) {
      debugPrint('❌ [MultiShareDemo] Error creating demo files: $e');
      rethrow; // Re-throw to show user the error
    }
  }

  // Navigate to Grant Permission UI with callback.

  Future<void> _startPermissionWorkflow() async {
    // Always ensure demo files exist on first run.

    if (_currentFileIndex == 0) {
      setState(() {
        _statusMessage = 'Setting up demo files for fresh POD...';
      });

      try {
        await _ensureDemoFilesExist();
        setState(() {
          _statusMessage = 'Demo files created! Starting workflow...';
        });
        // Small delay to show success message.

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _statusMessage = 'Failed to create demo files: $e';
        });
      }
    }

    setState(() {
      // _currentStep = 2;
      _statusMessage =
          'Navigate to permission screen for file ${_currentFileIndex + 1} of ${_sampleFiles.length}';
    });

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (navContext) => Theme(
          data: Theme.of(context),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(
                'Multi file sharing',
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
            body: GrantPermissionUi(
              resourceNames: _sampleFiles,
              title: 'Demo: Grant Permission on Multiple Files',
              accessModeList: const ['read'], // Simplified for demo.
              recipientTypeList: const ['indi'], // Individual permissions only.
              showAppBar: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              // ownerWebId: widget.bookOwner,
              child: widget.child,

              // // Handle user cancellation/navigation back.

              // onNavigateBack: () {
              //   if (mounted) {
              //     setState(() {
              //       _statusMessage = 'Permission granting cancelled by user';
              //     });
              //     Navigator.of(navContext).pop(false);
              //   }
              // },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Multi File Sharing Demo'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Troubleshooting'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'This demo is fully self-contained!\n\n'
                      '• All demo files are created automatically\n'
                      '• No manual setup required\n'
                      '• Works on fresh PODs out of the box\n'
                      '• Just enter a valid WebID and click "Start Auto-Demo"\n'
                      '• Try sharing with yourself first for testing\n'
                      '• Check console (F12) for detailed logs if needed\n\n'
                      'Common issues:\n'
                      '• Verify recipient WebID format ends with #me\n'
                      '• Ensure recipient has logged into their POD at least once\n'
                      '• Check browser console for detailed error logs',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Troubleshooting Help',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo status section.

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demo Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status message.

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Files to process section.

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Files to Share',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message:
                              'Demo creates all files automatically - no setup required!',
                          child: Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_sampleFiles.length, (index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _sampleFiles[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons section.

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startPermissionWorkflow,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text('Start Auto-Demo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetDemo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Demo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Extra padding at bottom to ensure scrolling works properly.

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
