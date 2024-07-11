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
/// Authors: Zheyuan Xu, Anushka Vidanage, Dawei Chen

// ignore_for_file: comment_references

library;

import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:http/http.dart' as http;
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Parse encrypted file content and extract into a map.
///
/// This function returns a map of encrypted file content
/// where keys are subject values and values are
/// predicate and object values.

Map<dynamic, dynamic> getEncFileContent(String fileInfo) {
  final g = Graph();
  g.parseTurtle(fileInfo);
  final fileContentMap = {};
  for (final t in g.triples) {
    /**
     * Use
     *  - t.sub -> Subject
     *  - t.pre -> Predicate
     *  - t.obj -> Object
     */
    final predicate = t.pre.value as String;
    if (predicate.contains('#')) {
      final subject = t.sub.value;
      final fileName = subject.split('#')[1];
      final attributeName = predicate.split('#')[1];
      final attrVal = t.obj.value;
      if (attributeName != 'type') {
        if (fileContentMap.containsKey(fileName)) {
          fileContentMap[fileName][attributeName] = attrVal;
        } else {
          fileContentMap[fileName] = {attributeName: attrVal};
        }
      }
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
    // return profResponse.bodyBytes;
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
    if (await checkResourceStatus(resourceUrl, fileFlag: false) ==
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
      if (await checkResourceStatus(resourceUrl, fileFlag: false) ==
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
    {dynamic content = '',
    bool fileFlag = true,
    bool replaceIfExist = true,
    ResourceContentType contentType = ResourceContentType.turtleText}) async {
  // Sanity check
  if (fileFlag) {
    assert(!resourceUrl.endsWith('/'));
  } else {
    assert(resourceUrl.endsWith('/'));
    assert(contentType == ResourceContentType.directory);
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
      'Content-Type': contentType.value,
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

/// Delete a file or a directory
Future<void> deleteResource(
    String resourceUrl, ResourceContentType contentType) async {
  final (:accessToken, :dPopToken) =
      await getTokensForResource(resourceUrl, 'DELETE');

  final response = await http.delete(
    Uri.parse(resourceUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': contentType.value,
      'DPoP': dPopToken,
    },
  );

  if (response.statusCode != 200 && response.statusCode != 205) {
    throw Exception('Failed to delete resource!'
        '\nURL: $resourceUrl'
        '\nERROR: ${response.body}');
  }
}

/// Asynchronously checks whether a given resource exists on the server.
///
/// This function makes an HTTP GET request to the specified resource URL to determine if the resource exists.
/// It handles both files and directories (containers) by setting appropriate headers based on the [fileFlag].

Future<ResourceStatus> checkResourceStatus(String resUrl,
    {bool fileFlag = true}) async {
  final (:accessToken, :dPopToken) = await getTokensForResource(resUrl, 'GET');
  final response = await http.get(
    Uri.parse(resUrl),
    headers: <String, String>{
      'Content-Type': fileFlag
          ? ResourceContentType.any.value
          : ResourceContentType.directory.value,
      'Authorization': 'DPoP $accessToken',
      'Link': fileFlag ? fileTypeLink : dirTypeLink,
      'DPoP': dPopToken,
    },
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    return ResourceStatus.exist;
  } else if (response.statusCode == 404) {
    return ResourceStatus.notExist;
  } else {
    debugPrint('Failed to check resource status.\n'
        'URL: $resUrl\n'
        'ERR: ${response.body}');
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

  if (editResponse.statusCode != 200 && editResponse.statusCode != 205) {
    throw Exception('Failed to write profile data! Try again in a while.');
  }
}

// Updates the initial profile data on the server.
///
/// This function sends a PUT request to update the user's profile information. It constructs the profile URL from the provided `webId`, generates a DPoP token using the RSA key pair and public key in JWK format from `authData`, and then sends the request with the `profBody` as the payload.
///
/// The `authData` map must contain `rsaInfo` (which includes `rsa` key pair and `pubKeyJwk`) and an `accessToken`. The function modifies the `webId` URL to target the appropriate resource on the server.
///
/// Throws an Exception if the server does not return a 200 OK or 205 Reset Content response, indicating a failure in updating the profile.

Future<void> initialProfileUpdate(String profBody) async {
  final webId = await AuthDataManager.getWebId();
  assert(webId != null);
  final profUrl = webId!.replaceAll('#me', '');

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

  if (updateResponse.statusCode != 200 && updateResponse.statusCode != 205) {
    throw Exception('Failed to update resource! Try again in a while.');
  }
}

/// Get the resource with URL [resourceUrl] from server.
/// The resource could be a text, turtle, binary file.
/// If [resourceUrl] ends with '/', i.e., a container / directory,
/// This function returns the bytes of a turtle string representing
/// the list of resources in the container / directory.
Future<Uint8List> getResource(String resourceUrl) async {
  final (:accessToken, :dPopToken) =
      await getTokensForResource(resourceUrl, 'GET');

  final response = await http.get(
    Uri.parse(resourceUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'DPoP': dPopToken,
    },
  );

  if (response.statusCode == 200) {
    debugPrint('Response status: ${response.statusCode}');
    // debugPrint('Response body: ${response.body}');
    return response.bodyBytes;
  } else {
    throw Exception('Failed to get resource $resourceUrl');
  }
}

/// Get the list of sub-containers and files in a container
/// Adapted from getContainerList() in
/// gurriny/indi/lib/models/common/rest_api.dart
Future<({List<String> subDirs, List<String> files})> getResourcesInContainer(
    String containerUrl) async {
  // The trailing "/" is essential for a directory
  final url = containerUrl.endsWith('/') ? containerUrl : '$containerUrl/';

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
    debugPrint(profResponse.body.runtimeType as String); // String

    // NB: rdflib-0.2.8 (dart) is not able to parse this but
    //     rdflib-7.0.0 (python) can parse it
    //
    // final g = Graph();
    // g.parseTurtle(profResponse.body);

    final (:subDirs, :files) = _parseGetContainerResponse(profResponse.body);

    debugPrint('SubDirs: |${subDirs.join(", ")}|');
    debugPrint('Files  : |${files.join(", ")}|');

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
  for (final l in lines) {
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

/// Check if a file is encrypted
Future<bool> checkFileEnc(String fileUrl) async =>
    KeyManager.hasIndividualKey(fileUrl);

/// Update ACL file of a resource by http put request
///
/// The request will replace the content in ACL file
/// Returns a string 'ok' upon successful content update
Future<String> updateAclFileContent(
    String resourceUrl, String aclFileContent) async {
  // Get acl file url
  final resourceAclUrl = getResAclFile(resourceUrl);

  final (:accessToken, :dPopToken) =
      await getTokensForResource(resourceAclUrl, 'PUT');

  // http request to update the acl file on the server
  final editResponse = await http.put(
    Uri.parse(resourceAclUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': 'text/turtle',
      'Content-Length': aclFileContent.length.toString(),
      'DPoP': dPopToken,
    },
    body: aclFileContent,
  );

  if (editResponse.statusCode == 201 || editResponse.statusCode == 205) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return 'ok';
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to write profile data! Try again in a while.');
  }
}
