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

  final rsaInfo = authData!['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'].toString();

  // Check if the file already exists

  final fileUrl = webId!.contains(profCard)
      ? webId.replaceAll(profCard, '$folderPath/$fileName')
      : '$webId$folderPath/$fileName';
  final fileExists = await checkResourceExists(fileUrl, accessToken,
      genDpopToken(fileUrl, rsaKeyPair, publicKeyJwk, 'GET'), true);

// Get the file with verification key
  final encKeyMap = await loadPrvTTL('$encDir/$encKeyFile');
  final encKeyFileUrl = await createFileUrl('$encDir/$encKeyFile');
  assert(encKeyMap != null);

  // Verify the provided password
  assert(verifyEncPasswd(
      plainTxtPasswd, encKeyMap![encKeyFileUrl][encKeyPred] as String));

  // Derive the master key from password
  final masterKey = genEncMasterKey(plainTxtPasswd);

  // Get the file with individual keys
  final indKeyMap = await loadPrvTTL('$encDir/$indKeyFile');
  // final indKeyFileUrl = await createFileUrl('$encDir/$indKeyFile');
  // assert(indKeyMap!.containsKey(indKeyFileUrl));

  var indKey;
  var indIv;

  if (fileExists == 'exist') {
    // Delete the existing file or Append?
    assert(indKeyMap!.containsKey(fileName));
    indKey = indKeyMap![fileName][sessionKeyPred];
    indIv = indKeyMap[fileName][ivPred];
    try {
      await deleteItem(true, '$folderPath/$fileName');
    } on Exception catch (e) {
      print('Exception: $e');
    }

    // Decrypt the encrypted file using its individual/session key

    // Update the file content
    // Encrypt the data
    // update data file with new data
    String query = '';
    try {
      if (await updateFileByQuery(
              fileUrl,
              accessToken,
              genDpopToken(fileUrl, rsaKeyPair, publicKeyJwk, 'PATCH'),
              query) !=
          'ok') {
        throw Exception('ERR: Update file failed');
      }
    } on Exception catch (e) {
      print('Exception: $e');
    }
  } else if (fileExists == 'not-exist') {
    // If the file does not exist
    try {
      // Generate individual/session key
      final indKey = getIndividualKey();

      // Encrypt data using the individual/session key
      final encContent = encryptData(fileContent, indKey);

      // Encrypt the individual/session key using the master key
      final encIndKey = encryptData(indKey.base64, getKeyfromUtf8(masterKey));

      // Add encrypted individual/session key to the ind-key file

      // Update the ind-key file on server (similar to updateIndKeyFile)

      // Create file with encrypted data on server

      final encData = '';
      if (await createItem(true, fileName, encData, webId, authData,
              fileLoc: folderPath, fileType: fileType, aclFlag: aclFlag) !=
          'ok') {
        throw Exception('ERR: Create file failed');
      }
    } on Exception catch (e) {
      print('Exception $e');
    }
  } else {
    print('ERR: Unable to determine if file exists');
  }
}
