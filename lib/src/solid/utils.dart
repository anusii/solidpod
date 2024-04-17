import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart' show writeToSecureStorage;
import 'package:solidpod/src/solid/constants.dart';

// solid-encrypt uses unencrypted local storage and refers to http://yarrabah.net/ for predicates definition,
// not sure if it is a good idea to use it here?
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Derive the master key from user password
Key genEncMasterKey(String plainTxtPasswd) => Key.fromUtf8(
    sha256.convert(utf8.encode(plainTxtPasswd)).toString().substring(0, 32));

/// Derive the verification key from user password
String genVerificationKey(String plainTxtPasswd) =>
    sha224.convert(utf8.encode(plainTxtPasswd)).toString().substring(0, 32);

/// Encrypt data using AES with the specified key
String encryptData(String data, Key key, IV iv) {
  final encrypter = Encrypter(AES(key));
  final encryptVal = encrypter.encrypt(data, iv: iv);
  return encryptVal.base64;
}

/// Decrypt a ciphertext value
String decryptData(String encData, Key key, IV iv) =>
    Encrypter(AES(key)).decrypt(Encrypted.from64(encData), iv: iv);

/// Create a random individual/session key
Key getIndividualKey() => Key.fromSecureRandom(32);

/// Create a random intialisation vector
IV getIV() => IV.fromLength(16);

/// Create a Key object from its utf-8 string
// Key getKeyfromUtf8(String utf8KeyStr) => Key.fromUtf8(utf8KeyStr);

/// Create a Key object from its base64 string
// Key getKeyfromBase64(String base64KeyStr) => Key.fromBase64(base64KeyStr);

/// Create a IV object from its base64 string
// IV getIVfromBase64(String base64IVStr) => IV.fromBase64(base64IVStr);

/// Verify the user provided password for data encryption
bool verifyEncPasswd(String plainTxtPasswd, String verificationKey) =>
    genVerificationKey(plainTxtPasswd) == verificationKey;

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

/// Parse TTL content into a map {subject: {predicate: object}}
Map<String, dynamic> parseTTL(String ttlContent) {
  final g = Graph();
  g.parseTurtle(ttlContent);
  final dataMap = <String, dynamic>{};
  String extract(String str) => str.contains('#') ? str.split('#')[1] : str;
  for (final t in g.triples) {
    final sub = extract(t.sub.value as String);
    final pre = extract(t.pre.value as String);
    final obj = extract(t.obj.value as String);
    if (dataMap.containsKey(sub)) {
      assert(!(dataMap[sub] as Map).containsKey(pre));
      dataMap[sub][pre] = obj;
    } else {
      dataMap[sub] = {pre: obj};
    }
  }
  return dataMap;
}

/// Load and parse a private TTL file from POD
Future<Map<String, dynamic>?> loadPrvTTL(String filePath) async {
  final fileUrl = await createFileUrl(filePath);
  final tokens = await getTokens(fileUrl);
  try {
    final rawContent =
        await fetchPrvFile(fileUrl, tokens.accessToken, tokens.dPopToken);
    return parseTTL(rawContent);
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
