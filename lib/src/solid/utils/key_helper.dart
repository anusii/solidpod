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
import 'package:rdflib/rdflib.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;

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

/// Get full predicate URL
String _getPred(String pred) => solidTermsNS.ns.withAttr(pred).value;

/// Read file `encryption/enc-keys.ttl' to get verification key and encrypted private key
Future<({String verificationKey, PrvKeyRecord record})> readEncKeyFile() async {
  final encKeyUrl = await getFileUrl(await getEncKeyPath());

  final tripleMap = turtleToTripleMap(
    utf8.decode(
      await getResource(encKeyUrl),
    ),
  );

  if (!tripleMap.containsKey(encKeyUrl)) {
    throw Exception('Invalid content in file: "$encKeyUrl"');
  }
  assert(tripleMap.length == 1);

  dynamic getVal(String pred) => tripleMap[encKeyUrl]![_getPred(pred)];

  _checkDuplicatedValue(
    value: getVal(encKeyPred),
    errMsg: 'ERROR: Duplicated verification key',
  );
  final verificationKey = getVal(encKeyPred) as String;

  final prvKeyRecord = PrvKeyRecord(
    encKeyBase64: getVal(prvKeyPred) as String,
    ivBase64: getVal(ivPred) as String,
  );

  return (verificationKey: verificationKey, record: prvKeyRecord);
}

/// Read file `encryption/ind-keys.ttl' to get encrypted individual keys
Future<Map<String, IndKeyRecord>> readIndKeyFile() async {
  final indKeyUrl = await getFileUrl(await getIndKeyPath());
  final indKeyMap = <String, IndKeyRecord>{};

  final tripleMap = turtleToTripleMap(
    utf8.decode(
      await getResource(indKeyUrl),
    ),
  );

  dynamic getVal(Map<String, dynamic> map, String pred) => map[_getPred(pred)];

  for (final entry in tripleMap.entries) {
    // `k' is changed from a URL to a relative path in new version of CSS (e.g v7.1.7)
    // if triples are inserted using SPARQL queries.
    final k = entry.key;
    final v = entry.value;
    if (v.containsKey(_getPred(sessionKeyPred))) {
      _checkDuplicatedValue(
        value: getVal(v, sessionKeyPred),
        errMsg: 'ERROR: Duplicated encryption key for resource "$k"',
      );
      _checkDuplicatedValue(
        value: getVal(v, ivPred),
        errMsg: 'ERROR: Duplicated IV for resource "$k"',
      );
      _checkDuplicatedValue(
        value: getVal(v, pathPred),
        errMsg: 'ERROR: Duplicated path for resource "$k"',
      );

      // Use resource URL as key instead of relative path (in new version of CSS)
      indKeyMap[await getFileUrl(getVal(v, pathPred) as String)] = IndKeyRecord(
        encKeyBase64: getVal(v, sessionKeyPred) as String,
        ivBase64: getVal(v, ivPred) as String,
        resourcePath: getVal(v, pathPred) as String,
      );
    }
  }

  return indKeyMap;
}

/// Read file `sharing/public-key.ttl' to get the public key
Future<String> readPubKeyFile() async {
  final pubKeyUrl = await getFileUrl(await getPubKeyPath());

  // Get and parse the pubKeyFile
  // final map = await loadPrvTTL(pubKeyUrl);

  final tripleMap = turtleToTripleMap(
    utf8.decode(
      await getResource(pubKeyUrl),
    ),
  );

  if (!tripleMap.containsKey(pubKeyUrl)) {
    throw Exception('Invalid content in file: "$pubKeyUrl"');
  }
  assert(tripleMap.length == 1);

  dynamic getVal(String pred) => tripleMap[pubKeyUrl]![_getPred(pred)];

  _checkDuplicatedValue(
    value: getVal(pubKeyPred),
    errMsg: 'ERROR: Duplicated public key',
  );

  final pubKey = getVal(pubKeyPred) as String;
  return pubKey;
}

/// Read file `shared/shared-keys.ttl` to get encrypted individual keys
/// of shared resources.
Future<Map<String, SharedIndKeyRecord>> readSharedIndKey(
  String privateKey,
) async {
  final sharedIndKeyUrl = await getFileUrl(await getSharedKeyFilePath());
  final sharedIndKeyMap = <String, SharedIndKeyRecord>{};
  Encrypter? encrypter;

  final tripleMap = turtleToTripleMap(
    utf8.decode(
      await getResource(sharedIndKeyUrl),
    ),
  );

  // shared-keys.ttl seems to use predicates defined in a different space
  // compared to enc-key.ttl and ind-keys.ttl

  String getPred(String pred) => '$appsData$pred';

  dynamic getVal(Map<String, dynamic> map, String pred) => map[getPred(pred)];

  for (final entry in tripleMap.entries) {
    final v = entry.value;
    if (v.containsKey(getPred(sharedKeyPred))) {
      encrypter ??= Encrypter(
        RSA(
          privateKey: RSAKeyParser().parse(privateKey) as RSAPrivateKey,
        ),
      );

      sharedIndKeyMap[encrypter.decrypt64(getVal(v, pathPred) as String)] =
          SharedIndKeyRecord(
        encResourcePath: getVal(v, pathPred) as String,
        encAccessList: getVal(v, accessListPred) as String,
        encKey: getVal(v, sharedKeyPred) as String,
      );
    }
  }
  return sharedIndKeyMap;
}

/// SPARQL operations used for adding / deleting individual keys.
enum SparqlOperation {
  insert('INSERT'),
  delete('DELETE');

  /// String value representing the key
  final String _value;
  String get value => _value;

  /// Generative enum constructor
  const SparqlOperation(this._value);
}

/// Generate the SPARQL query to insert/delete the encrypted individual key
/// and the corresponding IV of a resource.
Future<String> getIndKeyQuery(
  IndKeyRecord indKeyRecord, {
  required SparqlOperation operation,
  bool isFile = true,
}) async {
  final sub =
      await (isFile ? getFileUrl : getDirUrl)(indKeyRecord.resourcePath);

  return '${operation.value} DATA {'
      '<$sub> <$appsTerms$pathPred> "${indKeyRecord.resourcePath}"; '
      '<$appsTerms$ivPred> "${indKeyRecord.ivBase64}"; '
      '<$appsTerms$sessionKeyPred> "${indKeyRecord.encKeyBase64}".};';
}

/// Generate the SPARQL query to delete the shared individual/session key
/// and the corresponding IV of a resource with ID [resUniqueId].
Future<String> getSharedIndKeyDeletionQuery(
  String resUniqueId,
  SharedIndKeyRecord record,
) async {
  // Define prefix and subject
  const prefix1 = '$resIdPrefix <$appsResId>';
  const prefix2 = '$dataPrefix <$appsData>';
  final subject = '$resIdPrefix$resUniqueId';

  // Define predicates and objects
  final predObjPath = '$dataPrefix$pathPred "${record.encResourcePath}";';
  final predObjAcc = '$dataPrefix$accessListPred "${record.encAccessList}";';
  final predObjKey = '$dataPrefix$sharedKeyPred "${record.encKey}".';

  // Generate delete sparql query
  return 'PREFIX $prefix1 PREFIX $prefix2 DELETE DATA {$subject $predObjPath $predObjAcc $predObjKey};';
}

// Check duplicated values
void _checkDuplicatedValue({required dynamic value, required String errMsg}) {
  if (value is Iterable && (value as List).length > 1) {
    throw Exception(errMsg);
  }
}

// Bind the long namespace to shorter string to improve readability
final _bindNS = {
  solidTermsNS.prefix: solidTermsNS.ns,
  termsNS.prefix: termsNS.ns,
};

/// Generate the content of encKeyFile
Future<String> genEncKeyTTLStr(
  String encKeyUrl,
  String verificationKey,
  PrvKeyRecord prvKeyRecord,
) async {
  final triples = {
    URIRef(encKeyUrl): {
      termsNS.ns.withAttr(titlePred): encKeyFileTitle,
      solidTermsNS.ns.withAttr(encKeyPred): verificationKey,
      solidTermsNS.ns.withAttr(ivPred): prvKeyRecord.ivBase64,
      solidTermsNS.ns.withAttr(prvKeyPred): prvKeyRecord.encKeyBase64,
    },
  };

  return tripleMapToTurtle(triples, bindNamespaces: _bindNS);
}

/// Generate the content of indKeyFile
Future<String> genIndKeyTTLStr(
  String indKeyUrl,
  Map<String, IndKeyRecord>? indKeyMap,
) async {
  final triples = <URIRef, Map<URIRef, String>>{};
  triples[URIRef(indKeyUrl)] = {
    termsNS.ns.withAttr(titlePred): indKeyFileTitle,
  };

  if (indKeyMap != null && indKeyMap.isNotEmpty) {
    for (final entry in indKeyMap.entries) {
      final resourceUrl = entry.key;
      final record = entry.value;

      final indKey = record.key;
      assert(indKey != null);

      triples[URIRef(resourceUrl)] = {
        solidTermsNS.ns.withAttr(pathPred): record.resourcePath,
        solidTermsNS.ns.withAttr(ivPred): record.ivBase64,
        solidTermsNS.ns.withAttr(sessionKeyPred): record.encKeyBase64,
      };
    }
  }

  return tripleMapToTurtle(triples, bindNamespaces: _bindNS);
}

/// Generate the content of pubKeyFile
Future<String> genPubKeyTTLStr(String pubKeyUrl, String pubKey) async {
  final triples = {
    URIRef(pubKeyUrl): {
      termsNS.ns.withAttr(titlePred): pubKeyFileTitle,
      solidTermsNS.ns.withAttr(pubKeyPred): pubKey,
    },
  };

  return tripleMapToTurtle(triples, bindNamespaces: _bindNS);
}

/// [IndKeyRecord] is a simple class to store encrypted and decrypted AES keys
/// of individual data files.

class IndKeyRecord {
  /// Constructor
  IndKeyRecord({
    required this.resourcePath,
    required this.encKeyBase64,
    required this.ivBase64,
  });

  /// The path of file or directory corresponds to the key
  final String resourcePath;

  /// The base64 string of the encrypted key
  String encKeyBase64;

  /// The base64 string of the IV
  String ivBase64;

  /// The corresponding decrypted key
  Key? key;

  @override
  String toString() => 'IndividualKeyRecord {\n'
      '    resourcePath: $resourcePath,\n'
      '    encIndKey: $encKeyBase64,\n'
      '    iv: $ivBase64\n'
      '}';
}

/// [_SharedIndKeyRecord] is a simple class to store both encrypted and
/// decrypted individual keys shared by others

class SharedIndKeyRecord {
  /// Constructor
  SharedIndKeyRecord({
    required this.encResourcePath,
    required this.encAccessList,
    required this.encKey,
  });

  /// The encrypted path of resource corresponds to the key
  final String encResourcePath;

  /// The encrypted access list
  final String encAccessList;

  /// The encrypted key string
  final String encKey;

  /// The path of resource corresponds to the key
  String? resourcePath;

  /// The access list
  String? accessList;

  /// The corresponding decrypted key
  Key? key;

  @override
  String toString() => 'SharedIndividualKeyRecord {\n'
      '    encFilePath: $resourcePath,\n'
      '    encAccessList: $accessList,\n'
      '    encKey: $key\n'
      '}';
}

/// [PrvKeyRecord] is a simple class to store encrypted and decrypted
/// private key for data sharing.

class PrvKeyRecord {
  /// Constructor
  PrvKeyRecord({required this.encKeyBase64, required this.ivBase64, this.key});

  /// The base64 string of the encrypted private key
  String encKeyBase64;

  /// The base64 string of the IV
  String ivBase64;

  /// The corresponding decrypted private key
  String? key;
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
    //final map = await loadPrvTTL(recipientPubKeyUrl);

    final tripleMap = turtleToTripleMap(
      utf8.decode(
        await getResource(recipientPubKeyUrl),
      ),
    );

    if (!tripleMap.containsKey(recipientPubKeyUrl)) {
      throw Exception('Invalid content in file: "$recipientPubKeyUrl"');
    }

    _recipientPubKeyContent =
        tripleMap[recipientPubKeyUrl]![_getPred(pubKeyPred)] as String;

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
