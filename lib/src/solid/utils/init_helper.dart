/// Utility functions for generating folders and files at the initilisation stage.
///
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
/// Authors: Anushka Vidanage, Dawei Chen

library;

import 'package:solidpod/src/solid/constants/common.dart';

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<List<String>> generateDefaultFolders() async {
  final dataDirLoc = [appDirName, dataDir].join('/');
  final sharingDirLoc = [appDirName, sharingDir].join('/');
  final sharedDirLoc = [appDirName, sharedDir].join('/');
  final encDirLoc = [appDirName, encDir].join('/');
  final logDirLoc = [appDirName, logsDir].join('/');

  final folders = [
    appDirName,
    sharingDirLoc,
    sharedDirLoc,
    dataDirLoc,
    encDirLoc,
    logDirLoc,
  ];
  return folders;
}

/// Generates a list of custom folder paths for a given application.
///
/// This function takes the custom folder list given by the developer and
/// creates paths for those folders. Each custom folder will be created
/// inside the "data" folder. Following are few examples.
///   - Custom folder 'myDir1' will be created as '/data/myDir1'
///   - Custom folder 'myDir1/myDir3' will be created as '/data/myDir1/myDir3'
///   - Custom folder 'data' will be created as '/data/data'

List<String> generateCustomFolders(List customFolderPaths) {
  List<String> customFolderList = [];
  if (customFolderPaths.isNotEmpty) {
    for (String folderPath in customFolderPaths) {
      // Remove any leading '/' characters
      folderPath = folderPath.replaceFirst(RegExp(r'^/+'), '');
      customFolderList.add([appDirName, dataDir, folderPath].join('/'));
    }
  }
  return customFolderList;
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<Map<dynamic, dynamic>> generateDefaultFiles() async {
  final sharingDirLoc = [appDirName, sharingDir].join('/');
  final sharedDirLoc = [appDirName, sharedDir].join('/');
  final encDirLoc = [appDirName, encDir].join('/');
  final logDirLoc = [appDirName, logsDir].join('/');

  final files = {
    sharingDirLoc: [pubKeyFile, '$pubKeyFile.acl'],
    logDirLoc: [permLogFile, '$permLogFile.acl'],
    sharedDirLoc: ['.acl'],
    encDirLoc: [encKeyFile, indKeyFile],
  };
  return files;
}
