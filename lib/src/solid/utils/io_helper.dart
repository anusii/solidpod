/// Helper functions for reading and writing files in PODs.
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
/// Authors: Dawei Chen

library;

import 'package:solidpod/src/solid/utils/init_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

final _protectedFiles = <String>{};

Future<bool> isFileProtected(String fileUrl) async {
  final filePath = await extractResourcePathFromUrl(fileUrl);
  if (_protectedFiles.isEmpty) {
    // TODO: dc 20260105 - double check if these are all the protected files

    final files = [
      await getEncKeyPath(),
      await getIndKeyPath(),
      await getPubKeyPath(),
      await getPubIndKeyPath(),
      await getAuthUserIndKeyPath(),
      await getSharedKeyFilePath(),
      await getPermLogFilePath(),
    ];

    _protectedFiles.addAll(files);
    _protectedFiles.addAll(files.map((f) => '$f.acl'));
    _protectedFiles.addAll([
      for (final d in await generateDefaultFolders()) '$d/.acl',
    ]);
  }

  print(_protectedFiles);

  return _protectedFiles.contains(filePath);
}
