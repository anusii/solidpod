import 'package:fast_rsa/fast_rsa.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solid_auth/solid_auth.dart';

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
  String webId,
  String encPasswd,
  String fileName,
  String fileLoc,
  String fileType,
  String fileContent,
  bool aclFlag,
  Map<dynamic, dynamic> authData,
) async {
  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'].toString();

  // Get file with all keys (key_file)

  // Check if the file already exists

  final fileUrl = webId.contains('profile/card#me')
      ? webId.replaceAll('profile/card#me', fileLoc)
      : '$webId$fileLoc';
  final fileExists = await checkResourceExists(fileUrl, accessToken,
      genDpopToken(fileUrl, rsaKeyPair, publicKeyJwk, 'GET'), true);

  if (fileExists == 'exist') {
    // If the file exists
    // get the encrypted session key
    // decrypt the encrypted session key
    // encrypt the data
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
      // generate session key
      // encrypt data
      // encrypt session key
      // add encrypted session key to key_file
      // update key_file (similar to updateIndKeyFile)
      // create file with encrypted data
      final encData = '';
      if (await createItem(true, fileName, encData, webId, authData,
              fileLoc: fileLoc, fileType: fileType, aclFlag: aclFlag) !=
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
