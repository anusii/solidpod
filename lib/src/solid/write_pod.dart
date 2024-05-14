/// Function to write data to a private file in PODs.
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
/// Authors: Dawei Chen

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Write file [fileName] and content [fileContent] to PODs

Future<void> writePod(String fileName, String fileContent, BuildContext context,
    Widget child) async {
  // Write data to file in the data directory
  final filePath = path.join(await getDataDirPath(), fileName);

  await loginIfRequired(context);

  await getKeyFromUserIfRequired(context, child);

  // Get master key for encryption

  // final securityKey = await getVerifiedSecurityKey(context, child);
  // final masterKey = genMasterKey(securityKey);

  // Check if the file already exists

  final fileUrl = await getFileUrl(filePath);
  final fileExists = await checkResourceStatus(fileUrl, true);

  // Reuse the individual key if the file already exists
  late final Key indKey;
  late final bool replace;

  if (fileExists == ResourceStatus.exist) {
    replace = true;
    // Delete the existing file

    // try {
    //   await deleteItem(true, filePath);
    // } on Exception catch (e) {
    //   print('Exception: $e');
    // }

    // Get (and decrypt) the individual key from ind-key file
    // (the TTL file with encrypted individual keys and IVs)

    // final indKeyPath = await getIndKeyPath();
    // final indKeyUrl = await getFileUrl(indKeyPath);
    // final indKeyMap = await loadPrvTTL(indKeyUrl);
    // assert(indKeyMap.containsKey(fileUrl));

    // final indKeyIV = IV.fromBase64(indKeyMap![fileUrl][ivPred] as String);
    // final encIndKeyStr = indKeyMap[fileUrl][sessionKeyPred] as String;

    // indKey = Key.fromBase64(decryptData(encIndKeyStr, masterKey, indKeyIV));
    indKey = await KeyManager.getIndividualKey(fileUrl);
  } else if (fileExists == ResourceStatus.notExist) {
    replace = false;
    // Generate individual/session key and its IV

    indKey = genRandIndividualKey();
    final indKeyIV = genRandIV();
    final masterKey = await KeyManager.getMasterKey();

    // Encrypt individual Key
    final encIndKeyStr = encryptData(indKey.base64, masterKey, indKeyIV);

    // Add the encrypted individual key and its IV to the ind-key file
    await addIndKey(filePath, encIndKeyStr, indKeyIV);
  } else {
    print('Exception: Unable to determine if file "$filePath" exists');
  }

  // Create file with encrypted data on server

  await createResource(fileUrl,
      content: await getEncTTLStr(filePath, fileContent, indKey, genRandIV()),
      replaceIfExist: replace);
}
