/// Functions with restful APIs.
///
// Time-stamp: <Friday 2024-03-29 11:19:30 +1100 Graham Williams>
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
/// Authors: Dawei Chen, Zheyuan Xu

// ignore_for_file: comment_references

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart';
// ignore: implementation_imports
import 'package:solid_auth/src/openid/openid_client.dart';

import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/constants.dart';

/// Parses file information and extracts content into a map.
///
/// This function processes the provided file information, which is expected to be
/// in Turtle (Terse RDF Triple Language) format. It uses a graph-based approach
/// to parse the Turtle data and extract key attributes and their values.

Map<dynamic, dynamic> getFileContent(String fileInfo) {
  final g = Graph();
  g.parseTurtle(fileInfo);
  final fileContentMap = {};
  final fileContentList = [];
  for (final t in g.triples) {
    final predicate = t.pre.value as String;
    if (predicate.contains('#')) {
      final subject = t.sub.value;
      final attributeName = predicate.split('#')[1];
      final attrVal = t.obj.value.toString();
      if (attributeName != 'type') {
        fileContentList.add([subject, attributeName, attrVal]);
      }
      fileContentMap[attributeName] = [subject, attrVal];
    }
  }

  return fileContentMap;
}

/// The fetchPrvFile function is an asynchronous function designed to fetch
/// profile data from a specified URL [profCardUrl].
/// It takes three parameters: [profCardUrl] (the URL to fetch data from),
/// [accessToken] (used for authorization), and [dPopToken] (another form
/// of token used in headers for enhanced security).

Future<String> fetchPrvFile(
  String prvFileUrl,
  String accessToken,
  String dPopToken,
) async {
  final profResponse = await http.get(
    Uri.parse(prvFileUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'DPoP': dPopToken,
    },
  );

  if (profResponse.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return profResponse.body;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    // print(profResponse.body);
    throw Exception('Failed to load profile data! Try again in a while.');
  }
}

/// Tests the initial structure of a user's resources in a Solid Pod by checking the existence of specified folders and files.
///
/// This function is an asynchronous operation that takes in [authData], which includes authentication and encryption data,
/// and returns a [Future] that resolves to a [List<dynamic>].

Future<List<dynamic>> initialStructureTest(
    String appName, List<String> folders, Map<dynamic, dynamic> files) async {
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  final rsaInfo = authData!['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'];
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'].toString();
  final decodedToken = JwtDecoder.decode(accessToken);

  // Get webID
  final webId = decodedToken['webid'].toString();
  var allExists = true;
  final resNotExist = <dynamic, dynamic>{
    'folders': [],
    'files': [],
    'folderNames': [],
    'fileNames': []
  };

  for (final containerName in folders) {
    final resourceUrl = webId.replaceAll('profile/card#me', '$containerName/');
    final dPopToken =
        genDpopToken(resourceUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'GET');
    if (await checkResourceExists(resourceUrl, accessToken, dPopToken, false) ==
        'not-exist') {
      allExists = false;
      final resourceUrlStr = webId.replaceAll('profile/card#me', containerName);
      resNotExist['folders'].add(resourceUrlStr);
      resNotExist['folderNames'].add(containerName);
    }
  }

  for (final containerName in files.keys) {
    final fileNameList = files[containerName] as List<String>;
    for (final fileName in fileNameList) {
      final resourceUrl =
          webId.replaceAll('profile/card#me', '$containerName/$fileName');
      final dPopToken =
          genDpopToken(resourceUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'GET');
      if (await checkResourceExists(
              resourceUrl, accessToken, dPopToken, false) ==
          'not-exist') {
        allExists = false;
        resNotExist['files'].add(resourceUrl);
        resNotExist['fileNames'].add(fileName);
      }
    }
  }

  return [allExists, resNotExist];
}

/// Asynchronously creates a file or directory (item) on a server using HTTP
/// requests.
///
/// This function is used to send HTTP POST or PUT requests to a server in
/// order to create a new file or directory.

Future<String> createItem(bool fileFlag, String itemName, String itemBody,
    String webId, Map<dynamic, dynamic> authData,
    {required String fileLoc, String? fileType, bool aclFlag = false}) async {
  String? itemLoc = '';
  var itemSlug = '';
  var itemType = '';
  var contentType = '';

  // Get authentication info.

  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'];
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'].toString();

  // Set up directory or file parameters.
  if (fileFlag) {
    itemLoc = fileLoc;
    itemSlug = itemName;
    contentType = fileType!;
    itemType = '<http://www.w3.org/ns/ldp#Resource>; rel="type"';
  } else {
    itemLoc = fileLoc;
    itemSlug = itemName;
    contentType = 'application/octet-stream';
    itemType = '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"';
  }

  final encDataUrl = webId.contains('profile/card#me')
      ? webId.replaceAll('profile/card#me', itemLoc)
      : fileFlag
          ? '$webId$itemLoc'
          : '$webId/$itemLoc';

  final dPopToken =
      genDpopToken(encDataUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'POST');

  final http.Response createResponse;

  if (aclFlag) {
    final aclFileUrl = webId.contains('profile/card#me')
        ? webId.replaceAll('profile/card#me', '$itemLoc$itemName')
        : '$webId/$itemLoc$itemName';
    final dPopToken = genDpopToken(aclFileUrl, rsaKeyPair, publicKeyJwk, 'PUT');

    // The PUT request will create the acl item in the server.

    createResponse = await http.put(
      Uri.parse(aclFileUrl),
      headers: <String, String>{
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': 'text/turtle',
        'Content-Length': itemBody.length.toString(),
        'DPoP': dPopToken,
      },
      body: itemBody,
    );
  } else {
    // The POST request will create the item in the server.

    createResponse = await http.post(
      Uri.parse(encDataUrl),
      headers: <String, String>{
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': contentType,
        'Link': itemType,
        'Slug': itemSlug,
        'DPoP': dPopToken,
      },
      body: itemBody,
    );
  }

  if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return 'ok';
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to create resource! Try again in a while.');
  }
}

/// Asynchronously checks whether a given resource exists on the server.
///
/// This function makes an HTTP GET request to the specified resource URL to determine if the resource exists.
/// It handles both files and directories (containers) by setting appropriate headers based on the [fileFlag].

Future<String> checkResourceExists(
    String resUrl, String accessToken, String dPopToken, bool fileFlag) async {
  String contentType;
  String itemType;
  if (fileFlag) {
    contentType = '*/*';
    itemType = '<http://www.w3.org/ns/ldp#Resource>; rel="type"';
  } else {
    /// This is a directory (container)
    contentType = 'application/octet-stream';
    itemType = '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"';
  }

  final response = await http.get(
    Uri.parse(resUrl),
    headers: <String, String>{
      'Content-Type': contentType,
      'Authorization': 'DPoP $accessToken',
      'Link': itemType,
      'DPoP': dPopToken,
    },
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    // If the server did return a 200 OK response,
    // then return true.
    return 'exist';
  } else if (response.statusCode == 404) {
    // If the server did not return a 200 OK response,
    // then return false.
    return 'not-exist';
  } else {
    return 'other-error';
  }
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

List<String> generateDefaultFolders(String appName) {
  final mainResDir = appName;
  const myNotesDir = 'data';
  const sharingDir = 'sharing';
  const sharedDir = 'shared';
  const encDir = 'encryption';
  const logsDir = 'logs';

  final myNotesDirLoc = '$mainResDir/$myNotesDir';
  final sharingDirLoc = '$mainResDir/$sharingDir';
  final sharedDirLoc = '$mainResDir/$sharedDir';
  final encDirLoc = '$mainResDir/$encDir';
  final logDirLoc = '$mainResDir/$logsDir';

  final folders = [
    mainResDir,
    sharingDirLoc,
    sharedDirLoc,
    myNotesDirLoc,
    encDirLoc,
    logDirLoc,
  ];
  return folders;
}

/// Generates a list of default folder paths for a given application.
///
/// This function takes the name of an application as input and returns a list of strings.
/// Each string in the list represents a path to a default folder for the application.

Map<dynamic, dynamic> generateDefaultFiles(String appName) {
  final mainResDir = appName;
  const sharingDir = 'sharing';
  const sharedDir = 'shared';
  const encDir = 'encryption';
  const logsDir = 'logs';

  const encKeyFile = 'enc-keys.ttl';
  const pubKeyFile = 'public-key.ttl';
  const indKeyFile = 'ind-keys.ttl';
  const permLogFile = 'permissions-log.ttl';

  final sharingDirLoc = '$mainResDir/$sharingDir';
  final sharedDirLoc = '$mainResDir/$sharedDir';
  final encDirLoc = '$mainResDir/$encDir';
  final logDirLoc = '$mainResDir/$logsDir';

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

/// Updates a file on the server with the provided SPARQL query.
///
/// This asynchronous function sends a PATCH request to the server, targeting
/// the file specified by [fileUrl]. It uses SPARQL (a query language for RDF data)
/// to perform the update operation. This function is typically used in scenarios
/// where RDF data stored on a Solid POD (Personal Online Datastore) needs to be
/// modified.

Future<String> updateFileByQuery(
  String fileUrl,
  String accessToken,
  String dPopToken,
  String query,
) async {
  final editResponse = await http.patch(
    Uri.parse(fileUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': 'application/sparql-update',
      'Content-Length': query.length.toString(),
      'DPoP': dPopToken,
    },
    body: query,
  );

  if (editResponse.statusCode == 200 || editResponse.statusCode == 205) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return 'ok';
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to write profile data! Try again in a while.');
  }
}

/// Updates an individual key file with encrypted session key information.
///
/// This asynchronous function is responsible for updating the key file located
/// at a user's Solid POD (Personal Online Datastore) with new encrypted session
/// key data. The function performs various checks and updates the file only if
/// necessary to avoid redundant operations.

Future<String> updateIndKeyFile(
  String webId,
  Map<dynamic, dynamic> authData,
  String resName,
  String encSessionKey,
  String encNoteFilePath,
  String encNoteIv,
  String appName,
) async {
  var createUpdateRes = '';

  const encDir = 'encryption';

  final encDirLoc = '$appName/$encDir';

  // Get indi key file url.

  final keyFileUrl = webId.contains(profCard)
      ? webId.replaceAll(profCard, '$encDirLoc/$indKeyFile')
      : '$webId/$encDirLoc/$indKeyFile';

  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'];
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'].toString();

  final notesFile = '$webId/predicates/file#';
  final notesTerms = '$webId/predicates/terms#';

  // Update the file.
  // First check if the file already contain the same value.

  final dPopTokenKeyFile =
      genDpopToken(keyFileUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'GET');
  final keyFileContent =
      await fetchPrvFile(keyFileUrl, accessToken, dPopTokenKeyFile);
  final keyFileDataMap = getFileContent(keyFileContent);

  // Define query parameters.

  final prefix1 = 'file: <$notesFile>';
  final prefix2 = 'notesTerms: <$notesTerms>';

  final subject = 'file:$resName';
  final predObjPath = 'notesTerms:$pathPred "$encNoteFilePath";';
  final predObjIv = 'notesTerms:$ivPred "$encNoteIv";';
  final predObjKey = 'notesTerms:$sessionKeyPred "$encSessionKey".';

  // Check if the resource is previously added or not.

  if (keyFileDataMap.containsKey(resName)) {
    final existPath = keyFileDataMap[resName][pathPred].toString();
    final existIv = keyFileDataMap[resName][ivPred].toString();
    final existKey = keyFileDataMap[resName][sessionKeyPred].toString();

    // If file does not contain the same encrypted value then delete and update
    // the file.
    // NOTE: Public key encryption generates different hashes different time for same plaintext value.
    // Therefore this always ends up deleting the previous and adding a new hash.
    if (existKey != encSessionKey ||
        existPath != encNoteFilePath ||
        existIv != encNoteIv) {
      final predObjPathPrev = 'notesTerms:$pathPred "$existPath";';
      final predObjIvPrev = 'notesTerms:$ivPred "$existIv";';
      final predObjKeyPrev = 'notesTerms:$sessionKeyPred "$existKey".';

      // Generate update sparql query.

      final query =
          'PREFIX $prefix1 PREFIX $prefix2 DELETE DATA {$subject $predObjPathPrev $predObjIvPrev $predObjKeyPrev}; INSERT DATA {$subject $predObjPath $predObjIv $predObjKey};';

      // Generate DPoP token.

      final dPopTokenKeyFilePatch =
          genDpopToken(keyFileUrl, rsaKeyPair, publicKeyJwk, 'PATCH');

      // Run the query.

      createUpdateRes = await updateFileByQuery(
          keyFileUrl, accessToken, dPopTokenKeyFilePatch, query);
    } else {
      // If the file contain same values, then no need to run anything.
      createUpdateRes = 'ok';
    }
  } else {
    // Generate insert only sparql query.

    final query =
        'PREFIX $prefix1 PREFIX $prefix2 INSERT DATA {$subject $predObjPath $predObjIv $predObjKey};';

    // Generate DPoP token.

    final dPopTokenKeyFilePatch =
        genDpopToken(keyFileUrl, rsaKeyPair, publicKeyJwk, 'PATCH');

    // Run the query.

    createUpdateRes = await updateFileByQuery(
        keyFileUrl, accessToken, dPopTokenKeyFilePatch, query);
  }

  if (createUpdateRes == 'ok') {
    return createUpdateRes;
  } else {
    throw Exception('Failed to create/update the shared file.');
  }
}

// Updates the initial profile data on the server.
///
/// This function sends a PUT request to update the user's profile information. It constructs the profile URL from the provided `webId`, generates a DPoP token using the RSA key pair and public key in JWK format from `authData`, and then sends the request with the `profBody` as the payload.
///
/// The `authData` map must contain `rsaInfo` (which includes `rsa` key pair and `pubKeyJwk`) and an `accessToken`. The function modifies the `webId` URL to target the appropriate resource on the server.
///
/// Throws an Exception if the server does not return a 200 OK or 205 Reset Content response, indicating a failure in updating the profile.

Future<String> initialProfileUpdate(
  String profBody,
  Map<dynamic, dynamic> authData,
  String webId,
) async {
  // Get authentication info
  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'];
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'] as String;

  final profUrl = webId.replaceAll('#me', '');
  final dPopToken =
      genDpopToken(profUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'PUT');

  // The PUT request will create the acl item in the server
  final updateResponse = await http.put(
    Uri.parse(profUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': 'text/turtle',
      'Content-Length': profBody.length.toString(),
      'DPoP': dPopToken,
    },
    body: profBody,
  );

  if (updateResponse.statusCode == 200 || updateResponse.statusCode == 205) {
    // If the server did return a 205 Reset response,
    return 'ok';
  } else {
    // If the server did not return a 205 response,
    // then throw an exception.
    throw Exception('Failed to update resource! Try again in a while.');
  }
}

/// Get encryption keys from the private file
///
/// returns the file content

Future<String> fetchKeyData() async {
  final webId = await getWebId();
  assert(webId != null);
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  final rsaInfo = authData!['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'];
  final keyFileUrl = webId!.replaceAll(profCard, 'keypod/$encDir/$encKeyFile');
  final dPopTokenKey =
      genDpopToken(keyFileUrl, rsaKeyPair, publicKeyJwk, 'GET');

  final keyData = await fetchPrvFile(
    keyFileUrl,
    accessToken as String,
    dPopTokenKey,
  );

  return keyData;
}

/// Get tokens necessary to fetch a file from a POD
///
/// returns the access token and DPoP token

Future<List<dynamic>> getTokens(String fileUrl) async {
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  final rsaInfo = authData!['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'];
  final dPopToken = genDpopToken(fileUrl, rsaKeyPair, publicKeyJwk, 'GET');

  return [accessToken, dPopToken];
}

/// From a given file path create file URL
///
/// returns the full file URL

Future<String> createFileUrl(String filePath) async {
  final webId = await getWebId();

  final appDetails = await getAppNameVersion();
  final appName = appDetails[0];
  final keyFileUrl = webId!.replaceAll(profCard, '$appName/$filePath');

  return keyFileUrl;
}

/// Extract the app name and the version from the package info

Future<List<dynamic>> getAppNameVersion() async {
  final info = await PackageInfo.fromPlatform();
  final appName = info.appName;
  final appVersion = info.version;

  return [appName, appVersion];
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
  static const String authDataSecureStorageKey = '_solid_auth_data';

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
        authDataSecureStorageKey,
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
      final tokenResponse = await _authResponse!.getTokenResponse();
      return {
        'client': _authResponse!.client,
        'rsaInfo': _rsaInfo,
        'authResponse': _authResponse,
        'tokenResponse': tokenResponse,
        'accessToken': tokenResponse.accessToken,
        'idToken': _authResponse!.idToken,
        'refreshToken': _authResponse!.refreshToken,
        'expiresIn': tokenResponse.expiresIn,
        'logoutUrl': _logoutUrl,
      };
    } on Exception catch (e) {
      debugPrint('AuthDataManager => loadAuthData() failed: $e');
      return null;
    }
  }

  /// Remove/delete auth data from secure storage
  static Future<bool> removeAuthData() async {
    try {
      await secureStorage.delete(key: authDataSecureStorageKey);
      _logoutUrl = null;
      _rsaInfo = null;
      _authResponse = null;

      return true;
    } on Exception {
      debugPrint('AuthDataManager => removeAuthData() failed');
      return false;
    }
  }

  /// Returns the (refreshed) access token
  static Future<String?> getAccessToken() async {
    if (_authResponse == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => getAccessToken() failed');
        return null;
      }
    }
    assert(_authResponse != null);

    try {
      var tokenResponse = TokenResponse.fromJson(_authResponse!.response!);
      if (tokenResponse.expiresAt == null ||
          tokenResponse.expiresAt!.isBefore(DateTime.now())) {
        print('refreshing access token');
        assert(_rsaInfo != null);
        final rsaKeyPair = _rsaInfo!['rsa'] as KeyPair;
        final publicKeyJwk = _rsaInfo!['pubKeyJwk'];
        String tokenEndpoint =
            _authResponse!.client.issuer.metadata['token_endpoint'] as String;
        String dPopToken =
            genDpopToken(tokenEndpoint, rsaKeyPair, publicKeyJwk, 'POST');
        tokenResponse = await _authResponse!
            .getTokenResponse(forceRefresh: true, dPoPToken: dPopToken);
      }
      return tokenResponse.accessToken;
    } on Exception catch (e) {
      debugPrint('AuthDataManager => getAccessToken() Exception: $e');
      return null;
    }
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
    final dataStr = await secureStorage.read(key: authDataSecureStorageKey);

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
