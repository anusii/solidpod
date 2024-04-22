import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart' show writeToSecureStorage;
import 'package:solidpod/src/solid/constants.dart';

// solid-encrypt uses unencrypted local storage and refers to http://yarrabah.net/ for predicates definition,
// not sure if it is a good idea to use it here?
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Derive the master key from master password
Key genMasterKey(String masterPasswd) => Key.fromUtf8(
    sha256.convert(utf8.encode(masterPasswd)).toString().substring(0, 32));

/// Derive the verification key from master password
String genVerificationKey(String masterPasswd) =>
    sha224.convert(utf8.encode(masterPasswd)).toString().substring(0, 32);

/// Verify the user provided master password for data encryption
bool verifyMasterPasswd(String masterPasswd, String verificationKey) =>
    genVerificationKey(masterPasswd) == verificationKey;

/// Save master password to local secure storage
Future<void> saveMasterPassword(String masterPasswd) async {
  await writeToSecureStorage(masterPasswdSecureStorageKey, masterPasswd);
}

/// Load master password from local secure storage
Future<String?> loadMasterPassword() async {
  final webId = await getWebId();
  assert(webId != null);
  // TODO: the current initialisation code uses web ID as key, update it.
  // see src/screens/initial_setup/widgets/res_create_form_submission.dart
  final masterPasswd =
      await secureStorage.read(key: masterPasswdSecureStorageKey);
  return masterPasswd;
}

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
Future<bool> createTTL(String filePath, String fileContent) async {
  try {
    final fileName = path.basename(filePath);
    final folderPath = path.dirname(filePath);

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
  final fileUrl = webId!.replaceAll(profCard, resourcePath);
  return fileUrl;
}

/// Encrypt a given data string and format to TTL
Future<String> getEncTTLStr(
    String filePath, String fileContent, Key key, IV iv) async {
  final encData = encryptData(fileContent, key, iv);

  final g = Graph();
  //final f = URIRef(appsFile + filePath); //TODO: update this
  final f = URIRef(await getResourceUrl(filePath));
  final ns = Namespace(ns: appsTerms);
  g.addTripleToGroups(f, ns.withAttr(pathPred), filePath);
  g.addTripleToGroups(f, ns.withAttr(ivPred), iv.base64);
  g.addTripleToGroups(f, ns.withAttr(encDataPred), encData);

  // Bind the long namespace to shorter string for better readability
  // String getPrefix(String UriStr) => Uri.parse(UriStr).pathSegments[-1];
  // g.bind(appFilePrefix, Namespace(ns: appsFile));
  // g.bind(appTermPrefix, ns);
  // final uri = Uri.parse(appsTerms);
  // final host = uri.host.split('.')[0];
  // final hostpath = uri.removeFragment().toString();
  // g.bind(host, Namespace(ns: hostpath));
  // g.bind(host, ns);

  g.serialize(format: 'ttl', abbr: 'short');

  final encTTL = g.serializedString;
  return encTTL;
}

/// Returns the path of file with verification key and private key
Future<String> getEncKeyPath() async {
  final appName = await getAppName();
  return path.join(appName, encDir, encKeyFile);
}

/// Returns the path of file with individual keys
Future<String> getIndKeyPath() async {
  final appName = await getAppName();
  return path.join(appName, encDir, indKeyFile);
}

/// Add (encrypted) individual/session key [encIndKey] and the corresponding
/// IV [iv] for file with path [filePath]
Future<void> addIndKey(String filePath, String encIndKey, IV iv) async {
  // const filePrefix = '$appFilePrefix: <$appsFile>';
  // const termPrefix = '$appTermPrefix: <$appsTerms>';
  // final sub = appsFile + filePath;
  // final sub = '$appFilePrefix:$filePath';
  final sub = await getResourceUrl(filePath);
  // final query = [
  //   'PREFIX $filePrefix',
  //   'PREFIX $termPrefix',
  //   'INSERT DATA {',
  //   sub,
  //   '$appTermPrefix:$pathPred $filePath;',
  //   '$appTermPrefix:$ivPred ${iv.base64};',
  //   '$appTermPrefix:$sessionKeyPred $encIndKey.',
  //   '};'
  //].join(' ');
  final query =
      'INSERT DATA {<$sub> <$appsTerms$pathPred> "$filePath"; <$appsTerms$ivPred> "${iv.base64}"; <$appsTerms$sessionKeyPred> "$encIndKey".};';
  final fileUrl = await getResourceUrl(await getIndKeyPath());
  await updateFileByQuery(fileUrl, query);
}
