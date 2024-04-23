/// Initial loaded screen set up page.
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
/// Authors: Zheyuan Xu, Anushka Vidanage

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:solid_encrypt/solid_encrypt.dart' as solid_encrypt;

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';
import 'package:solidpod/src/screens/initial_setup/gen_file_body.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils.dart'
    show writeToSecureStorage, AuthDataManager, getWebId;
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/widgets/error_dialog.dart';
import 'package:solidpod/src/widgets/show_animation_dialog.dart';

/// A button to submit form widget
///
/// This function takes all the input data from the form and create all
/// required resources inside a user's POD. This includes creating several
/// directories and multiple ttl files.
///
/// At the end of the creation of resources the function will store the
/// encryption key in device local storage securely and then redirect the user
/// to the main/home page.

ElevatedButton resCreateFormSubmission(
  GlobalKey<FormBuilderState> formKey,
  BuildContext context,
  List<String> resFileNamesLink,
  List<String> resFoldersLink,
  List<String> resFilesLink,
  Widget child,
) {
  // Use MediaQuery to determine the screen width and adjust the font size accordingly.
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallDevice =
      screenWidth < 360; // A threshold for small devices, can be adjusted.

// TODO:
// This function needs refactoring to move the complex logic code into a
// separate function (i.e. the middle level code)
  return ElevatedButton(
    onPressed: () async {
      if (formKey.currentState?.saveAndValidate() ?? false) {
        // ignore: unawaited_futures
        showAnimationDialog(context, 17, 'Creating resources!', false, null);
        final formData = formKey.currentState?.value as Map;

        final passPlaintxt = formData['password'].toString();

        final webId = await getWebId();
        assert(webId != null);

        final authData = await AuthDataManager.loadAuthData();
        assert(authData != null);

        // Variable to see whether we need to update the key files. Because if
        // one file is missing we need to create asymmetric key pairs again.

        var keyVerifyFlag = true;

        // Enryption master key

        String? encMasterKeyVerify;
        String? encMasterKey;

        // Asymmetric key pair

        String? pubKey;
        String? pubKeyStr;
        String? prvKey;
        String? prvKeyHash;
        String? prvKeyIvz;

        // Create files and directories flag

        // var createFileSuccess = true;
        // var createDirSuccess = true;

        if (resFileNamesLink.contains(encKeyFile) ||
            resFileNamesLink.contains(pubKeyFile)) {
          // Generate master key

          encMasterKey = sha256
              .convert(utf8.encode(passPlaintxt))
              .toString()
              .substring(0, 32);
          encMasterKeyVerify = sha224
              .convert(utf8.encode(passPlaintxt))
              .toString()
              .substring(0, 32);

          // Generate asymmetric key pair

          final rsaKeyPair = await RSA.generate(2048);
          prvKey = rsaKeyPair.privateKey;
          pubKey = rsaKeyPair.publicKey;

          // Encrypt private key

          final key = encrypt.Key.fromUtf8(encMasterKey);
          final iv = encrypt.IV.fromLength(16);
          final encrypter =
              encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
          final encryptVal = encrypter.encrypt(prvKey, iv: iv);
          prvKeyHash = encryptVal.base64;
          prvKeyIvz = iv.base64;

          // Get public key without start and end bit

          pubKeyStr = dividePubKeyStr(pubKey);

          // TODO: update this code
          if (!resFileNamesLink.contains(encKeyFile)) {
            final encryptClient =
                solid_encrypt.EncryptClient(authData!, webId!);
            keyVerifyFlag = await encryptClient.verifyEncKey(passPlaintxt);
          }
        }

        if (!keyVerifyFlag) {
          // ignore: use_build_context_synchronously
          await showErrDialog(context, 'Wrong encode key. Please try again!');
        } else {
          try {
            for (final resLink in resFoldersLink) {
              final serverUrl = webId!.replaceAll(profCard, '');
              final resNameStr = resLink.replaceAll(serverUrl, '');
              final resName = resNameStr.split('/').last;

              // Get resource path

              final folderPath = resNameStr.replaceAll(resName, '');

              // final createDirRes =
              await createItem(false, resName, '', fileLoc: folderPath);

              // if (createDirRes != 'ok') {
              //   createDirSuccess = false;
              // }
            }

            // Create files
            for (final resLink in resFilesLink) {
              // Get base url

              final serverUrl = webId!.replaceAll(profCard, '');

              // Get resource path and name

              final resNameStr = resLink.replaceAll(serverUrl, '');

              // Get resource name

              final resName = resNameStr.split('/').last;

              // Get resource path

              final filePath = resNameStr.replaceAll(resName, '');

              var fileBody = '';

              if (resName == encKeyFile) {
                fileBody = genEncKeyBody(
                    encMasterKeyVerify!, prvKeyHash!, prvKeyIvz!, resLink);
              } else if (['$pubKeyFile.acl', '$permLogFile.acl']
                  .contains(resName)) {
                if (resName == '$permLogFile.acl') {
                  fileBody =
                      genLogAclBody(webId, resName.replaceAll('.acl', ''));
                } else {
                  fileBody = genPubFileAclBody(resName);
                }
              } else if (resName == '.acl') {
                fileBody = genPubDirAclBody();
              } else if (resName == indKeyFile) {
                fileBody = genIndKeyFileBody();
              } else if (resName == pubKeyFile) {
                fileBody = genPubKeyFileBody(resLink, pubKeyStr!);
              } else if (resName == permLogFile) {
                fileBody = genLogFileBody();
              }

              var aclFlag = false;
              if (resName.split('.').last == 'acl') {
                aclFlag = true;
              }

              // final createFileRes =
              await createItem(true, resName, fileBody,
                  fileLoc: filePath,
                  fileType: fileType[resName.split('.').last],
                  aclFlag: aclFlag);

              // if (createFileRes != 'ok') {
              //   createFileSuccess = false;
              // }
            }
          } on Exception catch (e) {
            print('Exception: $e');
          }

          // Update the profile with new information.

          // if (createFileSuccess && createDirSuccess) {
          imageCache.clear();

          // Add encryption key to the local secure storage.

          // TODO: this needs refactoring with a pair of functions
          // to load/save master password
          await writeToSecureStorage(webId!, passPlaintxt);
          // authData['keyExist'] = true;  // the master key isn't auth data
          // }

          await Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => child),
          );
        }
      }
    },
    style: ElevatedButton.styleFrom(
        foregroundColor: darkBlue,
        backgroundColor: darkBlue, // foreground
        padding: const EdgeInsets.symmetric(horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    child: Text(
      'SUBMIT',
      style: TextStyle(
        color: Colors.white,
        // Adjust the font size for small devices.
        fontSize:
            // Smaller font size for small devices.

            isSmallDevice ? 8 : 16,
      ),
      // Ensure the text does not wrap.

      overflow: TextOverflow.ellipsis,
      // Limit text to a single line.

      maxLines: 1,
    ),
  );
}
