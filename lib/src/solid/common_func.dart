/// Common functions for package users.
///
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
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart' show appsTerms;
import 'package:solidui/src/utils/solid_alert.dart';
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/init_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart' show parseTTLMap;

/// Check if the user's POD structure is initialised.

Future<(bool, Map<String, dynamic>)> checkPodInitialization() async {
  final defaultFolders = await generateDefaultFolders();
  final defaultFiles = await generateDefaultFiles();

  final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;
  final missingResources = resCheckList.last as Map<String, dynamic>;

  return (allExists, missingResources);
}

/// Delete a data file (and its ACL file if exist), remove its individual key
/// and the corresponding IV from the ind-key-file.

Future<void> deleteDataFileDialog(
  String fileName,
  BuildContext context, {
  ResourceContentType contentType = ResourceContentType.turtleText,
}) async {
  if (!await isUserLoggedIn()) {
    throw NotLoggedInException(
      'User must be logged in to delete files. '
      'Please authenticate before calling this function.',
    );
  }

  const smallGapH = SizedBox(width: 10);
  String msg;

  final filePath = [await getDataDirPath(), fileName].join('/');
  final fileUrl = await getFileUrl(filePath);
  final status = await checkResourceStatus(fileUrl);

  switch (status) {
    case ResourceStatus.exist:
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notice'),
            content: Text('Delete data file "$fileName"?'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await deleteFile(fileUrl: fileUrl, contentType: contentType);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully deleted data file "$fileName".',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              smallGapH,
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
      return;

    case ResourceStatus.forbidden:
      msg = 'Access to data file "$fileName" is forbidden.';

    case ResourceStatus.notExist:
      msg = 'Data file "$fileName" does not exist.';

    case ResourceStatus.unknown:
      msg = 'Error occurred when checking the status of data file "$fileName".';
  }

  if (context.mounted) await alert(context, msg);
}

/// Get inherited resource parent directory url
String getParentDir(String fileContent, String fileUrl) {
  final dataMap = parseTTLMap(fileContent);
  return dataMap[fileUrl]['$appsTerms$inheritKeyPred'].first;
}
