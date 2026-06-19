/// solidpod:create - scaffold a new Solid Pod file-browser app.
///
/// This generator stamps out a ready-to-run Flutter application from the
/// `solidpod` app template (a Pod file browser, with navigation rail and status
/// bar, built on `solidui`). It is the practical equivalent of a
/// `flutter create --template=solidpod`, which stock Flutter does not support
/// because the `--template` flag only accepts a fixed set of built-in types.
///
/// Usage:
///
///   dart run solidpod:create APP_NAME [options]
///
/// Run with `--help` for the full list of options.
///
/// This script deliberately imports only `dart:` libraries so it stays a pure
/// Dart executable that can also be globally activated with
/// `flutter pub global activate`.

library;

import 'dart:io';
import 'dart:isolate';

// File extensions copied verbatim (never treated as text for token
// substitution).

const _binaryExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.ico',
  '.webp',
};

// Operating-system and editor cruft that must never be copied into a generated
// project (and would otherwise break the text decoder).

const _junkFiles = {
  '.DS_Store',
  'Thumbs.db',
};

// Dart reserved words that cannot be used as a package name.

const _reservedWords = {
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'library', 'mixin',
  'new', 'null', 'on', 'operator', 'part', 'rethrow', 'return', 'set', 'show',
  'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try',
  'typedef', 'var', 'void', 'while', 'with', 'yield',
  // Names that would clash with the Flutter toolchain.
  'flutter', 'test',
};

Future<void> main(List<String> arguments) async {
  final args = _Args.parse(arguments);

  if (args.help) {
    _printUsage(stdout);
    return;
  }

  final projectName = args.projectName;
  if (projectName == null) {
    stderr.writeln('Error: missing <app_name>.\n');
    _printUsage(stderr);
    exitCode = 64; // EX_USAGE
    return;
  }

  final nameError = _validateProjectName(projectName);
  if (nameError != null) {
    stderr.writeln('Error: $nameError');
    exitCode = 64;
    return;
  }

  // Derive the human-facing names from the package name unless overridden.

  final appName = _pascalCase(projectName);
  final appTitle = args.title ?? '$appName - File Browser for Solid Pods';
  final appDescription = args.description ??
      '$appName - manage files on your personal online data store (POD).';
  final orgName = args.org;

  // The project name is used as-is almost everywhere (package name, imports,
  // applicationId, POD folder, and the clientId / redirect URL paths, which all
  // permit underscores). The ONE exception is the custom redirect URI scheme: a
  // URI scheme may not contain underscores (RFC 3986 allows only letters,
  // digits and "+", "-", "."), and an Android intent-filter scheme must be
  // lower case. So we derive a scheme name with the underscores stripped, and
  // use it only inside the `org.scheme://` redirect.

  final schemeName = projectName.replaceAll('_', '');
  final outputDir = Directory(args.output ?? projectName);

  final templateDir = await _resolveTemplateDir();
  if (templateDir == null || !templateDir.existsSync()) {
    stderr.writeln(
      'Error: could not locate the solidpod template directory.\n'
      'Expected it alongside the solidpod package (templates/solidpod/).',
    );
    exitCode = 70; // EX_SOFTWARE
    return;
  }

  final tokens = <String, String>{
    '{{projectName}}': projectName,
    '{{appName}}': appName,
    '{{appTitle}}': appTitle,
    '{{appDescription}}': appDescription,
    '{{orgName}}': orgName,
    '{{schemeName}}': schemeName,
  };

  stdout.writeln('Creating Solid Pod app "$appName" in ${outputDir.path}/ ...');

  // Step 1: let `flutter create` lay down the platform folders and tooling
  // (android/, ios/, etc.) unless the caller opted out. We pass the project
  // name and org so the generated metadata matches our overlaid pubspec.

  if (args.runFlutterCreate) {
    final created = await _runFlutterCreate(
      projectName: projectName,
      org: orgName,
      output: outputDir,
    );
    if (!created) {
      exitCode = 70;
      return;
    }
  } else {
    outputDir.createSync(recursive: true);
  }

  // Step 2: overlay the template, substituting tokens as we go. This overwrites
  // the default main.dart and pubspec.yaml that flutter create produced.

  stdout.writeln('Applying the solidpod template ...');
  _renderTemplate(
    source: templateDir,
    target: outputDir,
    tokens: tokens,
  );

  // Step 3: drop the default counter widget test, which references the
  // scaffolding flutter create generated rather than our app.

  final defaultTest = File('${outputDir.path}/test/widget_test.dart');
  if (defaultTest.existsSync()) {
    defaultTest.deleteSync();
  }

  // Step 4: wire up the OIDC redirect on the platforms that flutter create does
  // not configure (Android manifest placeholder and the iOS URL scheme). The
  // macOS entitlements are supplied by the template overlay above.

  if (args.runFlutterCreate) {
    _patchAuthRedirect(outputDir, scheme: '$orgName.$schemeName');
  }

  // Step 5: resolve dependencies now that the pubspec lists solidui.

  if (args.runPubGet && args.runFlutterCreate) {
    stdout.writeln('Running flutter pub get ...');
    await _runProcess('flutter', ['pub', 'get'], outputDir.path);
  }

  _printNextSteps(stdout, outputDir.path, runFlutterCreate: args.runFlutterCreate);
}

// ── Template rendering ─────────────────────────────────────────────────────

void _renderTemplate({
  required Directory source,
  required Directory target,
  required Map<String, String> tokens,
}) {
  final sourcePath = source.path;
  for (final entity in source.listSync(recursive: true)) {
    if (entity is! File) continue;

    final name = entity.uri.pathSegments.last;

    // Skip operating-system and editor junk that may sit alongside the template
    // (e.g. macOS .DS_Store), so it never lands in the generated project nor
    // trips up the text decoder below.

    if (_junkFiles.contains(name)) continue;

    // Path of the file relative to the template root.

    var relative = entity.path.substring(sourcePath.length);
    relative = relative.replaceFirst(RegExp(r'^[\\/]+'), '');

    // Strip the .tmpl marker and substitute any tokens that appear in the path
    // itself (so template authors can parameterise file names too).

    if (relative.endsWith('.tmpl')) {
      relative = relative.substring(0, relative.length - '.tmpl'.length);
    }
    relative = _substitute(relative, tokens);

    final destination = File('${target.path}/$relative');
    destination.parent.createSync(recursive: true);

    // Known-binary files are copied verbatim. Anything else we attempt to read
    // as text for token substitution, falling back to a byte copy if it turns
    // out not to be valid UTF-8 (so an unexpected binary never crashes us).

    if (_isBinary(relative)) {
      destination.writeAsBytesSync(entity.readAsBytesSync());
      continue;
    }
    try {
      final rendered = _substitute(entity.readAsStringSync(), tokens);
      destination.writeAsStringSync(rendered);
    } on FileSystemException {
      destination.writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

String _substitute(String input, Map<String, String> tokens) {
  var output = input;
  tokens.forEach((token, value) {
    output = output.replaceAll(token, value);
  });
  return output;
}

bool _isBinary(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return false;
  return _binaryExtensions.contains(path.substring(dot).toLowerCase());
}

// ── OIDC redirect wiring ───────────────────────────────────────────────────

// flutter create does not register the custom redirect scheme that the OIDC
// login needs. We add the Android manifest placeholder and the iOS URL scheme
// here; the macOS network-client/keychain entitlements come from the template.

void _patchAuthRedirect(Directory output, {required String scheme}) {
  _patchAndroidRedirectScheme(output, scheme);
  _patchIosUrlScheme(output, scheme);
}

void _patchAndroidRedirectScheme(Directory output, String scheme) {
  // flutter_appauth reads `appAuthRedirectScheme` from the manifest placeholders
  // declared in the app-level Gradle file (Kotlin or Groovy DSL).

  final placeholder = 'appAuthRedirectScheme';

  final kts = File('${output.path}/android/app/build.gradle.kts');
  if (kts.existsSync()) {
    final content = kts.readAsStringSync();
    if (content.contains(placeholder)) return;
    final patched = content.replaceFirstMapped(
      RegExp(r'versionName = flutter\.versionName\n'),
      (m) => '${m[0]}        manifestPlaceholders.putAll(mapOf(\n'
          '            "$placeholder" to "$scheme",\n'
          '        ))\n',
    );
    if (patched != content) {
      kts.writeAsStringSync(patched);
    } else {
      stderr.writeln(
        'Warning: could not add $placeholder to build.gradle.kts; add '
        'manifestPlaceholders["$placeholder"] = "$scheme" to defaultConfig '
        'manually.',
      );
    }
    return;
  }

  final groovy = File('${output.path}/android/app/build.gradle');
  if (groovy.existsSync()) {
    final content = groovy.readAsStringSync();
    if (content.contains(placeholder)) return;
    final patched = content.replaceFirstMapped(
      RegExp(r'versionName flutterVersionName\n'),
      (m) => '${m[0]}        manifestPlaceholders = [$placeholder: "$scheme"]\n',
    );
    if (patched != content) {
      groovy.writeAsStringSync(patched);
    } else {
      stderr.writeln(
        'Warning: could not add $placeholder to build.gradle; add '
        'manifestPlaceholders = [$placeholder: "$scheme"] to defaultConfig '
        'manually.',
      );
    }
  }
}

void _patchIosUrlScheme(Directory output, String scheme) {
  final plist = File('${output.path}/ios/Runner/Info.plist');
  if (!plist.existsSync()) return;

  final content = plist.readAsStringSync();
  if (content.contains('CFBundleURLTypes')) return;

  // Register the custom scheme so iOS can return to the app after login.

  final block = '''
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>$scheme</string>
			</array>
		</dict>
	</array>
''';

  final patched = content.replaceFirst(
    RegExp(r'\n</dict>\n</plist>'),
    '\n$block</dict>\n</plist>',
  );
  if (patched != content) {
    plist.writeAsStringSync(patched);
  } else {
    stderr.writeln(
      'Warning: could not add CFBundleURLTypes to ios/Runner/Info.plist; add '
      'the "$scheme" URL scheme manually.',
    );
  }
}

// ── Template location ──────────────────────────────────────────────────────

Future<Directory?> _resolveTemplateDir() async {
  // Preferred: resolve through the package config so this works whether invoked
  // as `dart run solidpod:create` or after a global activation.

  try {
    final libUri = await Isolate.resolvePackageUri(
      Uri.parse('package:solidpod/solidpod.dart'),
    );
    if (libUri != null) {
      final dir = Directory.fromUri(libUri.resolve('../templates/solidpod/'));
      if (dir.existsSync()) return dir;
    }
  } catch (_) {
    // Fall through to the script-relative lookup below.
  }

  // Fallback: relative to this script (bin/create.dart -> ../templates/...).

  try {
    final dir = Directory.fromUri(
      Platform.script.resolve('../templates/solidpod/'),
    );
    if (dir.existsSync()) return dir;
  } catch (_) {
    // Ignored - caller handles the null result.
  }

  return null;
}

// ── Process helpers ────────────────────────────────────────────────────────

Future<bool> _runFlutterCreate({
  required String projectName,
  required String org,
  required Directory output,
}) async {
  stdout.writeln('Running flutter create ...');
  return _runProcess(
    'flutter',
    [
      'create',
      '--project-name',
      projectName,
      '--org',
      org,
      '--no-pub',
      output.path,
    ],
    null,
  );
}

Future<bool> _runProcess(
  String executable,
  List<String> args,
  String? workingDirectory,
) async {
  try {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );
    final code = await process.exitCode;
    if (code != 0) {
      stderr.writeln('Error: `$executable ${args.join(' ')}` exited with $code.');
      return false;
    }
    return true;
  } on ProcessException catch (e) {
    stderr.writeln(
      'Error: could not run `$executable`. Is it installed and on your PATH?\n'
      '  ${e.message}',
    );
    return false;
  }
}

// ── Naming helpers ─────────────────────────────────────────────────────────

String? _validateProjectName(String name) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    return '"$name" is not a valid package name. Use lowercase letters, '
        'digits and underscores, starting with a letter '
        '(e.g. my_pod_app).';
  }
  if (_reservedWords.contains(name)) {
    return '"$name" is a reserved word and cannot be used as a package name.';
  }
  return null;
}

String _pascalCase(String snake) {
  return snake
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

// ── Argument parsing ───────────────────────────────────────────────────────

class _Args {
  _Args({
    required this.projectName,
    required this.org,
    required this.title,
    required this.description,
    required this.output,
    required this.runFlutterCreate,
    required this.runPubGet,
    required this.help,
  });

  final String? projectName;
  final String org;
  final String? title;
  final String? description;
  final String? output;
  final bool runFlutterCreate;
  final bool runPubGet;
  final bool help;

  static _Args parse(List<String> arguments) {
    String? projectName;
    var org = 'com.example';
    String? title;
    String? description;
    String? output;
    var runFlutterCreate = true;
    var runPubGet = true;
    var help = false;

    String valueFor(String arg, String? inlineValue, Iterator<String> it) {
      if (inlineValue != null) return inlineValue;
      if (it.moveNext()) return it.current;
      stderr.writeln('Error: option "$arg" expects a value.');
      exit(64);
    }

    final it = arguments.iterator;
    while (it.moveNext()) {
      final arg = it.current;

      // Allow an optional leading `create` verb so both `solidpod create app`
      // and `solidpod app` work after a global activation.

      if (arg == 'create' && projectName == null) continue;

      if (arg == '-h' || arg == '--help') {
        help = true;
        continue;
      }
      if (arg == '--no-flutter-create') {
        runFlutterCreate = false;
        continue;
      }
      if (arg == '--no-pub-get') {
        runPubGet = false;
        continue;
      }

      String? key = arg;
      String? inline;
      final eq = arg.indexOf('=');
      if (arg.startsWith('--') && eq != -1) {
        key = arg.substring(0, eq);
        inline = arg.substring(eq + 1);
      }

      switch (key) {
        case '--org':
          org = valueFor(arg, inline, it);
        case '--title':
          title = valueFor(arg, inline, it);
        case '--description':
          description = valueFor(arg, inline, it);
        case '--output':
        case '-o':
          output = valueFor(arg, inline, it);
        default:
          if (arg.startsWith('-')) {
            stderr.writeln('Error: unknown option "$arg".');
            exit(64);
          }
          projectName ??= arg;
      }
    }

    return _Args(
      projectName: projectName,
      org: org,
      title: title,
      description: description,
      output: output,
      runFlutterCreate: runFlutterCreate,
      runPubGet: runPubGet,
      help: help,
    );
  }
}

void _printUsage(IOSink out) {
  out.writeln('''
Scaffold a new Solid Pod file-browser app from the solidpod template.

Usage:
  dart run solidpod:create <app_name> [options]

Options:
  --org <id>            Reverse-domain organisation id (default: com.example).
  --title <text>        Window title (default: "<AppName> - File Browser for
                        Solid Pods").
  --description <text>  pubspec description.
  -o, --output <dir>    Output directory (default: <app_name>).
  --no-flutter-create   Only render the template; skip running flutter create
                        (no platform folders are generated).
  --no-pub-get          Skip the final flutter pub get.
  -h, --help            Show this help.

Example:
  dart run solidpod:create my_pod_app --org au.org.example
''');
}

void _printNextSteps(IOSink out, String path, {required bool runFlutterCreate}) {
  out.writeln('''

Done! Your Solid Pod app is ready in $path/

Next steps:
  cd $path${runFlutterCreate ? '' : '\n  flutter create --project-name <name> .   # generate platform folders\n  flutter pub get'}
  flutter run

Then update the Solid app registration (clientId, redirectUris, link) in
lib/app.dart and the constants in lib/constants/app.dart for your deployment.

On macOS/iOS, enable signing once in Xcode (Signing & Capabilities -> Team)
so the keychain-backed login can build. See the generated README for details.
''');
}
