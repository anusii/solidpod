import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;

import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/popup_login.dart';
import 'package:solidpod/src/solid/utils.dart';

/// Write file content to a POD
/// (1-3 shoudl be in keypod)
/// 1. check if a user is logged in
/// 2. load user password (master key) from local storage or ask user
/// 3. validate user password (master key)
/// 4. if file does not exist:
///    - generate individual key and encrypt data
///    - update file with all individual keys (updateFileByQuery)
///    - create file with encrypted data (createItem)
/// 5. if file exists:
///    - load individual key from server and encrypt data
///    - update file with encrypted data if it exists (updateFileByQuery)

Future<void> writePod(String filePath, String fileContent, BuildContext context,
    Widget child) async {
  // TODO: put this block into a separate function: loginIfApplicable?
  final loggedIn = await checkLoggedIn();
  if (!loggedIn) {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SolidPopupLogin(),
        ));
  }

  final fileName = path.basename(filePath);

  //TODO: extract this initial structure test code to a separate function
  final defaultFolders = await generateDefaultFolders();
  final defaultFiles = await generateDefaultFiles();

  final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists) {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => InitialSetupScreen(
                resCheckList: resCheckList,
                child: child,
              )),
    );
  }

  // Get master password for encryption
  // TODO: Request master password from user if not found in secure storage
  final masterPasswd = await loadMasterPassword();
  assert(masterPasswd != null);

  final webId = await getWebId();
  assert(webId != null);
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  // Get the file with verification key
  final encKeyPath = await getEncKeyPath();
  final encKeyMap = await loadPrvTTL(encKeyPath);
  final encKeyFileUrl = await getResourceUrl(encKeyPath);
  assert(encKeyMap != null);

  // Verify the provided password
  assert(verifyEncPasswd(
      masterPasswd!, encKeyMap![encKeyFileUrl][encKeyPred] as String));

  // Derive the master key from password
  final masterKey = genEncMasterKey(masterPasswd!);

  // Check if the file already exists

  final fileUrl = await getResourceUrl(filePath);
  final fileExists = await checkResourceExists(fileUrl, true);

  //late final String encData;
  late final Key indKey;
  late final IV dataIV;

  if (fileExists == ResourceStatus.exist) {
    // Delete the existing file or Append?

    try {
      await deleteItem(true, filePath);
    } on Exception catch (e) {
      print('Exception: $e');
    }

    // Get the TTL file with individual keys
    final indKeyPath = await getIndKeyPath();
    final indKeyMap = await loadPrvTTL(indKeyPath);
    assert(indKeyMap!.containsKey(fileName));

    final encIndKeyStr = indKeyMap![fileName][sessionKeyPred] as String;
    final indKeyIVStr = indKeyMap[fileName][ivPred] as String;

    // Decrypt the individual key
    final indKeyStr =
        decryptData(encIndKeyStr, masterKey, IV.fromBase64(indKeyIVStr));
    indKey = Key.fromBase64(indKeyStr);

    // Encrypt data
    dataIV = getIV();
    //encData = encryptData(fileContent, Key.fromBase64(indKeyStr), dataIV);
  } else if (fileExists == ResourceStatus.notExist) {
    // Generate individual/session key
    final indKey = getIndividualKey();
    final indKeyIV = getIV();
    dataIV = getIV();
    //encData = encryptData(fileContent, indKey, dataIV);

    // Encrypt individual Key
    final encIndKey = encryptData(indKey.base64, masterKey, indKeyIV);

    // Update the ind-key file on server
  } else {
    //throw Exception('Unable to determine if file exists');
    print('ERR');
  }

  // Create file with encrypted data on server
  await createTTL(
      filePath, getEncTTLStr(filePath, fileContent, indKey, dataIV));
}
