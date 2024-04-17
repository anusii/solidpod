import 'dart:core';

import 'package:encrypt/encrypt.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:solidpod/src/solid/utils.dart';
import 'package:solidpod/src/solid/constants.dart';

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

Future<void> writePod(
  String plainTxtPasswd,
  String fileName,
  String folderPath,
  String fileType,
  String fileContent,
  bool aclFlag,
) async {
  final webId = await getWebId();
  assert(webId != null);
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  // Check if the file already exists

  final fileUrl = await createFileUrl('$folderPath/$fileName');
  final fileExists = await checkResourceExists(fileUrl, true);

// Get the file with verification key
  final encKeyMap = await loadPrvTTL('$encDir/$encKeyFile');
  final encKeyFileUrl = await createFileUrl('$encDir/$encKeyFile');
  assert(encKeyMap != null);

  // Verify the provided password
  assert(verifyEncPasswd(
      plainTxtPasswd, encKeyMap![encKeyFileUrl][encKeyPred] as String));

  // Derive the master key from password
  final masterKey = genEncMasterKey(plainTxtPasswd);

  late final String encData;
  late final IV dataIV;

  if (fileExists == ResourceStatus.exist) {
    // Delete the existing file or Append?

    try {
      await deleteItem(true, '$folderPath/$fileName');
    } catch (e) {
      print('Exception: $e');
    }

    // Get the file with individual keys
    final indKeyMap = await loadPrvTTL('$encDir/$indKeyFile');
    // final indKeyFileUrl = await createFileUrl('$encDir/$indKeyFile');
    // assert(indKeyMap!.containsKey(indKeyFileUrl));

    assert(indKeyMap!.containsKey(fileName));
    final encIndKey = indKeyMap![fileName][sessionKeyPred] as String;
    final indKeyIV = indKeyMap[fileName][ivPred] as String;

    // Decrypt the individual key
    final indKey = Key.fromBase64(
        decryptData(encIndKey, masterKey, IV.fromBase64(indKeyIV)));

    // Encrypt data
    dataIV = getIV();
    encData = encryptData(fileContent, indKey, dataIV);
  } else if (fileExists == ResourceStatus.notExist) {
    // Generate individual/session key
    final indKey = getIndividualKey();
    final indKeyIV = getIV();
    dataIV = getIV();
    encData = encryptData(fileContent, indKey, dataIV);

    // Encrypt individual Key
    final encIndKey = encryptData(indKey.base64, masterKey, indKeyIV);

    // Update the ind-key file on server
  } else {
    //throw Exception('Unable to determine if file exists');
    print('ERR');
  }

  // generate TTL with dataIV and encData
  final ttlContent = '';

  // Create file with encrypted data on server
  createTTL(fileName, folderPath, ttlContent);
}
