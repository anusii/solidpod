import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/utils.dart';

/// Write file with path [filePath] and content [fileContent] to a POD

Future<void> writePod(String filePath, String fileContent, BuildContext context,
    Widget child) async {
  // Login and initialise PODs if necessary

  await loginIfRequired(context);
  await initPodsIfRequired(context, child);

  // Get master key for encryption

  final masterPasswd = await getVerifiedMasterPassword(context, child);
  final masterKey = genMasterKey(masterPasswd);

  // Check if the file already exists

  final fileUrl = await getResourceUrl(filePath);
  final fileExists = await checkResourceExists(fileUrl, true);

  // Reuse the individual key if the file already exists
  late final Key indKey;

  if (fileExists == ResourceStatus.exist) {
    // Delete the existing file

    try {
      await deleteItem(true, filePath);
    } on Exception catch (e) {
      print('Exception: $e');
    }

    // Get (and decrypt) the individual key from ind-key file
    // (the TTL file with encrypted individual keys and IVs)

    final indKeyPath = await getIndKeyPath();
    final indKeyMap = await loadPrvTTL(indKeyPath);
    assert(indKeyMap!.containsKey(fileUrl));

    final indKeyIV = IV.fromBase64(indKeyMap![fileUrl][ivPred] as String);
    final encIndKeyStr = indKeyMap[fileUrl][sessionKeyPred] as String;

    indKey = Key.fromBase64(decryptData(encIndKeyStr, masterKey, indKeyIV));
  } else if (fileExists == ResourceStatus.notExist) {
    // Generate individual/session key and its IV

    indKey = getIndividualKey();
    final indKeyIV = getIV();

    // Encrypt individual Key
    final encIndKeyStr = encryptData(indKey.base64, masterKey, indKeyIV);

    // Add the encrypted individual key and its IV to the ind-key file
    await addIndKey(filePath, encIndKeyStr, indKeyIV);
  } else {
    print('Exception: Unable to determine if file "$filePath" exists');
  }

  // Create file with encrypted data on server

  await createTTL(
      filePath, await getEncTTLStr(filePath, fileContent, indKey, getIV()));
}
