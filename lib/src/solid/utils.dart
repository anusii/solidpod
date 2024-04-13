import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';

//import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Derive the master key from user password
String genEncMasterKey(String plainTxtPasswd) {
  final encMasterKey =
      sha256.convert(utf8.encode(plainTxtPasswd)).toString().substring(0, 32);
  return encMasterKey;
}

/// Derive the verification key from user password
String genVerificationKey(String plainTxtPasswd) {
  final encMasterKeyVerify =
      sha224.convert(utf8.encode(plainTxtPasswd)).toString().substring(0, 32);
  return encMasterKeyVerify;
}

/// Encrypt data using AES with the specified key
/// Return a record (with named fields)
/// https://dart.dev/language/records
/// TODO: use encrypt/decrypt functions from solid-encrypt rather than this function
({String encData, String iv}) encryptData(String key, String data) {
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
  final encryptVal = encrypter.encrypt(data, iv: iv);
  return (encData: encryptVal.base64, iv: iv.base64);
}

/// Verify the user provided password for data encryption
bool verifyEncPasswd(String plainTxtPasswd, String verificationKey) {
  return genVerificationKey(plainTxtPasswd) == verificationKey;
}

/// Load and parse a private TTL file from POD
Future<Map<dynamic, dynamic>?> loadPrvTTL(String filePath) async {
  final fileUrl = await createFileUrl(filePath);
  final tokens = await getTokens(fileUrl);
  try {
    final rawContent =
        await fetchPrvFile(fileUrl, tokens.accessToken, tokens.dPopToken);
    return getFileContent(rawContent);
  } on Exception catch (e) {
    print('Exception: $e');
    return null;
  }
}
