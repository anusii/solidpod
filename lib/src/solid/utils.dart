/// Common utility functions used across the package.
///
// Time-stamp: <Friday 2024-02-16 10:59:10 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Anushka Vidanage, Dawei Chen, Zheyuan Xu

library;

import 'dart:convert';

import 'package:flutter/foundation.dart' hide Key;

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:solid_auth/src/openid/openid_client.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants.dart';

// solid-encrypt uses unencrypted local storage and refers to http://yarrabah.net/ for predicates definition,
// do not use it before it is updated (same as what the gurriny project does)
// import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

/// Write the given [key], [value] pair to the secure storage.
///
/// If [key] already exisits then delete that first and then
/// write again.

Future<void> writeToSecureStorage(String key, String value) async {
  final isKeyExist = await secureStorage.containsKey(
    key: key,
  );

  // Since write() method does not automatically overwrite an existing value.
  // To overwrite an existing value, call delete() first.

  if (isKeyExist) {
    await secureStorage.delete(
      key: key,
    );
  }

  await secureStorage.write(
    key: key,
    value: value,
  );
}

/// Derive the master key from master password
Key genMasterKey(String masterPasswd) => Key.fromUtf8(
    sha256.convert(utf8.encode(masterPasswd)).toString().substring(0, 32));

/// Derive the verification key from master password
String genVerificationKey(String masterPasswd) =>
    sha224.convert(utf8.encode(masterPasswd)).toString().substring(0, 32);

/// Get the verification key stored in PODs
Future<String?> getVerificationKey() async {
  final encKeyPath = await getEncKeyPath();
  final encKeyMap = await loadPrvTTL(encKeyPath);
  if (encKeyMap == null) {
    return null;
  }

  final encKeyFileUrl = await getResourceUrl(encKeyPath);
  if (!encKeyMap.containsKey(encKeyFileUrl)) {
    return null;
  }

  final verificationKey = encKeyMap[encKeyFileUrl][encKeyPred] as String;
  return verificationKey;
}

/// Verify the user provided master password for data encryption
bool verifyMasterPassword(String masterPasswd, String verificationKey) =>
    genVerificationKey(masterPasswd) == verificationKey;

/// Save master password to local secure storage
Future<void> saveMasterPassword(String masterPasswd) async {
  await writeToSecureStorage(masterPasswdSecureStorageKey, masterPasswd);
}

/// Load master password from local secure storage
Future<String?> loadMasterPassword() async {
  // final webId = await getWebId();
  // assert(webId != null);
  // TODO: the current initialisation code uses web ID as key, update it.
  // see src/screens/initial_setup/widgets/res_create_form_submission.dart
  final masterPasswd =
      await secureStorage.read(key: masterPasswdSecureStorageKey);
  return masterPasswd;
}

/// Delete the saved master password from local secure storage
Future<void> removeMasterPassword() async {
  if (await secureStorage.containsKey(key: masterPasswdSecureStorageKey)) {
    await secureStorage.delete(key: masterPasswdSecureStorageKey);
  }
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
    await createItem(false, dirName, '', fileLoc: dirParentPath);
    return true;
  } on Exception catch (e) {
    print('Exception: $e');
  }
  return false;
}

/// Create new TTL file with content
Future<bool> createFile(String filePath, String fileContent) async {
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
  final resourceUrl = webId!.replaceAll(profCard, resourcePath);
  return resourceUrl;
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

  g.serialize(abbr: 'short');

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

/// Returns the path of the data directory
Future<String> getDataDirPath() async {
  final appName = await getAppName();
  return path.join(appName, dataDir);
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

/// Extract the app name and the version from the package info
/// Return a record (with named fields https://dart.dev/language/records)

Future<({String name, String version})> getAppNameVersion() async {
  final info = await PackageInfo.fromPlatform();
  return (name: info.appName, version: info.version);
}

/// Check whether a user is logged in or not
///
/// Check if the local storage has authentication
/// details of the user and also check whether the
/// access token is expired or not
/// returns boolean

Future<bool> checkLoggedIn() async {
  final webId = await getWebId();

  if (webId != null && webId.isNotEmpty) {
    final accessToken = await AuthDataManager.getAccessToken();
    if (accessToken != null && !JwtDecoder.isExpired(accessToken)) {
      return true;
    }
  }

  return false;
}

/// Delete login information from the local storage
///
/// returns true if successful

Future<bool> deleteLogIn() async {
  const success = true;
  try {
    await secureStorage.delete(key: 'webid');
  } on Exception {
    return false;
  }
  return success && (await AuthDataManager.removeAuthData());
}

/// Get the webId from local storage

Future<String?> getWebId() async {
  final webId = await secureStorage.read(key: 'webid');
  return webId;
}

/// [AuthDataManager] is a class to manage auth data returned by
/// solid-auth authenticate, including:
/// - save auth data to secure storage
/// - load auth data from secure storage
/// - delete saved auth data from secure storage
/// - refresh access token if necessary

class AuthDataManager {
  /// The URL for logging out
  static String? _logoutUrl;

  /// The RSA keypair and their JWK format
  /// It seems Map<String, dynamic> does not work
  static Map<dynamic, dynamic>? _rsaInfo;

  /// The authentication response
  static Credential? _authResponse;

  /// The string key for storing auth data in secure storage
  static const String _authDataSecureStorageKey = '_solid_auth_data';

  /// Save the auth data returned by solid-auth authenticate in secure storage
  /// It seems Map<String, dynamic> does not work
  static Future<void> saveAuthData(Map<dynamic, dynamic> authData) async {
    const keys = [
      'client',
      'rsaInfo',
      'authResponse',
      'tokenResponse',
      'accessToken',
      'idToken',
      'refreshToken',
      'expiresIn',
      'logoutUrl',
    ];

    for (final key in keys) {
      assert(authData.containsKey(key));
    }

    _logoutUrl = authData['logoutUrl'] as String;
    _rsaInfo = authData['rsaInfo'] as Map<dynamic,
        dynamic>; // Note that use Map<String, dynamic> does not seem to work
    _authResponse = authData['authResponse'] as Credential;

    await writeToSecureStorage(
        _authDataSecureStorageKey,
        jsonEncode({
          'logout_url': _logoutUrl,
          'rsa_info': jsonEncode({
            ..._rsaInfo!,
            // Overwrite the 'rsa' keypair in rsaInfo
            'rsa': {
              'public_key': _rsaInfo!['rsa'].publicKey as String,
              'private_key': _rsaInfo!['rsa'].privateKey as String,
            },
          }),
          'auth_response': _authResponse!.toJson(),
        }));

    debugPrint('AuthDataManager => saveAuthData() done');
  }

  /// Retrieve (and reconstruct) auth data from secure storage
  /// It seems Map<String, dynamic> does not work
  static Future<Map<dynamic, dynamic>?> loadAuthData() async {
    if (_logoutUrl == null || _rsaInfo == null || _authResponse == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => loadAuthData() failed');
        return null;
      }
    }

    assert(_logoutUrl != null && _rsaInfo != null && _authResponse != null);
    try {
      final tokenResponse = await _getTokenResponse();
      return {
        'client': _authResponse!.client,
        'rsaInfo': _rsaInfo,
        'authResponse': _authResponse,
        'tokenResponse': tokenResponse,
        'accessToken': tokenResponse!.accessToken,
        'idToken': _authResponse!.idToken,
        'refreshToken': _authResponse!.refreshToken,
        'expiresIn': tokenResponse.expiresIn,
        'logoutUrl': _logoutUrl,
      };
    } on Exception catch (e) {
      debugPrint('AuthDataManager => loadAuthData() failed: $e');
    }
    return null;
  }

  /// Remove/delete auth data from secure storage
  static Future<bool> removeAuthData() async {
    try {
      if (await secureStorage.containsKey(key: _authDataSecureStorageKey)) {
        await secureStorage.delete(key: _authDataSecureStorageKey);
        _logoutUrl = null;
        _rsaInfo = null;
        _authResponse = null;
      }

      return true;
    } on Exception {
      debugPrint('AuthDataManager => removeAuthData() failed');
    }
    return false;
  }

  /// Returns the (refreshed) access token
  static Future<String?> getAccessToken() async {
    final tokenResponse = await _getTokenResponse();
    if (tokenResponse != null) {
      return tokenResponse.accessToken;
    } else {
      debugPrint('AuthDataManager => getAccessToken() failed');
    }
    return null;
  }

  /// Returns the (updated) token response
  static Future<TokenResponse?> _getTokenResponse() async {
    if (_authResponse == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => _getTokenResponse() failed');
        return null;
      }
    }
    assert(_authResponse != null);

    try {
      var tokenResponse = TokenResponse.fromJson(_authResponse!.response!);
      if (JwtDecoder.isExpired(tokenResponse.accessToken!)) {
        debugPrint(
            'AuthDataManager => _getTokenResponse() refreshing expired token');
        assert(_rsaInfo != null);
        final rsaKeyPair = _rsaInfo!['rsa'] as KeyPair;
        final publicKeyJwk = _rsaInfo!['pubKeyJwk'];
        final tokenEndpoint =
            _authResponse!.client.issuer.metadata['token_endpoint'] as String;
        final dPopToken =
            genDpopToken(tokenEndpoint, rsaKeyPair, publicKeyJwk, 'POST');
        tokenResponse = await _authResponse!
            .getTokenResponse(forceRefresh: true, dPoPToken: dPopToken);
      }
      return tokenResponse;
    } on Exception catch (e) {
      debugPrint('AuthDataManager => _getTokenResponse() failed: $e');
    }
    return null;
  }

  /// Returns the logout URL
  static Future<String?> getLogoutUrl() async {
    if (_logoutUrl == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => getLogoutUrl() failed');
        return null;
      }
    }
    assert(_logoutUrl != null);
    return _logoutUrl;
  }

  /// Reconstruct the rsaInfo from JSON string
  static Map<dynamic, dynamic> _getRsaInfo(String rsaJson) {
    final rsaInfo_ = jsonDecode(rsaJson) as Map<String, dynamic>;
    final publicKey = rsaInfo_['rsa']['public_key'] as String;
    final privateKey = rsaInfo_['rsa']['private_key'] as String;

    return {...rsaInfo_, 'rsa': KeyPair(publicKey, privateKey)};
  }

  /// Retrieve auth data from secure storage
  static Future<bool> _loadData() async {
    final dataStr = await secureStorage.read(key: _authDataSecureStorageKey);

    if (dataStr != null) {
      final dataMap = jsonDecode(dataStr) as Map<String, dynamic>;
      _logoutUrl = dataMap['logout_url'] as String;
      _rsaInfo = _getRsaInfo(dataMap['rsa_info'] as String);
      _authResponse =
          Credential.fromJson((dataMap['auth_response'] as Map).cast());

      return true;
    }
    return false;
  }
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<List<String>> generateDefaultFolders() async {
  final appName = await getAppName();
  final mainResDir = appName;

  final dataDirLoc = path.join(mainResDir, dataDir);
  final sharingDirLoc = path.join(mainResDir, sharingDir);
  final sharedDirLoc = path.join(mainResDir, sharedDir);
  final encDirLoc = path.join(mainResDir, encDir);
  final logDirLoc = path.join(mainResDir, logsDir);

  final folders = [
    mainResDir,
    sharingDirLoc,
    sharedDirLoc,
    dataDirLoc,
    encDirLoc,
    logDirLoc,
  ];
  return folders;
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Future<Map<dynamic, dynamic>> generateDefaultFiles() async {
  final appName = await getAppName();
  final mainResDir = appName;

  const encKeyFile = 'enc-keys.ttl';
  const pubKeyFile = 'public-key.ttl';
  const indKeyFile = 'ind-keys.ttl';
  const permLogFile = 'permissions-log.ttl';

  final sharingDirLoc = path.join(mainResDir, sharingDir);
  final sharedDirLoc = path.join(mainResDir, sharedDir);
  final encDirLoc = path.join(mainResDir, encDir);
  final logDirLoc = path.join(mainResDir, logsDir);

  final files = {
    sharingDirLoc: [
      pubKeyFile,
      '$pubKeyFile.acl',
    ],
    logDirLoc: [
      permLogFile,
      '$permLogFile.acl',
    ],
    sharedDirLoc: ['.acl'],
    encDirLoc: [encKeyFile, indKeyFile],
  };
  return files;
}
