/// Functions with restful APIs.
///
// Time-stamp: <Tuesday 2024-01-02 15:57:15 +1100 Zheyuan Xu>
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
/// Authors: Zheyuan Xu

library;

import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid_auth/solid_auth.dart';

/// The fetchPrvFile function is an asynchronous function designed to fetch
/// profile data from a specified URL [profCardUrl].
/// It takes three parameters: [profCardUrl] (the URL to fetch data from),
/// [accessToken] (used for authorization), and [dPopToken] (another form
/// of token used in headers for enhanced security).

Future<String> fetchPrvFile(
  String profCardUrl,
  String accessToken,
  String dPopToken,
) async {
  final profResponse = await http.get(
    Uri.parse(profCardUrl),
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
    //print(profResponse.body);
    throw Exception('Failed to load profile data! Try again in a while.');
  }
}

/// Tests the initial structure of a user's resources in a Solid Pod by checking the existence of specified folders and files.
///
/// This function is an asynchronous operation that takes in [authData], which includes authentication and encryption data,
/// and returns a [Future] that resolves to a [List<dynamic>].

Future<List<dynamic>> initialStructureTest(Map<dynamic, dynamic> authData,
    String appName, List<String> folders, Map<dynamic, dynamic> files) async {
  final rsaInfo = authData['rsaInfo'];
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

/// Asynchronously creates a file or directory (item) on a server using HTTP requests.
///
/// This function is used to send HTTP POST or PUT requests to a server in order to create a new file or directory.

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
