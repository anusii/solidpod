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
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' hide Hmac;
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:fast_rsa/fast_rsa.dart' as fast_rsa;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/data_encryption.dart';
import 'package:solidpod/src/solid/utils/get_url_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;

/// Generates a public key block from a given key content.
String genPubKeyStr(String pubKeyContent) =>
    '''-----BEGIN RSA PUBLIC KEY-----\n$pubKeyContent\n-----END RSA PUBLIC KEY-----''';

/// Get unique bit of the webId
String getUniqueStrWebId(String webId) {
  var uniqueStr = webId.replaceAll('https://', '');
  uniqueStr = uniqueStr.replaceAll('http://', '');
  uniqueStr = uniqueStr.replaceAll('/$profCard', '');
  uniqueStr = uniqueStr.replaceAll('/', '-');

  return uniqueStr;
}

/// The current key-derivation scheme version.
///
/// Version 1 (legacy): master key = `sha256(securityKey)`, verification key =
/// `sha224(securityKey)` — no salt, no work factor (see [genLegacyMasterKey]
/// and [genLegacyVerificationKey]).
///
/// Version 2: a single salted Argon2id run is HKDF-expanded into two
/// domain-separated outputs — the AES master key and the verification value
/// (see [deriveKeys]). The version is stored alongside the keys in
/// `encryption/enc-keys.ttl` so existing PODs can be detected and migrated.
const int kdfVersion = 2;

/// Generate random salt
List<int> generateSalt() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256));
}

/// Derive the master key and verification value from the security key.
///
/// Runs Argon2id once (the expensive, salted step) to obtain a master secret,
/// then HKDF-expands it into two domain-separated outputs: the AES-256 master
/// key and the verification value stored on the POD. Because the two outputs
/// use distinct `info` labels, the stored verification value reveals nothing
/// about the master key, and brute-forcing it costs a full Argon2id run per
/// guess.
Future<({Key masterKey, String verificationKey})> deriveKeys(
  String securityKey,
  List<int> salt,
) async {
  final argon2 = Argon2id(
    parallelism: 4,
    memory: 10000, // 10,000 x 1kB = 10 MB
    iterations: 1, // raise memory instead of iterations for better security
    hashLength: 32, // 32 bytes = AES-256
  );

  final masterSecret = await argon2.deriveKeyFromPassword(
    password: securityKey,
    nonce: salt,
  );

  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  // The salt is reused as the HKDF nonce (this implementation requires a
  // non-empty nonce). Domain separation between the two outputs comes from
  // the distinct `info` labels, not the nonce.
  final mk = await hkdf.deriveKey(
    secretKey: masterSecret,
    nonce: salt,
    info: utf8.encode('solidpod/v2/master-key'),
  );
  final vk = await hkdf.deriveKey(
    secretKey: masterSecret,
    nonce: salt,
    info: utf8.encode('solidpod/v2/verification'),
  );

  return (
    // Full 32 bytes => true 256-bit AES key.
    masterKey: Key(Uint8List.fromList(await mk.extractBytes())),
    verificationKey: base64.encode(await vk.extractBytes()),
  );
}

/// Derive the master key from the security key using the legacy (version 1)
/// scheme: plain `sha256` truncated to 32 hex chars.
///
/// Retained only to decrypt keys on PODs created before the version 2 scheme
/// so they can be migrated. Do NOT use for new keys.
Key genLegacyMasterKey(String securityKey) => Key.fromUtf8(
      sha256.convert(utf8.encode(securityKey)).toString().substring(0, 32),
    );

/// Derive the verification key from the security key using the legacy
/// (version 1) scheme: plain `sha224` truncated to 32 hex chars.
///
/// Retained only to verify the security key on legacy PODs before migrating
/// them. Do NOT use for new keys.
String genLegacyVerificationKey(String securityKey) =>
    sha224.convert(utf8.encode(securityKey)).toString().substring(0, 32);

/// Constant-time comparison of two strings.
///
/// Avoids leaking the length of a matching prefix via short-circuit timing
/// (security finding H1). Returns false immediately only on a length
/// mismatch, which is not secret here (hash/verification values have a fixed
/// length).
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) {
    return false;
  }
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Verify the security key against a legacy (version 1) verification key.
///
/// This is part of the public API surface. Version 2 verification requires the
/// stored salt and is performed inside `KeyManager`; this helper covers the
/// legacy scheme only.
bool verifySecurityKey(String securityKey, String verificationKey) =>
    constantTimeEquals(verificationKey, genLegacyVerificationKey(securityKey));

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
String getPredicateUrl(String pred, {Namespace? ns}) =>
    (ns ?? solidTermsNS.ns).withAttr(pred).value;

/// Read file `encryption/enc-keys.ttl' to get verification key and encrypted
/// private key, together with the key-derivation salt and scheme version.
///
/// PODs created before the version 2 scheme have neither a salt nor a version
/// triple; for those `saltB64` is null and `version` defaults to 1 (legacy).
Future<
    ({
      String verificationKey,
      PrvKeyRecord record,
      String? saltB64,
      int version,
    })> readEncKeyFile() async {
  final encKeyUrl = await getFileUrl(await getEncKeyPath());

  final tripleMap = turtleToTripleMap(
    utf8.decode(await getResource(encKeyUrl)),
  );

  if (!tripleMap.containsKey(encKeyUrl)) {
    throw Exception('Invalid content in file: "$encKeyUrl"');
  }
  assert(tripleMap.length == 1);

  dynamic getVal(String pred) => tripleMap[encKeyUrl]![getPredicateUrl(pred)];

  _checkDuplicatedValue(
    value: getVal(encKeyPred),
    errMsg: 'ERROR: Duplicated verification key',
  );
  final verificationKey = getVal(encKeyPred) as String;

  final prvKeyRecord = PrvKeyRecord(
    encKeyBase64: getVal(prvKeyPred) as String,
    ivBase64: getVal(ivPred) as String,
  );

  // Salt and version are absent on legacy (version 1) PODs.
  final saltB64 = getVal(saltPred) as String?;
  final versionStr = getVal(keyVersionPred) as String?;
  final version = versionStr == null ? 1 : int.parse(versionStr);

  return (
    verificationKey: verificationKey,
    record: prvKeyRecord,
    saltB64: saltB64,
    version: version,
  );
}

/// Read file `encryption/ind-keys.ttl' to get encrypted individual keys
Future<Map<String, IndKeyRecord>> readIndKeyFile() async {
  final indKeyUrl = await getFileUrl(await getIndKeyPath());
  final indKeyMap = <String, IndKeyRecord>{};

  final tripleMap = turtleToTripleMap(
    utf8.decode(await getResource(indKeyUrl)),
  );

  dynamic getVal(Map<String, dynamic> map, String pred) =>
      map[getPredicateUrl(pred)];

  for (final entry in tripleMap.entries) {
    // `k' is changed from a URL to a relative path in new version of CSS (e.g v7.1.7)
    // if triples are inserted using SPARQL queries.
    final k = entry.key;
    final v = entry.value;
    if (v.containsKey(getPredicateUrl(sessionKeyPred))) {
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
      final String relFilePath = await getVal(v, pathPred) as String;
      final String fileUrl = await getFileUrl(relFilePath);

      indKeyMap[fileUrl] = IndKeyRecord(
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

  final tripleMap = turtleToTripleMap(
    utf8.decode(await getResource(pubKeyUrl)),
  );

  if (!tripleMap.containsKey(pubKeyUrl)) {
    throw Exception('Invalid content in file: "$pubKeyUrl"');
  }
  assert(tripleMap.length == 1);

  dynamic getVal(String pred) => tripleMap[pubKeyUrl]![getPredicateUrl(pred)];

  _checkDuplicatedValue(
    value: getVal(pubKeyPred),
    errMsg: 'ERROR: Duplicated public key',
  );

  final pubKey = getVal(pubKeyPred) as String;
  return pubKey;
}

/// Read file `shared/shared-keys.ttl` to get encrypted individual keys
/// of shared resources.
Future<Map<String, SharedIndKeyRecord>> readSharedIndKey() async {
  final sharedIndKeyUrl = await getFileUrl(await getSharedKeyFilePath());
  final sharedIndKeyMap = <String, SharedIndKeyRecord>{};

  // dc 20250105: It seems shared/shared-key.ttl is not created during
  // POD initialisation, see `generateDefaultFiles()`. Why?

  if (await checkResourceStatus(sharedIndKeyUrl) != ResourceStatus.exist) {
    return sharedIndKeyMap;
  }

  final tripleMap = turtleToTripleMap(
    utf8.decode(await getResource(sharedIndKeyUrl)),
  );

  // shared-keys.ttl seems to use predicates defined in a different space
  // compared to enc-key.ttl and ind-keys.ttl

  String getPred(String pred) =>
      getPredicateUrl(pred, ns: Namespace(ns: appsData));

  dynamic getVal(Map<String, dynamic> map, String pred) => map[getPred(pred)];

  for (final entry in tripleMap.entries) {
    final v = entry.value;
    if (v.containsKey(getPred(sharedKeyPred))) {
      sharedIndKeyMap[entry.key] = SharedIndKeyRecord(
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
  final sub = await (isFile ? getFileUrl : getDirUrl)(
    indKeyRecord.resourcePath,
  );

  return '${operation.value} DATA {'
      '<$sub> <$appsTerms$pathPred> "${indKeyRecord.resourcePath}"; '
      '<$appsTerms$ivPred> "${indKeyRecord.ivBase64}"; '
      '<$appsTerms$sessionKeyPred> "${indKeyRecord.encKeyBase64}".};';
}

/// Generate the SPARQL query to delete the shared individual/session key
/// and the corresponding IV of a resource with ID [resUniqueId].
Future<String> getSharedIndKeyDeletionQuery(
  String uniqueIdUrl,
  SharedIndKeyRecord record,
) async {
  // Define predicates and objects
  final predObjPath = '$dataPrefix$pathPred "${record.encResourcePath}";';
  final predObjAcc = '$dataPrefix$accessListPred "${record.encAccessList}";';
  final predObjKey = '$dataPrefix$sharedKeyPred "${record.encKey}".';

  // Generate delete sparql query
  return 'PREFIX $dataPrefix <$appsData> DELETE DATA {$uniqueIdUrl $predObjPath $predObjAcc $predObjKey};';
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

/// Generate the content of encKeyFile.
///
/// When [saltB64] and [version] are provided (version 2+ scheme) they are
/// written as additional triples so the key-derivation salt and scheme version
/// can be recovered on subsequent logins. They are omitted for the legacy
/// scheme to keep the file format backwards compatible.
Future<String> genEncKeyTTLStr(
  String encKeyUrl,
  String verificationKey,
  PrvKeyRecord prvKeyRecord, {
  String? saltB64,
  int? version,
}) async {
  final predObjMap = {
    termsNS.ns.withAttr(titlePred): encKeyFileTitle,
    solidTermsNS.ns.withAttr(encKeyPred): verificationKey,
    solidTermsNS.ns.withAttr(ivPred): prvKeyRecord.ivBase64,
    solidTermsNS.ns.withAttr(prvKeyPred): prvKeyRecord.encKeyBase64,
  };

  if (saltB64 != null) {
    predObjMap[solidTermsNS.ns.withAttr(saltPred)] = saltB64;
  }
  if (version != null) {
    predObjMap[solidTermsNS.ns.withAttr(keyVersionPred)] = version.toString();
  }

  final triples = {URIRef(encKeyUrl): predObjMap};

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

      // [20260427 jesscmoore] Removed the assert that record.key is not null, as it prevents first file being written to pod.
      // final indKey = record.key;
      // assert(indKey != null);

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
    final recipientPubKeyUrl = recipientWebId.replaceAll(
      profCard,
      await getPubKeyPath(),
    );

    // Get and parse the pubKeyFile

    final tripleMap = turtleToTripleMap(
      utf8.decode(await getResource(recipientPubKeyUrl)),
    );

    if (!tripleMap.containsKey(recipientPubKeyUrl)) {
      throw Exception('Invalid content in file: "$recipientPubKeyUrl"');
    }

    _recipientPubKeyContent =
        tripleMap[recipientPubKeyUrl]![getPredicateUrl(pubKeyPred)] as String;

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
