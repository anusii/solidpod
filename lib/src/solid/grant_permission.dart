/// Function to grant permission to a private file in a POD.
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
/// Authors: Anushka Vidanage

// ignore_for_file: use_build_context_synchronously

library;

import 'dart:core';

import 'package:flutter/material.dart' hide Key;

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/common_func.dart';
import 'package:solidpod/src/solid/utils/key_management.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Grant permission to [resourceUrl] for a given [receiverWebId].
/// Parameters:
///   [resourceUrl] is the path of the file in the POD including the file name
///   [permissionList] is the list of permission to be granted
///   [receiverWebId] is the webId of the permission receiver
///   [isFileEncrypted] is the flag to determine if the file is encrypted or not

Future<void> grantPermission(
    String resourceUrl,
    List<dynamic> permissionList,
    String receiverWebId,
    bool isFileEncrypted,
    BuildContext context,
    Widget child) async {
  await loginIfRequired(context);

  await getKeyFromUserIfRequired(context, child);

  // Add the permission line to the relevant ACL file
  await setPermissionAcl(resourceUrl, receiverWebId, permissionList);

  // Check if the file is encrypted
  final fileIsEncrypted = await checkFileEnc(resourceUrl);

  // If the file is encrypted then share the individual encryption key
  // with the receiver
  if (fileIsEncrypted) {
    // Get user's security key.
    // final secureKey = await getSecureKeyPlain(secureKeyObject, webId);
    // final encKey =
    //     sha256.convert(utf8.encode(secureKey)).toString().substring(0, 32);

    // /// Get the individual security key for the file
    // final indKey = await KeyManager.getIndividualKey(resourceUrl);

    // final indKeyFileLoc =
    //     webId.replaceAll('profile/card#me', IND_KEY_FILE_LOC);
    // final dPopTokenKeyFile =
    //     genDpopToken(indKeyFileLoc, rsaKeyPair, publicKeyJwk, 'GET');
    // final keyFileContent =
    //     await fetchPrvData(indKeyFileLoc, accessToken, dPopTokenKeyFile);
    // final keyFileDataMap = getEncFileContent(keyFileContent);

    // //String filePath = keyFileDataMap[resourceName]['path'];
    // final String fileKeyInd =
    //     keyFileDataMap['indEncFile-$resourceName']['indKey'];

    // /// Decrypt the individual key using master key
    // final masterKey = encrypt.Key.fromUtf8(encKey);
    // final ivInd = encrypt.IV
    //     .fromBase64(keyFileDataMap['indEncFile-$resourceName']['ivz']);
    // final encrypterInd = encrypt.Encrypter(
    //     encrypt.AES(masterKey, mode: encrypt.AESMode.cbc));
    // final eccInd = encrypt.Encrypted.from64(fileKeyInd);
    // final plainKeyInd = encrypterInd.decrypt(eccInd, iv: ivInd);

    // /// Get recipient's public key
    // var otherPubKey = await fetchOtherPubKey(authData, permissionWebId);
    // otherPubKey = otherPubKey.replaceAll('"', '');
    // otherPubKey = genPubKeyStr(otherPubKey);

    // /// Encrypt individual key, file path, and access list using recipient's public key
    // final parser = encrypt.RSAKeyParser();
    // final pubKey = parser.parse(otherPubKey) as RSAPublicKey;
    // final encrypterPub = encrypt.Encrypter(encrypt.RSA(publicKey: pubKey));
    // final encShareKey = encrypterPub.encrypt(plainKeyInd).base64;
    // final encSharePath = encrypterPub.encrypt(resourceUrl).base64;

    // selectedItems.sort();
    // final accessListStr = selectedItems.join(',');
    // final encSharedAccess = encrypterPub.encrypt(accessListStr).base64;

    // /// Get username to create a directory
    // final List webIdContent = webId.split('/');
    // final String dirName = webIdContent[3];
  }
}
