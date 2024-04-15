import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart' show writeToSecureStorage;
import 'package:solidpod/src/solid/constants.dart';

// solid-encrypt uses unencrypted local storage and refers to http://yarrabah.net/ for predicates definition,
// not sure if it is a good idea to use it here?
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

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
/// TODO: update solid-encrypt and use the its encrypt/decrypt functions
/// key: Key.fromUtf8(key_utf8_str) or Key.fromBase64(key_base64_str)
({String encData, String iv}) encryptData(String data, Key key) {
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  final encryptVal = encrypter.encrypt(data, iv: iv);
  return (encData: encryptVal.base64, iv: iv.base64);
}

/// Decrypt a ciphertext value
String decryptData(String encData, Key key, String iv) {
  final encrypter = Encrypter(AES(key));
  return encrypter.decrypt(Encrypted.from64(encData), iv: IV.fromBase64(iv));
}

/// Create a random individual/session key
Key getIndividualKey() {
  return Key.fromSecureRandom(32);
}

// /// Encrypt individual key
// ({String indKeyEnc, String indKeyIV}) encryptIndividualKey(
//     Key indKey, String masterKey) {
//   final enc = encryptData(indKey.base64, Key.fromUtf8(masterKey));
//   return (indKeyEnc: enc.encData, indKeyIV: enc.iv);
// }

/// Verify the user provided password for data encryption
bool verifyEncPasswd(String plainTxtPasswd, String verificationKey) {
  return genVerificationKey(plainTxtPasswd) == verificationKey;
}

/// Save encryption password in local secure storage
Future<void> saveEncPasswd(String plainTxtPasswd) async {
  await writeToSecureStorage(encPasswdSecureStorageKey, plainTxtPasswd);
}

/// Load encryption master key
Future<String?> loadEncPasswd() async {
  final plainTxtPasswd =
      await secureStorage.read(key: encPasswdSecureStorageKey);
  return plainTxtPasswd;
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

/// Create a directory
Future<bool> createDir(String dirName, String dirParentPath) async {
  try {
    final webId = await getWebId();
    assert(webId != null);
    final authData = await AuthDataManager.loadAuthData();
    assert(authData != null);

    final ret = await createItem(false, dirName, '', webId!, authData!,
        fileLoc: dirParentPath);

    if (ret == 'ok') {
      return true;
    }
  } on Exception catch (e) {
    print('Exception: $e');
    return false;
  }

  return false;
}

/// Create new TTL file with content
Future<bool> createTTL(
    String fileName, String folderPath, String content) async {
  try {
    final webId = await getWebId();
    assert(webId != null);
    final authData = await AuthDataManager.loadAuthData();
    assert(authData != null);

    final ret = await createItem(true, fileName, content, webId!, authData!,
        fileType: 'text/turtle', fileLoc: folderPath);

    if (ret == 'ok') {
      return true;
    }
  } on Exception catch (e) {
    print('Exception: $e');
    return false;
  }

  return false;
}
