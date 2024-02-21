/// Model layer of setting page, including basic CRUD HTTPS connections
/// to a specific POD.
///
/// Copyright 2023, Software Innovation Institute, ANU.
///
/// License: http://www.apache.org/licenses/LICENSE-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///
/// Authors: Ye Duan (Diabete's app), Kevin Wang

import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart';
import 'package:solid_auth/solid_auth.dart';

class HomePageNet {
  /// this method is to update a file
  /// @param fileURI - the uri of a file users would like to read in a pod
  ///        accessToken - the access token parsed from authentication data
  ///        after login
  ///        rsa - rsaKeyPair to help generate dPopToken
  ///        pubKeyJwk - pubKeyJwk to help generate dPopToken
  ///        content - the content String to edit the specific file
  /// @return void
  Future<void> updateFile(
    String fileURI,
    String accessToken,
    KeyPair rsaKeyPair,
    dynamic publicKeyJwk,
    String content,
  ) async {
    String dPopToken = genDpopToken(fileURI, rsaKeyPair, publicKeyJwk, 'PUT');
    Response response = await put(
      Uri.parse(fileURI),
      headers: <String, String>{
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': 'text/plain',
        'Content-Length': content.length.toString(),
        'DPoP': dPopToken,
      },
      body: content,
    );
    if (response.statusCode != 200 && response.statusCode != 205) {
      throw Exception('Error on updating a file');
    }
  }

  /// this method is to create a new file in the root directory of a POD
  /// @param containerURI - the uri of a container you would like to create your file in
  ///        accessToken - the access token parsed from authentication data after login
  ///        rsa - rsaKeyPair to help generate dPopToken
  ///        pubKeyJwk - pubKeyJwk to help generate dPopToken
  ///        fileName - the name of your new file
  /// @return void
  Future<void> touch(
    String containerURI,
    String accessToken,
    KeyPair rsaKeyPair,
    dynamic pubKeyJwk,
    String fileName,
  ) async {
    String dPopToken =
        genDpopToken(containerURI, rsaKeyPair, pubKeyJwk, 'POST');

    Response response = await post(
      Uri.parse(containerURI),
      headers: <String, String>{
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': 'text/turtle',
        'DPoP': dPopToken,
        'Link': '<http://www.w3.org/ns/ldp#Resource>; rel="type"',
        'Slug': fileName,
      },
    );
    if (response.statusCode != 201) {
      throw Exception('Error on creating a file');
    }
  }

  /// this method is to create a new container in the root directory of a POD
  /// @param rootURI - the uri of a root directory of a POD
  ///        accessToken - the access token parsed from authentication data after login
  ///        rsa - rsaKeyPair to help generate dPopToken
  ///        pubKeyJwk - pubKeyJwk to help generate dPopToken
  ///        containerName - the name of your new container (folder)
  /// @return void
  Future<void> mkdir(
    String rootURI,
    String accessToken,
    KeyPair rsaKeyPair,
    dynamic publicKeyJwk,
    String containerName,
  ) async {
    String dPopToken = genDpopToken(rootURI, rsaKeyPair, publicKeyJwk, 'POST');
    Response response = await post(
      Uri.parse(rootURI),
      headers: <String, String>{
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': 'text/turtle',
        'DPoP': dPopToken,
        'Link': '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"',
        'Slug': containerName,
      },
    );
    if (response.statusCode != 201) {
      throw Exception('Error on creating a directory');
    }
  }
}
