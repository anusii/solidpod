/// Function to grant permission to a private file in a POD.
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
/// Authors: Anushka Vidanage

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Grant permission to [fileName] for a given [recipientWebId].
/// Parameters:
///   [fileName] is the name of the file providing permission to
///   [permissionList] is the list of permission to be granted
///   [recipientWebId] is the webId of the permission receiver
///   [isFileEncrypted] is the flag to determine if the file is encrypted or not

Future<void> grantPermission(
    String fileName,
    List<dynamic> permissionList,
    String recipientWebId,
    bool isFileEncrypted,
    BuildContext context,
    Widget child) async {
  await loginIfRequired(context);

  await getKeyFromUserIfRequired(context, child);

  // Get the file path
  final filePath = [await getDataDirPath(), fileName].join('/');

  // Get the url of the file
  final resourceUrl = await getFileUrl(filePath);

  // Add the permission line to the relevant ACL file
  await setPermissionAcl(resourceUrl, recipientWebId, permissionList);

  // Check if the file is encrypted
  final fileIsEncrypted = await checkFileEnc(resourceUrl);

  // If the file is encrypted then share the individual encryption key
  // with the receiver
  if (fileIsEncrypted) {
    // Get the individual security key for the file
    final indKey = await KeyManager.getIndividualKey(resourceUrl);

    // Setup recipient's public key
    final recipientPubKey = RecipientPubKey(recipientWebId: recipientWebId);

    // Encrypt individual key
    final sharedIndKey = await recipientPubKey.encryptData(indKey.base64);

    // Encrypt resource URL
    final sharedResPath = await recipientPubKey.encryptData(resourceUrl);

    // Encrypt the list of permissions
    permissionList.sort();
    final sharedAccessList =
        await recipientPubKey.encryptData(permissionList.join(','));

    // Copy shared content to recipient's POD
    final senderUniqueName = getUniqueStrWebId(await getWebId() as String);
    final resourceName = resourceUrl.split('/').last;
    await copySharedKey(recipientWebId, senderUniqueName, resourceName,
        sharedIndKey, sharedResPath, sharedAccessList);
  }
}