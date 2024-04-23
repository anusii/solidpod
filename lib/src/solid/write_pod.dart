import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';

//import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils.dart';
import 'package:solidpod/src/solid/constants.dart';
//import 'package:solidpod/src/solid/popup_login.dart';
import 'package:solidpod/src/solid/common_func.dart';

/// Write file with path [filePath] and content [fileContent] to a POD

Future<void> writePod(String filePath, String fileContent, BuildContext context,
    Widget child) async {
  await loginIfRequired(context);
  // TODO: put this block into a separate function: loginIfRequired?
  // final loggedIn = await checkLoggedIn();
  // if (!loggedIn) {
  //   await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => const SolidPopupLogin(),
  //       ));
  // }

  await initPodIfRequired(context, child);
  //TODO: extract this initial structure test code to a separate function: initPodIfRequired?
  // final defaultFolders = await generateDefaultFolders();
  // final defaultFiles = await generateDefaultFiles();

  // final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  // final allExists = resCheckList.first as bool;

  // if (!allExists) {
  //   await Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //         builder: (context) => InitialSetupScreen(
  //               resCheckList: resCheckList,
  //               child: child,
  //             )),
  //   );
  // }

  // Get master key for encryption
  // TODO: move this to a middle level function askMasterPasswdIfRequired?
  // which should require user input if master password is not stored
  // in local secure storage or cannot be verified.

  await askMasterPasswordIfRequired(context);
  final masterPasswd = await loadMasterPassword();
  assert(masterPasswd != null);
  // final verified = verifyMasterPasswd(masterPasswd!);
  // assert(verified);

  final masterKey = genMasterKey(masterPasswd!);

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

    // TODO: move this to a separate function getIndKeyOfFile?
    // Get the ind-key file (TTL file with encrypted individual keys and IVs)

    final indKeyPath = await getIndKeyPath();
    final indKeyMap = await loadPrvTTL(indKeyPath);
    assert(indKeyMap!.containsKey(fileUrl));

    // Get (and decrypt) the individual key from ind-key file

    final indKeyIV = IV.fromBase64(indKeyMap![fileUrl][ivPred] as String);
    final encIndKeyStr = indKeyMap[fileUrl][sessionKeyPred] as String;
    indKey = Key.fromBase64(decryptData(encIndKeyStr, masterKey, indKeyIV));
  } else if (fileExists == ResourceStatus.notExist) {
    // Generate individual/session key and its IV

    indKey = getIndividualKey();
    final indKeyIV = getIV();

    // Encrypt individual Key
    final encIndKeyStr = encryptData(indKey.base64, masterKey, indKeyIV);

    // Add the individual key and its IV to the ind-key file
    await addIndKey(filePath, encIndKeyStr, indKeyIV);
  } else {
    print('Exception: Unable to determine if file "$filePath" exists');
  }

  // Create file with encrypted data on server

  final encData = await getEncTTLStr(filePath, fileContent, indKey, getIV());
  await createTTL(filePath, encData);
}
