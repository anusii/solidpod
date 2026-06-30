/// A screen to drive the headless Solid load tester and visualise its progress.
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A demonstrator screen that launches `loadtest/solid_load_test.py` and renders
/// its JSON-Lines progress in real time.
///
/// The heavy lifting (creating up to ~100 accounts and Pods, logging in, and
/// reading/writing resources concurrently) lives in the Python script so the
/// test runs headlessly and scales well beyond what interactive in-app OIDC
/// login could manage. This screen is purely a launcher and live dashboard: it
/// spawns the script with `--json`, streams its stdout, and updates as each
/// `phase`, `progress` and `summary` event arrives.
///
/// Spawning a child process needs `dart:io`, so the feature is only available on
/// the desktop builds of the demonstrator (it is disabled on web).

class LoadTest extends StatefulWidget {
  /// Initialise widget variables.

  const LoadTest({super.key});

  @override
  State<LoadTest> createState() => _LoadTestState();
}

class _LoadTestState extends State<LoadTest> {
  // The default target server under test.

  static const _defaultServer = 'https://solid.dev.empwr.au';

  // Form controllers. The interpreter and script paths are resolved to absolute
  // paths in initState by walking up from the running executable (see
  // _resolveDefaults); the values below are only fallbacks for when that
  // resolution fails (e.g. a relocated release build). Both can be edited.

  final _serverCtrl = TextEditingController(text: _defaultServer);
  final _usersCtrl = TextEditingController(text: '20');
  final _concurrencyCtrl = TextEditingController(text: '10');
  final _resourcesCtrl = TextEditingController(text: '3');
  final _prefixCtrl = TextEditingController(text: 'loadtest');
  final _domainCtrl = TextEditingController(text: 'example.org');
  final _passwordCtrl = TextEditingController(text: 'Load-Test-Pw-1!');
  final _pythonCtrl = TextEditingController(text: 'python3');
  final _scriptCtrl =
      TextEditingController(text: 'loadtest/solid_load_test.py');

  // The resolved example-app directory (the parent of loadtest/), if located by
  // walking up from the running executable. Used as the working directory for
  // the spawned script so it can find its virtualenv and resources.

  String? _exampleDir;

  bool _changePassword = false;
  bool _encrypt = true;

  // Live run state.

  Process? _process;
  bool get _running => _process != null;

  int _completed = 0;
  int _total = 0;
  int _ok = 0;
  int _failed = 0;

  // The most recent summary, parsed from the final `summary` event.

  Map<String, dynamic>? _summary;

  // A rolling log of recent events shown in the bottom pane. Capped so a long
  // run does not grow the list without bound.

  final List<String> _log = [];
  static const _maxLogLines = 400;

  final _logScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _resolveDefaults();
  }

  // Resolve absolute defaults for the script and interpreter paths.
  //
  // The process working directory on macOS is not the project directory (under
  // the App Sandbox it is the container root), so a relative script path cannot
  // be relied upon. Instead the load tester is located on disk relative to the
  // running executable and the resulting absolute path is used.

  void _resolveDefaults() {
    if (kIsWeb) return;
    final dir = _findExampleDir();
    if (dir == null) return;
    _exampleDir = dir;

    final script = '$dir/loadtest/solid_load_test.py';
    if (File(script).existsSync()) {
      _scriptCtrl.text = script;
    }

    // Prefer the project's virtualenv interpreter (created per
    // loadtest/README.md) so the third-party dependencies (httpx, cryptography)
    // are available without relying on a global Python installation.

    for (final candidate in [
      '$dir/loadtest/.venv/bin/python3',
      '$dir/loadtest/.venv/bin/python',
    ]) {
      if (File(candidate).existsSync()) {
        _pythonCtrl.text = candidate;
        break;
      }
    }
  }

  // Walk up from the running executable looking for the directory that contains
  // loadtest/solid_load_test.py. When run with `flutter run -d macos` the
  // executable lives several levels below the example directory inside
  // build/macos/..., so a bounded upward search reliably finds it. Returns null
  // if no such directory is found.

  String? _findExampleDir() {
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 12; i++) {
      if (File('${dir.path}/loadtest/solid_load_test.py').existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break; // Reached the filesystem root.
      dir = parent;
    }
    return null;
  }

  @override
  void dispose() {
    // Make sure a running test does not outlive the screen.

    _process?.kill();
    _serverCtrl.dispose();
    _usersCtrl.dispose();
    _concurrencyCtrl.dispose();
    _resourcesCtrl.dispose();
    _prefixCtrl.dispose();
    _domainCtrl.dispose();
    _passwordCtrl.dispose();
    _pythonCtrl.dispose();
    _scriptCtrl.dispose();
    _logScrollCtrl.dispose();
    super.dispose();
  }

  // Append a line to the rolling log and scroll to the bottom.

  void _appendLog(String line) {
    setState(() {
      _log.add(line);
      if (_log.length > _maxLogLines) {
        _log.removeRange(0, _log.length - _maxLogLines);
      }
    });
    // Defer the scroll until after the new line has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollCtrl.hasClients) {
        _logScrollCtrl.jumpTo(_logScrollCtrl.position.maxScrollExtent);
      }
    });
  }

  // Build the script arguments from the current form values.

  List<String> _buildArgs() {
    final args = <String>[
      _scriptCtrl.text.trim(),
      '--json',
      '--server',
      _serverCtrl.text.trim(),
      '--users',
      _usersCtrl.text.trim(),
      '--concurrency',
      _concurrencyCtrl.text.trim(),
      '--resources',
      _resourcesCtrl.text.trim(),
      '--prefix',
      _prefixCtrl.text.trim(),
      '--email-domain',
      _domainCtrl.text.trim(),
      '--password',
      _passwordCtrl.text,
    ];
    if (_changePassword) args.add('--change-password');
    if (!_encrypt) args.add('--no-encrypt');
    return args;
  }

  // Launch the Python load tester and wire up its output streams.

  Future<void> _startRun() async {
    if (_running) return;

    // Reset the dashboard for the new run.

    setState(() {
      _completed = 0;
      _total = int.tryParse(_usersCtrl.text.trim()) ?? 0;
      _ok = 0;
      _failed = 0;
      _summary = null;
      _log.clear();
    });

    final python = _pythonCtrl.text.trim();
    final args = _buildArgs();
    _appendLog('\$ $python ${args.join(' ')}');

    Process process;
    try {
      process = await Process.start(
        python,
        args,
        workingDirectory: _exampleDir,
      );
    } on Object catch (e) {
      _appendLog('Failed to start the load tester: $e');
      _appendLog(
        'Check that the Python executable and script path above are correct '
        '(absolute paths are filled in automatically when the loadtest/ '
        'directory is found), and that the dependencies in '
        'loadtest/requirements.txt are installed in that interpreter.',
      );
      return;
    }

    setState(() {
      _process = process;
    });

    // Parse each line of stdout as a JSON event.

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine);

    // Surface anything on stderr (e.g. a Python traceback) in the log.

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _appendLog('stderr: $line'));

    // Clear the running state once the process exits.

    unawaited(process.exitCode.then((code) {
      _appendLog('Load tester exited with code $code.');
      if (mounted) {
        setState(() {
          _process = null;
        });
      }
    }));
  }

  // Stop a run in progress.

  void _stopRun() {
    _process?.kill();
    _appendLog('Stopping load tester...');
  }

  // Decode and act on a single JSON-Lines event from the script.

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;

    Map<String, dynamic> event;
    try {
      event = jsonDecode(line) as Map<String, dynamic>;
    } on Object {
      // Not a JSON line (e.g. a stray print); show it verbatim.

      _appendLog(line);
      return;
    }

    switch (event['event']) {
      case 'start':
        _appendLog(
          'Started: ${event['users']} users, concurrency '
          '${event['concurrency']}, server ${event['server']}',
        );

      case 'phase':
        final status = (event['status'] as String).toUpperCase();
        final ms = event['ms'];
        final detail = event['detail'];
        _appendLog(
          '  [user ${event['user']}] ${event['step']} $status'
          '${ms == null ? '' : ' (${ms}ms)'}'
          '${detail == null ? '' : ' - $detail'}',
        );

      case 'user_done':
        final outcome = (event['ok'] as bool) ? 'OK' : 'FAILED';
        _appendLog(
          '[user ${event['user']}] ${event['email']} -> $outcome '
          '(${event['total_ms']}ms)',
        );

      case 'progress':
        setState(() {
          _completed = event['completed'] as int;
          _total = event['total'] as int;
          _ok = event['ok'] as int;
          _failed = event['failed'] as int;
        });

      case 'summary':
        setState(() {
          _summary = event;
        });
        _appendLog('Run complete.');

      case 'error':
        _appendLog('ERROR: ${event['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Testing'),
      ),
      body: kIsWeb
          // Spawning the Python script needs dart:io, which is unavailable on
          // web, so the launcher is disabled there.
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'The load tester launches a local Python script and is only '
                  'available on the desktop builds of this demonstrator. Run '
                  'the script directly from loadtest/ on web.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stress test of Pod hosting, login and read/write access at scale.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each simulated user creates an account and Pod, logs in, '
            'generates a security key, then writes and reads resources. '
            'The work is performed by loadtest/solid_load_test.py; install '
            'its requirements first (see loadtest/README.md).',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Test parameters, laid out as a wrapping grid of small fields.

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field(_serverCtrl, 'Server URL', width: 320),
              _field(_usersCtrl, 'Users', width: 110, number: true),
              _field(_concurrencyCtrl, 'Concurrency', width: 130, number: true),
              _field(_resourcesCtrl, 'Resources/user',
                  width: 140, number: true),
              _field(_prefixCtrl, 'Account prefix', width: 160),
              _field(_domainCtrl, 'Email domain', width: 200),
              _field(_passwordCtrl, 'Password', width: 200),
            ],
          ),
          const SizedBox(height: 12),

          // Advanced toggles.

          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _toggle(
                'Also change password',
                _changePassword,
                (v) => setState(() => _changePassword = v),
              ),
              _toggle(
                'Encrypt resources',
                _encrypt,
                (v) => setState(() => _encrypt = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Runner configuration (interpreter + script path).

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field(_pythonCtrl, 'Python executable', width: 220),
              _field(_scriptCtrl, 'Script path', width: 360),
            ],
          ),
          const SizedBox(height: 16),

          // Run / stop controls.

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _running ? null : _startRun,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Load Test'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _running ? _stopRun : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
              const SizedBox(width: 16),
              if (_running)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),

          _buildProgress(context),
          const SizedBox(height: 12),

          if (_summary != null) ...[
            _buildSummary(context),
            const SizedBox(height: 12),
          ],

          _buildLog(context),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final fraction = _total == 0 ? 0.0 : _completed / _total;

    // Before a run has started the bar is an inert grey track at zero rather
    // than the animated indeterminate state, so it reads as disabled.

    final idle = !_running && _completed == 0 && _summary == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: fraction,
          color: idle ? Theme.of(context).disabledColor : null,
        ),
        const SizedBox(height: 6),
        Text(
          'Completed $_completed of $_total  '
          '(ok $_ok, failed $_failed)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final s = _summary!;
    final steps = (s['steps'] as Map<String, dynamic>?) ?? {};

    // One row per lifecycle step with its mean/p95/max and failure count.

    final rows = <DataRow>[];
    steps.forEach((step, value) {
      final st = value as Map<String, dynamic>;
      if ((st['count'] as int) == 0 && (st['failures'] as int) == 0) return;
      rows.add(DataRow(cells: [
        DataCell(Text(step)),
        DataCell(Text('${st['mean']}')),
        DataCell(Text('${st['p95']}')),
        DataCell(Text('${st['max']}')),
        DataCell(Text('${st['failures']}')),
      ]));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Users: ${s['users_ok']} ok / ${s['users_failed']} failed '
                'of ${s['users']}'),
            Text('Resources written: ${s['resources_written']}, '
                'read back: ${s['resources_read']}'),
            Text('Wall-clock time: ${s['wall_ms']} ms'),
            const SizedBox(height: 8),
            const Text(
              'Per-step timing (ms)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Step')),
                  DataColumn(label: Text('Mean')),
                  DataColumn(label: Text('p95')),
                  DataColumn(label: Text('Max')),
                  DataColumn(label: Text('Fail')),
                ],
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLog(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live log',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 240,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Scrollbar(
            controller: _logScrollCtrl,
            child: ListView.builder(
              controller: _logScrollCtrl,
              itemCount: _log.length,
              itemBuilder: (context, i) => Text(
                _log[i],
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // A labelled text field of a fixed width for the parameter grid.

  Widget _field(
    TextEditingController controller,
    String label, {
    required double width,
    bool number = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: !_running,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: _running ? null : (v) => onChanged(v ?? false),
        ),
        Text(label),
      ],
    );
  }
}
