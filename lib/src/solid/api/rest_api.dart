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

import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:rdflib/rdflib.dart';
import 'package:solid_auth/solid_auth.dart';

import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart'
    show AuthDataManager;

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

Future<String> fetchPrvFile(String prvFileUrl) async {
  final (:accessToken, :dPopToken) =
      await getTokensForResource(prvFileUrl, 'GET');
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
    print(profResponse.body);
    throw Exception('Failed to load profile data! Try again in a while.');
  }
}

/// Tests the initial structure of a user's resources in a Solid Pod by checking the existence of specified folders and files.
///
/// This function is an asynchronous operation that takes in [authData], which includes authentication and encryption data,
/// and returns a [Future] that resolves to a [List<dynamic>].

Future<List<dynamic>> initialStructureTest(
    List<String> folders, Map<dynamic, dynamic> files) async {
  var allExists = true;
  final resNotExist = <dynamic, dynamic>{
    'folders': [],
    'files': [],
    'folderNames': [],
    'fileNames': []
  };

  for (final containerName in folders) {
    // NB: the trailing separator in path is essential for this check
    final resourceUrl = await getDirUrl(containerName);
    if (await checkResourceExists(resourceUrl, false) ==
        ResourceStatus.notExist) {
      allExists = false;

      resNotExist['folders'].add(resourceUrl);
      resNotExist['folderNames'].add(containerName);
    }
  }

  for (final containerName in files.keys) {
    final fileNameList = files[containerName] as List<String>;
    for (final fileName in fileNameList) {
      final resourceUrl =
          await getFileUrl([containerName as String, fileName].join('/'));
      if (await checkResourceExists(resourceUrl, false) ==
          ResourceStatus.notExist) {
        allExists = false;
        resNotExist['files'].add(resourceUrl);
        resNotExist['fileNames'].add(fileName);
      }
    }
  }

  return [allExists, resNotExist];
}

/// Asynchronously creates a resource (a file or directory / container)
/// on a server using HTTP requests:
/// - PUT request: create or replace a resource if exists (e.g. an ACL file)
/// - POST request: create a resource (e.g. a TTL file or a directory)

Future<void> createResource(String resourceUrl,
    {String content = '',
    bool fileFlag = true,
    bool replaceIfExist = false}) async {
  // Sanity check
  if (fileFlag) {
    assert(!resourceUrl.endsWith('/'));
  } else {
    assert(resourceUrl.endsWith('/'));
  }

  // Use PUT request for creating and replacing a file if it already exists

  final put = (fileFlag && replaceIfExist) ? true : false;
  final httpMethod = put ? http.put : http.post;

  // Get the name and parent container URL of the resource to be created for
  // POST request

  late String name;
  late String parentUrl;

  if (!put) {
    final items = resourceUrl.split('/');
    final index = fileFlag ? items.length - 1 : items.length - 2;

    name = items[index];
    parentUrl = '${items.getRange(0, index).join('/')}/';
  }

  final (:accessToken, :dPopToken) = await getTokensForResource(
      put ? resourceUrl : parentUrl, put ? 'PUT' : 'POST');

  final response = await httpMethod(
    Uri.parse(put ? resourceUrl : parentUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': fileFlag ? fileContentType : dirContentType,
      if (put) 'Content-Length': content.length.toString(),
      if (!put) 'Link': fileFlag ? fileTypeLink : dirTypeLink,
      if (!put) 'Slug': name,
      'DPoP': dPopToken,
    },
    body: content,
  );

  if ([200, 201, 205].contains(response.statusCode)) {
    return;
  } else {
    throw Exception('Failed to create resource!'
        '\nURL: $resourceUrl'
        '\nERROR: ${response.body}');
  }
}

/// From a given resource path create its URL
///
/// returns the full resource URL

// Future<String> getResourceUrl(String resourcePath) async {
//   final webId = await getWebId();
//   assert(webId != null);
//   assert(webId!.contains(profCard));
//   final resourceUrl = webId!.replaceAll(profCard, resourcePath);
//   return resourceUrl;
// }

// /// Asynchronously creates a file or directory on a server using HTTP requests.
// ///
// /// PUT request: create or replace a resource
// /// POST request: create a resource

// Future<void> createItem(bool fileFlag, String itemName, String itemBody,
//     {required String fileLoc, String? fileType, bool aclFlag = false}) async {
//   String? itemLoc = '';
//   var itemSlug = '';
//   var itemType = '';
//   var contentType = '';

//   // Set up directory or file parameters.
//   if (fileFlag) {
//     itemLoc = fileLoc;
//     itemSlug = itemName;
//     contentType = fileType!;
//     itemType = '<http://www.w3.org/ns/ldp#Resource>; rel="type"';
//   } else {
//     itemLoc = fileLoc;
//     itemSlug = itemName;
//     contentType = 'application/octet-stream';
//     itemType = '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"';
//   }

//   // final resourcePath = fileFlag ? itemLoc : '$itemLoc/';
//   // final encDataUrl = webId!.contains(profCard)
//   //     ? webId.replaceAll(profCard, itemLoc)
//   //     : fileFlag
//   //         ? '$webId$itemLoc'
//   //         : '$webId/$itemLoc';
//   final resourceUrl = await getResourceUrl(itemLoc);

//   final http.Response createResponse;

//   if (aclFlag) {
//     // final aclFileUrl = webId.contains(profCard)
//     //     ? webId.replaceAll(profCard, '$itemLoc$itemName')
//     //     : '$webId/$itemLoc$itemName';
//     // final dPopToken = genDpopToken(aclFileUrl, rsaKeyPair, publicKeyJwk, 'PUT');
//     final aclFileUrl = await getResourceUrl(path.join(itemLoc, itemName));
//     final (:accessToken, :dPopToken) =
//         await getTokensForResource(aclFileUrl, 'PUT');

//     // The PUT request will create the acl item in the server.
//     print('CREATE: $aclFileUrl\n');

//     createResponse = await http.put(
//       Uri.parse(aclFileUrl),
//       headers: <String, String>{
//         'Accept': '*/*',
//         'Authorization': 'DPoP $accessToken',
//         'Connection': 'keep-alive',
//         'Content-Type': 'text/turtle',
//         'Content-Length': itemBody.length.toString(),
//         'DPoP': dPopToken,
//       },
//       body: itemBody,
//     );
//   } else {
//     final (:accessToken, :dPopToken) =
//         await getTokensForResource(resourceUrl, 'POST');

//     // The POST request will create the item in the server.

//     print('CREATE: $resourceUrl');
//     print('SLUG  : $itemSlug\n');

//     createResponse = await http.post(
//       Uri.parse(resourceUrl),
//       headers: <String, String>{
//         'Accept': '*/*',
//         'Authorization': 'DPoP $accessToken',
//         'Connection': 'keep-alive',
//         'Content-Type': contentType,
//         'Link': itemType,
//         'Slug': itemSlug,
//         'DPoP': dPopToken,
//       },
//       body: itemBody,
//     );
//   }

//   // if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
//   //   // If the server did return a 200 OK response,
//   //   // then parse the JSON.
//   //   return 'ok';
//   // } else {
//   if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
//     // If the server did not return a 200 OK response,
//     // then throw an exception.
//     throw Exception('Failed to create resource! Try again in a while.');
//   }
// }

/// Delete a file or a directory
Future<void> deleteItem(bool fileFlag, String itemLoc) async {
  // Set up file (resource) or directory (container) parameters
  final contentType = fileFlag ? 'text/turtle' : 'application/octet-stream';

  // String encKeyUrl = webId!.replaceAll(profCard, itemLoc);
  // String dPopToken =
  //     genDpopToken(encKeyUrl, rsaKeyPair, publicKeyJwk, 'DELETE');

  final resourceUrl =
      fileFlag ? await getFileUrl(itemLoc) : await getDirUrl(itemLoc);
  final (:accessToken, :dPopToken) =
      await getTokensForResource(resourceUrl, 'DELETE');

  final createResponse = await http.delete(
    Uri.parse(resourceUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': contentType,
      'DPoP': dPopToken,
    },
  );

  // if (createResponse.statusCode == 200 || createResponse.statusCode == 205) {
  //   // If the server did return a 200 OK response,
  //   // then parse the JSON.
  //   return 'ok';
  // } else {
  if (createResponse.statusCode != 200 && createResponse.statusCode != 205) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to delete file! Try again in a while.');
  }
}

/// Enum of resource status
enum ResourceStatus {
  /// The resource exist
  exist,

  /// The resource does not exist
  notExist,

  /// Do not know if the resource exist (e.g. error occurred when checking the status)
  unknown
}

/// Asynchronously checks whether a given resource exists on the server.
///
/// This function makes an HTTP GET request to the specified resource URL to determine if the resource exists.
/// It handles both files and directories (containers) by setting appropriate headers based on the [fileFlag].

Future<ResourceStatus> checkResourceExists(String resUrl, bool fileFlag) async {
  String contentType;
  String itemType;
  if (fileFlag) {
    contentType = '*/*';
    itemType = fileTypeLink;
  } else {
    /// This is a directory (container)
    contentType = dirContentType;
    itemType = dirTypeLink;
  }

  final (:accessToken, :dPopToken) = await getTokensForResource(resUrl, 'GET');
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
    return ResourceStatus.exist;
  } else if (response.statusCode == 404) {
    // If the server did not return a 200 OK response,
    // then return false.
    return ResourceStatus.notExist;
  } else {
    return ResourceStatus.unknown;
  }
}

/// Updates a file on the server with the provided SPARQL query.
///
/// This asynchronous function sends a PATCH request to the server, targeting
/// the file specified by [fileUrl]. It uses SPARQL (a query language for RDF data)
/// to perform the update operation. This function is typically used in scenarios
/// where RDF data stored on a Solid POD (Personal Online Datastore) needs to be
/// modified.

Future<void> updateFileByQuery(
  String fileUrl,
  String query,
) async {
  final (:accessToken, :dPopToken) =
      await getTokensForResource(fileUrl, 'PATCH');
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

  // if (editResponse.statusCode == 200 || editResponse.statusCode == 205) {
  //   // If the server did return a 200 OK response,
  //   // then parse the JSON.
  //   return 'ok';
  // } else {
  if (editResponse.statusCode != 200 && editResponse.statusCode != 205) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to write profile data! Try again in a while.');
  }
}

/// TODO:
/// The predicates looks specific to podnotes, this likely needs to be updated.
///
/// Updates an individual key file with encrypted session key information.
///
/// This asynchronous function is responsible for updating the key file located
/// at a user's Solid POD (Personal Online Datastore) with new encrypted session
/// key data. The function performs various checks and updates the file only if
/// necessary to avoid redundant operations.

Future<void> updateIndKeyFile(
  String webId,
  Map<dynamic, dynamic> authData,
  String resName,
  String encSessionKey,
  String encNoteFilePath,
  String encNoteIv,
  String appName,
) async {
  // var createUpdateRes = '';

  const encDir = 'encryption';

  final encDirLoc = '$appName/$encDir';

  // Get indi key file url.

  final keyFileUrl = webId.contains(profCard)
      ? webId.replaceAll(profCard, '$encDirLoc/$indKeyFile')
      : '$webId/$encDirLoc/$indKeyFile';

  // final rsaInfo = authData['rsaInfo'];
  // final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  // final publicKeyJwk = rsaInfo['pubKeyJwk'];
  // final accessToken = authData['accessToken'].toString();

  final notesFile = '$webId/predicates/file#';
  final notesTerms = '$webId/predicates/terms#';

  // Update the file.
  // First check if the file already contain the same value.

  // final dPopTokenKeyFile =
  //     genDpopToken(keyFileUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'GET');
  final keyFileContent = await fetchPrvFile(keyFileUrl);
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

      // final dPopTokenKeyFilePatch =
      //     genDpopToken(keyFileUrl, rsaKeyPair, publicKeyJwk, 'PATCH');

      // Run the query.

      // createUpdateRes =
      await updateFileByQuery(keyFileUrl, query);
    } else {
      // If the file contain same values, then no need to run anything.
      // createUpdateRes = 'ok';
    }
  } else {
    // Generate insert only sparql query.

    final query =
        'PREFIX $prefix1 PREFIX $prefix2 INSERT DATA {$subject $predObjPath $predObjIv $predObjKey};';

    // Generate DPoP token.

    // final dPopTokenKeyFilePatch =
    //     genDpopToken(keyFileUrl, rsaKeyPair, publicKeyJwk, 'PATCH');

    // Run the query.

    // createUpdateRes =
    await updateFileByQuery(keyFileUrl, query);
  }

  // if (createUpdateRes == 'ok') {
  //   return createUpdateRes;
  // } else {
  //   throw Exception('Failed to create/update the shared file.');
  // }
}

// Updates the initial profile data on the server.
///
/// This function sends a PUT request to update the user's profile information. It constructs the profile URL from the provided `webId`, generates a DPoP token using the RSA key pair and public key in JWK format from `authData`, and then sends the request with the `profBody` as the payload.
///
/// The `authData` map must contain `rsaInfo` (which includes `rsa` key pair and `pubKeyJwk`) and an `accessToken`. The function modifies the `webId` URL to target the appropriate resource on the server.
///
/// Throws an Exception if the server does not return a 200 OK or 205 Reset Content response, indicating a failure in updating the profile.

Future<void> initialProfileUpdate(String profBody) async {
  final webId = await getWebId();
  assert(webId != null);
  final profUrl = webId!.replaceAll('#me', '');
  // final dPopToken =
  //     genDpopToken(profUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'PUT');

  final (:accessToken, :dPopToken) = await getTokensForResource(profUrl, 'PUT');

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

  // if (updateResponse.statusCode == 200 || updateResponse.statusCode == 205) {
  //   // If the server did return a 205 Reset response,
  //   return 'ok';
  // } else {
  if (updateResponse.statusCode != 200 && updateResponse.statusCode != 205) {
    // If the server did not return a 205 response,
    // then throw an exception.
    throw Exception('Failed to update resource! Try again in a while.');
  }
}

/// TODO:
/// keypod is hard-coded in the keyFileUrl, this likely needs to be updated.
///
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

  final keyData = await fetchPrvFile(keyFileUrl);

  return keyData;
}

/// Get tokens necessary to fetch a resource from a POD
///
/// returns the access token and DPoP token

Future<({String accessToken, String dPopToken})> getTokensForResource(
    String resourceUrl, String httpMethod) async {
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  final rsaInfo = authData!['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'] as KeyPair;
  final publicKeyJwk = rsaInfo['pubKeyJwk'];

  return (
    accessToken: authData['accessToken'] as String,
    dPopToken: genDpopToken(resourceUrl, rsaKeyPair, publicKeyJwk, httpMethod),
  );
}

/// Get the list of sub-containers and files in a container
/// Adapted from getContainerList() in
/// gurriny/indi/lib/models/common/rest_api.dart
Future<({List<String> subDirs, List<String> files})> getResourcesInContainer(
    String containerUrl) async {
  // The trailing "/" is essential for a directory
  final url = containerUrl.endsWith(path.separator)
      ? containerUrl
      : containerUrl + path.separator;

  final (:accessToken, :dPopToken) = await getTokensForResource(url, 'GET');

  final profResponse = await http.get(
    Uri.parse(url),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'DPoP': dPopToken,
    },
  );

  if (profResponse.statusCode == 200) {
    // print(profResponse.body.runtimeType); // String

    // NB: rdflib-0.2.8 (dart) is not able to parse this but
    //     rdflib-7.0.0 (python) can parse it
    //
    // final g = Graph();
    // g.parseTurtle(profResponse.body);

    final (:subDirs, :files) = _parseGetContainerResponse(profResponse.body);

    // print('SubDirs: |${subDirs.join(", ")}|');
    // print('Files  : |${files.join(", ")}|');

    return (subDirs: subDirs, files: files);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to get resource list.');
  }
}

/// A heuristic to parse the response body of a request getting the list of
/// resources in a container.
/// This heuristic is a temporary solution before rdflib (dart) is capable
/// of parsing the response body.
({List<String> subDirs, List<String> files}) _parseGetContainerResponse(
    String responseBody) {
  final containers = <String>[];
  final files = <String>[];
  final re = RegExp('^<[^>]+>'); // starts with <, ends with >, no > in between

  final lines = responseBody.split('\n');
  for (var l in lines) {
    if (l.startsWith('<') && !l.startsWith('<>')) {
      if (l.contains('ldp:Resource')) {
        final name = re.firstMatch(l)?.group(0);
        assert(name != null);
        if (l.contains('ldp:Container')) {
          containers.add(name!.substring(1, name.length - 2)); // <NAME/>
        } else {
          files.add(name!.substring(1, name.length - 1)); // <NAME>
        }
      }
    }
  }
  return (subDirs: containers, files: files);
}
