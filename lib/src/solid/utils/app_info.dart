/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Dawei Chen

library;

import 'package:package_info_plus/package_info_plus.dart';

/// [AppInfo] is class that stores the information of a particular app
/// (i.e. the app that invokes methods of this class), including:
/// name, version, canonical name, package name, build number.

class AppInfo {
  /// Instance caching results of async call: `await PackageInfo.fromPlatform()`
  static PackageInfo? _info;

  /// Get the app name from pubspec.yml
  static Future<String> get name async {
    _info ??= await PackageInfo.fromPlatform();
    return _info!.appName;
  }

  /// Get the version
  static Future<String> get version async {
    _info ??= await PackageInfo.fromPlatform();
    print("version: ${_info!.version}");
    return _info!.version;
  }

  /// Get the app name from pubspec.yml and
  /// 1. Remove any leading and trailing whitespace
  /// 2. Convert to lower case
  /// 3. Replace (one or multiple) white spaces with an underscore
  static Future<String> get canonicalName async {
    _info ??= await PackageInfo.fromPlatform();
    return _info!.appName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get the name of the package that provides the app
  static Future<String> get packageName async {
    _info ??= await PackageInfo.fromPlatform();
    return _info!.packageName;
  }

  /// Get the build number
  static Future<String> get buildNumber async {
    _info ??= await PackageInfo.fromPlatform();
    return _info!.buildNumber;
  }
}
