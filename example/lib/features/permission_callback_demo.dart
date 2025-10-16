/// A demonstration widget showcasing the onPermissionGranted callback functionality.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

/// A widget demonstrating the onPermissionGranted callback functionality.

class PermissionCallbackDemo extends StatefulWidget {
  const PermissionCallbackDemo({required this.child, super.key});

  final Widget child;

  @override
  State<PermissionCallbackDemo> createState() => _PermissionCallbackDemoState();
}

class _PermissionCallbackDemoState extends State<PermissionCallbackDemo> {
  // Status tracking variables.

  bool _workflowCompleted = false;
  int _currentStep = 1;
  String _statusMessage = 'Ready to start permission workflow';

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
      _workflowCompleted = false;
      _currentStep = 1;
      _currentFileIndex = 0;
      _statusMessage = 'Ready to start permission workflow';
    });
  }

  // Create all demo files automatically.

  Future<void> _ensureDemoFilesExist() async {
    try {
      for (int i = 0; i < _sampleFiles.length; i++) {
        final fileName = _sampleFiles[i];
        final filePath = [await getDataDirPath(), fileName].join('/');

        // Create rich demo content with different data for each file
        final fileNumber = i + 1;
        final demoContent = '''@prefix demo: <#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

demo:sampleData$fileNumber a demo:DemoResource ;
    rdfs:label "Permission Callback Demo File $fileNumber" ;
    demo:created "${DateTime.now().toIso8601String()}" ;
    demo:purpose "Demonstrating onPermissionGranted callback functionality" ;
    demo:fileNumber "$fileNumber" ;
    demo:description "This file demonstrates how callbacks enable automated workflows when sharing multiple files sequentially." ;
    foaf:maker "SolidPod Permission Callback Demo" .

demo:exampleData$fileNumber
    demo:sampleProperty "Sample value $fileNumber" ;
    demo:category "demo-data" ;
    demo:testValue ${fileNumber * 100} .
''';

        // Always create/overwrite the demo file for consistency.

        if (!mounted) return;

        await writePod(filePath, demoContent, context, widget.child);
      }
    } catch (e) {
      debugPrint('❌ [CallbackDemo] Error creating demo files: $e');
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
      _currentStep = 2;
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
                'Share "${_sampleFiles[_currentFileIndex]}" (${_currentFileIndex + 1}/${_sampleFiles.length})',
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
            body: GrantPermissionUi(
              resourceName: _sampleFiles[_currentFileIndex],
              title: 'Demo: Grant Permission with Callback',
              accessModeList: const ['read'], // Simplified for demo.
              recipientTypeList: const ['indi'], // Individual permissions only.
              showAppBar: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: widget.child,

              // 🎯 Key callback being demonstrated.

              onPermissionGranted: () async {
                // This callback is triggered when permissions are successfully granted.

                if (mounted) {
                  // Update our state to reflect success.

                  setState(() {
                    _currentStep = 3;
                    _statusMessage =
                        'Permission granted successfully! Processing next file...';
                  });

                  // Navigate back from the permission screen.

                  Navigator.of(navContext).pop(true);

                  // Continue with the next file in our workflow.

                  await _continueWorkflow();
                }
              },

              // Handle user cancellation/navigation back.

              onNavigateBack: () {
                if (mounted) {
                  setState(() {
                    _statusMessage = 'Permission granting cancelled by user';
                  });
                  Navigator.of(navContext).pop(false);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Continue workflow after permission is granted.

  Future<void> _continueWorkflow() async {
    // Simulate some processing time.

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    _currentFileIndex++;

    if (_currentFileIndex < _sampleFiles.length) {
      // More files to process.

      setState(() {
        _currentStep = 2;
        _statusMessage =
            'Moving to next file: ${_sampleFiles[_currentFileIndex]}';
      });

      // Automatically start next file (in real app, you might want user confirmation).

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _startPermissionWorkflow();
      }
    } else {
      // All files processed.

      setState(() {
        _workflowCompleted = true;
        _currentStep = 4;
        _statusMessage = 'All files shared successfully! Workflow completed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Permission Callback Demo'),
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
              // Header section.

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.blue[700], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Why Use onPermissionGranted Callback?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The onPermissionGranted callback allows your app to automatically continue workflows after users grant permissions. This demo creates sample files automatically and shows how to share multiple files sequentially without manual navigation.',
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Current workflow status section.

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
                      'Workflow Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress indicator.

                    Row(
                      children: [
                        _buildStepIndicator(1, 'Start', _currentStep >= 1),
                        _buildConnector(_currentStep >= 2),
                        _buildStepIndicator(2, 'Grant', _currentStep >= 2),
                        _buildConnector(_currentStep >= 3),
                        _buildStepIndicator(3, 'Process', _currentStep >= 3),
                        _buildConnector(_currentStep >= 4),
                        _buildStepIndicator(4, 'Complete', _currentStep >= 4),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Status message.

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _workflowCompleted
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _workflowCompleted
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _workflowCompleted
                                ? Icons.check_circle
                                : Icons.info,
                            color: _workflowCompleted
                                ? Colors.green[700]
                                : Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _workflowCompleted
                                    ? Colors.green[800]
                                    : Colors.orange[800],
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
                      final isProcessed = index < _currentFileIndex;
                      final isCurrent =
                          index == _currentFileIndex && _currentStep >= 2;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isProcessed
                              ? Colors.green[50]
                              : isCurrent
                                  ? Colors.blue[50]
                                  : Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isProcessed
                                ? Colors.green[200]!
                                : isCurrent
                                    ? Colors.blue[200]!
                                    : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isProcessed
                                  ? Icons.check_circle
                                  : isCurrent
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                              color: isProcessed
                                  ? Colors.green[600]
                                  : isCurrent
                                      ? Colors.blue[600]
                                      : Colors.grey[400],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _sampleFiles[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isProcessed || isCurrent
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            if (isProcessed)
                              const Text(
                                'Shared ✓',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
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
                      onPressed: (_currentStep == 1 || _workflowCompleted)
                          ? _startPermissionWorkflow
                          : null,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_workflowCompleted
                          ? 'Run Demo Again'
                          : 'Start Auto-Demo'),
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

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[600] : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue[600] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.blue[600] : Colors.grey[300],
    );
  }
}
