import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  final fileUrl = await getResourceUrl(filePath);
  try {
    final rawContent = await fetchPrvFile(fileUrl);
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

    await createItem(false, dirName, '', fileLoc: dirParentPath);
    return true;
  } on Exception catch (e) {
    print('Exception: $e');
  }
  return false;
}

/// Create new TTL file with content
Future<bool> createTTL(
    String fileName, String folderPath, String fileContent) async {
  try {
    final webId = await getWebId();
    assert(webId != null);
    final authData = await AuthDataManager.loadAuthData();
    assert(authData != null);

    await createItem(true, fileName, fileContent,
        fileType: 'text/turtle', fileLoc: folderPath);

    return true;
  } on Exception catch (e) {
    print('Exception: $e');
  }
  return false;
}

/// Get the app name from pubspec.yml and
/// 1. Remove any leading and trailing whitespace
/// 2. Convert to lower case
/// 3. Replace (one or multiple) white spaces with an underscore

Future<String> getAppName() async {
  final info = await PackageInfo.fromPlatform();
  final appName = info.appName;
  return appName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

/// From a given resource path create its URL
///
/// returns the full resource URL

Future<String> getResourceUrl(String resourcePath) async {
  final webId = await getWebId();
  assert(webId != null);
  assert(webId!.contains(profCard));

  final appName = await getAppName();
  final fileUrl = webId!.replaceAll(profCard, '$appName/$resourcePath');
  return fileUrl;
}

String getEncTTLStr(String filePath, String fileContent, Key key, IV iv) {
  final encData = encryptData(fileContent, key, iv);

  final g = Graph();
  final f = URIRef('https://solidcommunity.au/file');
  g.addTripleToGroups(f, pathPred, filePath);
  g.addTripleToGroups(f, ivPred, iv.base64);
  g.addTripleToGroups(f, encDataPred, encData);
  g.serialize(format: 'ttl', abbr: 'short');

  final encTTL = g.serializedString;
  return encTTL;
}
