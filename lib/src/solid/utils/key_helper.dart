/// Utilities for managing keys for data protection.
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
/// Authors: Dawei Chen, Anushka Vidanage

library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:fast_rsa/fast_rsa.dart' as fast_rsa;
import 'package:pointycastle/asymmetric/api.dart';

import 'package:solidpod/src/solid/api/rest_api.dart' show updateFileByQuery;
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart' show parseTTLMap;

/// Derive the master key from the security key
Key genMasterKey(String securityKey) => Key.fromUtf8(
      sha256.convert(utf8.encode(securityKey)).toString().substring(0, 32),
    );

/// Derive the verification key from the security key
String genVerificationKey(String securityKey) =>
    sha224.convert(utf8.encode(securityKey)).toString().substring(0, 32);

/// Verify the security key
bool verifySecurityKey(String securityKey, String verificationKey) =>
    verificationKey == genVerificationKey(securityKey);

/// Create a random individual/session key
Key genRandIndividualKey() => Key.fromSecureRandom(32);

/// Create a random intialisation vector
IV genRandIV() => IV.fromLength(16);

/// Create a random public-private key pair
Future<({String publicKey, String privateKey})> genRandRSAKeyPair() async {
  final pair = await fast_rsa.RSA.generate(2048);
  return (publicKey: pair.publicKey, privateKey: pair.privateKey);
}

/// Encrypt the private key for data sharing
String encryptPrivateKey(String privateKey, Key masterKey, IV iv) =>
    encryptData(privateKey, masterKey, iv, mode: AESMode.cbc);

/// Decrypt the (encrypted) private key for data sharing
String decryptPrivateKey(String encPrivateKey, Key masterKey, IV iv) =>
    decryptData(encPrivateKey, masterKey, iv, mode: AESMode.cbc);

/// Add the encrypted individual/session key string [encIndKey] and
/// the corresponding IV string [ivBase64] for file with path [filePath]
Future<void> addIndKey(
  String resourcePath,
  String encIndKey,
  String ivBase64, {
  bool isFile = true,
}) async {
  final sub = await (isFile ? getFileUrl : getDirUrl)(resourcePath);

  final query = 'INSERT DATA {<$sub> <$appsTerms$pathPred> "$resourcePath"; '
      '<$appsTerms$ivPred> "$ivBase64"; '
      '<$appsTerms$sessionKeyPred> "$encIndKey".};';

  final fileUrl = await getFileUrl(await getIndKeyPath());

  await updateFileByQuery(fileUrl, query);
}

/// Delete the encrypted individual/session key string [encIndKey] and
/// the corresponding IV string [ivBase64] for file with path [filePath]
Future<void> delIndKey(
  String filePath,
  String encIndKey,
  String ivBase64,
) async {
  final sub = await getFileUrl(filePath);

  final query = 'DELETE DATA {<$sub> <$appsTerms$pathPred> "$filePath"; '
      '<$appsTerms$ivPred> "$ivBase64"; '
      '<$appsTerms$sessionKeyPred> "$encIndKey".};';

  final fileUrl = await getFileUrl(await getIndKeyPath());

  await updateFileByQuery(fileUrl, query);
}

/// Delete the shared individual/session key string [sharedKey] and
/// the corresponding file path [filePath] and access list [accessList]
Future<void> delSharedIndKey(
  String resUniqueId,
  String sharedKey,
  String filePath,
  String accessList,
) async {
  // Define prefix and subject
  const prefix1 = '$resIdPrefix <$appsResId>';
  const prefix2 = '$dataPrefix <$appsData>';
  final subject = '$resIdPrefix$resUniqueId';

  // Define predicates and objects
  final predObjPath = '$dataPrefix$pathPred "$filePath";';
  final predObjAcc = '$dataPrefix$accessListPred "$accessList";';
  final predObjKey = '$dataPrefix$sharedKeyPred "$sharedKey".';

  // Generate delete sparql query
  final query =
      'PREFIX $prefix1 PREFIX $prefix2 DELETE DATA {$subject $predObjPath $predObjAcc $predObjKey};';

  final fileUrl = await getFileUrl(await getSharedKeyFilePath());

  await updateFileByQuery(fileUrl, query);
}

/// Check duplicated values
void checkDuplicatedValue({required dynamic value, required String errMsg}) {
  if (value is Iterable && (value as List).length > 1) {
    throw Exception(errMsg);
  }
}

/// [RecipientPubKey] is a class to store public keys of another POD.
/// This public key is used to share encrypted data to this POD

class RecipientPubKey {
  /// Constructor
  RecipientPubKey({required this.recipientWebId});

  /// The webId of the recipient
  String recipientWebId;

  /// The content of the public key
  String? _recipientPubKeyContent;

  /// The public key with prefix and suffix
  RSAPublicKey? _recipientPubKey;

  /// Public key encrypter
  Encrypter? _encrypter;

  /// Get the public key
  Future<RSAPublicKey> getPubKey() async {
    if (_recipientPubKey == null) {
      await _setPubKey();
    }

    return _recipientPubKey!;
  }

  /// Get the public key content
  Future<String> getPubKeyContent() async {
    if (_recipientPubKeyContent == null) {
      await _setPubKey();
    }

    return _recipientPubKeyContent!;
  }

  /// Set the public key
  Future<void> _setPubKey() async {
    /// Get recipient's public key
    final recipientPubKeyUrl =
        recipientWebId.replaceAll(profCard, await getPubKeyPath());

    // Get and parse the pubKeyFile
    final map = await loadPrvTTL(recipientPubKeyUrl);

    if (!map.containsKey(recipientPubKeyUrl)) {
      throw Exception('Invalid content in file: "$recipientPubKeyUrl"');
    }

    _recipientPubKeyContent = map[recipientPubKeyUrl][pubKeyPred] as String;

    final recipientPubKeyStr = genPubKeyStr(_recipientPubKeyContent as String);

    final parser = RSAKeyParser();
    _recipientPubKey = parser.parse(recipientPubKeyStr) as RSAPublicKey;
    _encrypter = Encrypter(RSA(publicKey: _recipientPubKey!));
  }

  /// Encrypt a given value using public key
  Future<String> encryptData(String dataVal) async {
    if (_recipientPubKey == null || _encrypter == null) {
      await _setPubKey();
    }
    return _encrypter!.encrypt(dataVal).base64;
  }
}

/// Returns true if there is an individual key for a given resource
bool hasInheritedKey(String fileContent, String fileUrl) {
  final dataMap = parseTTLMap(fileContent);
  return dataMap.containsKey(fileUrl) &&
      dataMap[fileUrl].containsKey('$appsTerms$inheritancePred');
}
