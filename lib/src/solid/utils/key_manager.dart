/// Class to manage keys for data encryption and sharing.
///
/// Some terminology used in this class are defined as follows:
/// - security key: the string user provides to unlock encrypted data in PODs
/// - master key: the sha256 of the security key
/// - verification key: the sha224 of the security key
/// - individual key: the AES key used to encrypt an individual file
/// - public/private key pair: the RSA key pair for data sharing.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/utils/key_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart' show tripleMapToTurtle;

/// Add the encrypted individual/session key string [encIndKey] and
/// the corresponding IV string [ivBase64] for file with path [filePath]
Future<void> _addIndKey(
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
Future<void> _delIndKey(
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
Future<void> _delSharedIndKey(
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
void _checkDuplicatedValue({required dynamic value, required String errMsg}) {
  if (value is Iterable && (value as List).length > 1) {
    throw Exception(errMsg);
  }
}

/// [KeyManager] is a class to manage security key and encryption keys
/// for data stored in PODs.
///
/// Some rules we follow:
/// - The "security key" and "master key" are never stored in PODs
/// - Each encrypted file is associated with its own "individual key"
/// - All "individual key"s are encrypted using AES with the "master key"
/// - All encrypted "individual key"s and their IVs are stored in
///   POD_NAME/encryption/ind-keys.ttl
/// - The private key is encrypted using the "master key" and stored in
///   POD_NAME/encryption/enc-keys.ttl (together with its IV)
/// - The public key is stored in POD_NAME/sharing/public-key.ttl
/// - The verification key is stored in POD_NAME/encryption/enc-keys.ttl

class KeyManager {
  /// URL of the file with verification key and encrypted private key
  static String? _encKeyUrl;

  /// URL of the file with encrypted individual keys
  static String? _indKeyUrl;

  /// URL of the file with shared encrypted individual keys
  static String? _sharedIndKeyUrl;

  /// URL of the file with public key
  static String? _pubKeyUrl;

  /// The security key
  static String? _securityKey;

  /// The master key
  static Key? _masterKey;

  /// The verification key
  static String? _verificationKey;

  /// The public key
  static String? _pubKey;

  /// The encrypted (and decrypted) private key
  static _PrvKeyRecord? _prvKeyRecord;

  /// The encrypted (and decrypted) individual keys
  static Map<String, _IndKeyRecord>? _indKeyMap;

  /// The decrypted shared individual keys
  static Map<String, _SharedIndKeyRecord>? _sharedIndKeyMap;

  /// The string key for storing auth data in secure storage
  static const String _securityKeySecureStorageKey = '_solid_security_key';

  /// Remove stored security key and set all cached private members to null
  static Future<void> clear() async {
    await forgetSecurityKey();

    _encKeyUrl = null;
    _indKeyUrl = null;
    _pubKeyUrl = null;
    _sharedIndKeyUrl = null;

    _securityKey = null;
    _masterKey = null;
    _verificationKey = null;

    _pubKey = null;
    _prvKeyRecord = null;

    _indKeyMap = null;
    _sharedIndKeyMap = null;
  }

  /// Initialise the encKeyFile, indKeyFile and pubKeyFile
  /// and save them (on server)
  static Future<void> initPodKeys(String securityKey) async {
    assert(securityKey.trim().isNotEmpty);

    // Clear cached value (if there are any)
    await clear();

    // Set the security key, master key, and verification key

    _securityKey = securityKey;
    _masterKey = genMasterKey(_securityKey!);
    _verificationKey = genVerificationKey(_securityKey!);
    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);

    // Set the public-private key pair

    final pair = await genRandRSAKeyPair();
    _pubKey = trimPubKeyStr(pair.publicKey);
    final iv = genRandIV();
    _prvKeyRecord = _PrvKeyRecord(
      encKeyBase64: encryptPrivateKey(pair.privateKey, _masterKey!, iv),
      ivBase64: iv.base64,
      key: pair.privateKey,
    );

    // Save encKeyFile, indKeyFile, and pubKeyFile (on server)

    await _saveEncKeyFile();
    await _saveIndKeyFile();
    await _savePubKeyFile();
  }

  /// Get the master key
  static Future<Key> getMasterKey() async {
    if (_masterKey == null) {
      _securityKey ??=
          await secureStorage.read(key: _securityKeySecureStorageKey);

      if (_securityKey == null) {
        throw Exception('You must first set the security key!');
      }

      if (!verifySecurityKey(_securityKey!, await getVerificationKey())) {
        await forgetSecurityKey();
        throw Exception('Unable to verify the security key!');
      }

      _masterKey = genMasterKey(_securityKey!);
    }

    return _masterKey!;
  }

  /// Get the verification key
  static Future<String> getVerificationKey() async {
    if (_verificationKey == null) {
      await _loadEncKeyFile();
    }
    assert(_verificationKey != null);
    return _verificationKey!;
  }

  /// Check if the security is available
  static Future<bool> hasSecurityKey() async {
    _securityKey ??=
        await secureStorage.read(key: _securityKeySecureStorageKey);

    if (_securityKey == null) {
      return false;
    }

    if (!verifySecurityKey(_securityKey!, await getVerificationKey())) {
      await forgetSecurityKey();
      return false;
    }

    return true;
  }

  /// Set the security key
  static Future<void> setSecurityKey(String securityKey) async {
    if (await hasSecurityKey()) {
      debugPrint('Security key already set, do nothing.');
      return;
    }

    if (!verifySecurityKey(securityKey, await getVerificationKey())) {
      throw Exception('Unable to verify the provided security key!');
    }

    _securityKey = securityKey;
    _masterKey = genMasterKey(_securityKey!);

    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);
  }

  /// Remove the security key from memory and local secure storage
  static Future<void> forgetSecurityKey() async {
    if (await secureStorage.containsKey(key: _securityKeySecureStorageKey)) {
      await secureStorage.delete(key: _securityKeySecureStorageKey);
    }

    // Remove the security key, master key, decrypted private key,
    // and decrypted individual keys from memory (if applicable).

    _securityKey = null;
    _masterKey = null;

    if (_prvKeyRecord != null) {
      _prvKeyRecord!.key = null;
    }

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final record in _indKeyMap!.values) {
        record.key = null;
      }
    }
  }

  /// Change the security key and update encKeyFile and indKeyFile in POD
  static Future<void> changeSecurityKey(
    String currentSecurityKey,
    String newSecurityKey,
  ) async {
    if (!verifySecurityKey(currentSecurityKey, await getVerificationKey())) {
      throw Exception('Unable to verify the current security key!');
    }

    assert(newSecurityKey.trim().isNotEmpty);
    assert(newSecurityKey != currentSecurityKey);

    _securityKey = currentSecurityKey;
    _masterKey ??= genMasterKey(_securityKey!);

    // Load key files and decrypt the private key and individual keys
    // using the old master key

    await _loadEncKeyFile();
    await _loadIndKeyFile();

    assert(_prvKeyRecord != null);
    _prvKeyRecord!.key ??= await getPrivateKey();

    assert(_indKeyMap != null);
    if (_indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final fileUrl = entry.key;
        final record = entry.value;
        record.key ??= await getIndividualKey(fileUrl);
        _indKeyMap![fileUrl] = record;
      }
    }

    // Set the new security key, master key, and verification key

    _securityKey = newSecurityKey;
    _masterKey = genMasterKey(_securityKey!);
    _verificationKey = genVerificationKey(_securityKey!);

    // Encrypt the private key using the new master key (and new IV)

    final iv = genRandIV();
    _prvKeyRecord!.ivBase64 = iv.base64;
    _prvKeyRecord!.encKeyBase64 =
        encryptPrivateKey(_prvKeyRecord!.key!, _masterKey!, iv);

    // Re-generate the content of encKeyFile and save it (on server)
    await _saveEncKeyFile();

    // Encrypt the individual keys using the new mater key (and new IVs)

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final fileUrl = entry.key;
        final record = entry.value;

        final iv = genRandIV();
        final indKey = record.key;
        assert(indKey != null);

        record.ivBase64 = iv.base64;
        record.encKeyBase64 = encryptData(indKey!.base64, _masterKey!, iv);

        _indKeyMap![fileUrl] = record;
      }
    }

    // Re-generate the content of indKeyFile and save it (on server)
    await _saveIndKeyFile();

    // Save security key to local secure storage
    await writeToSecureStorage(_securityKeySecureStorageKey, _securityKey!);
  }

  /// Return the public key
  static Future<String> getPublicKey() async {
    if (_pubKey == null) {
      await _loadPubKeyFile();
    }
    assert(_pubKey != null);
    return _pubKey!;
  }

  /// Return the private key
  static Future<String> getPrivateKey() async {
    if (_prvKeyRecord == null) {
      await _loadEncKeyFile();
    }

    assert(_prvKeyRecord != null);

    _prvKeyRecord!.key ??= decryptPrivateKey(
      _prvKeyRecord!.encKeyBase64,
      await getMasterKey(),
      IV.fromBase64(_prvKeyRecord!.ivBase64),
    );

    return _prvKeyRecord!.key!;
  }

  /// Returns true if there is an individual key for a given resource
  static Future<bool> hasIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);
    return _indKeyMap!.containsKey(resourceUrl);
  }

  /// Return the (decrypted) individual key for an existing resource
  static Future<Key> getIndividualKey(String resourceUrl) async {
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }

    assert(_indKeyMap != null);
    if (!_indKeyMap!.containsKey(resourceUrl)) {
      throw Exception(
        'Unable to locate the individual key for resource:\n$resourceUrl',
      );
    }

    final record = _indKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      record.key = Key.fromBase64(
        decryptData(
          record.encKeyBase64,
          await getMasterKey(),
          IV.fromBase64(record.ivBase64),
        ),
      );
      _indKeyMap![resourceUrl] = record;
    }
    return record.key!;
  }

  /// Add the (encrypted) individual key for file
  static Future<void> addIndividualKey(
    String resourcePath,
    Key indKey, {
    bool isFile = true,
  }) async {
    String fileUrl;
    if (isFile) {
      fileUrl = await getFileUrl(resourcePath);
    } else {
      fileUrl = await getDirUrl(resourcePath);
    }

    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);

    final iv = genRandIV();
    final encIndKey = encryptData(indKey.base64, await getMasterKey(), iv);
    _indKeyMap![fileUrl] = _IndKeyRecord(
      resourcePath: resourcePath,
      encKeyBase64: encIndKey,
      ivBase64: iv.base64,
    );

    await _addIndKey(resourcePath, encIndKey, iv.base64, isFile: isFile);
  }

  /// Remove the (encrypted) individual key for file
  static Future<void> removeIndividualKey(String filePath) async {
    final fileUrl = await getFileUrl(filePath);
    if (_indKeyMap == null) {
      await _loadIndKeyFile();
    }
    assert(_indKeyMap != null);

    if (_indKeyMap!.containsKey(fileUrl)) {
      final record = _indKeyMap!.remove(fileUrl);
      assert(record != null);
      await _delIndKey(filePath, record!.encKeyBase64, record.ivBase64);
      debugPrint('Deleted $record');
    } else {
      debugPrint('Individual key for "$filePath" does not exist, do nothing.');
    }
  }

  /// Returns true if there is an individual key for a given resource
  static Future<bool> hasSharedIndividualKey(String resourceUrl) async {
    if (_sharedIndKeyMap == null || _sharedIndKeyMap!.isEmpty) {
      await _loadSharedIndKeyFile();
    }
    assert(_sharedIndKeyMap != null);
    return _sharedIndKeyMap!.containsKey(resourceUrl);
  }

  /// Return the (decrypted) individual key for an existing resource
  static Future<Key> getSharedIndividualKey(String resourceUrl) async {
    if (_sharedIndKeyMap == null) {
      await _loadSharedIndKeyFile();
    }

    assert(_sharedIndKeyMap != null);
    if (!_sharedIndKeyMap!.containsKey(resourceUrl)) {
      throw Exception(
        'Unable to locate the individual key for resource:\n$resourceUrl',
      );
    }

    final record = _sharedIndKeyMap![resourceUrl];
    assert(record != null);

    if (record!.key == null) {
      _prvKeyRecord!.key ??= await getPrivateKey();
      final encrypter = Encrypter(
        RSA(
          privateKey:
              RSAKeyParser().parse(_prvKeyRecord!.key!) as RSAPrivateKey,
        ),
      );

      record.filePath = encrypter.decrypt64(record.encFilePath);
      record.accessList = encrypter.decrypt64(record.encAccessList);
      record.key = Key.fromBase64(encrypter.decrypt64(record.encKey));
    }

    return record.key!;
  }

  /// Remove the (encrypted) shared individual key for file
  static Future<void> removeSharedIndividualKey(
    String resourceUrl,
    String resUniqueId,
  ) async {
    if (_sharedIndKeyMap == null) {
      await _loadSharedIndKeyFile();
    }
    assert(_sharedIndKeyMap != null);

    if (_sharedIndKeyMap!.containsKey(resourceUrl)) {
      final record = _sharedIndKeyMap!.remove(resourceUrl);
      assert(record != null);

      // Delete shared key from shared keys file
      await _delSharedIndKey(
        resUniqueId,
        record!.encKey,
        record.encFilePath,
        record.encAccessList,
      );
      debugPrint('Deleted $record');
    } else {
      debugPrint(
        'Individual key for "$resourceUrl" does not exist, do nothing.',
      );
    }
  }

  /// Load the file with verification key and encrypted private key
  static Future<void> _loadEncKeyFile({bool forceReload = false}) async {
    if (_verificationKey != null && _prvKeyRecord != null && !forceReload) {
      return;
    }

    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    // _checkMasterKey();

    // Get and parse the encKeyFile
    final map = await loadPrvTTL(_encKeyUrl!);

    if (!map.containsKey(_encKeyUrl)) {
      throw Exception('Invalid content in file: "$_encKeyUrl"');
    }
    assert(map.length == 1);

    final v = map[_encKeyUrl] as Map;
    _checkDuplicatedValue(
      value: v[encKeyPred],
      errMsg: 'ERROR: Duplicated verification key',
    );
    _verificationKey = v[encKeyPred] as String;

    _prvKeyRecord = _PrvKeyRecord(
      encKeyBase64: v[prvKeyPred] as String,
      ivBase64: v[ivPred] as String,
    );
  }

  /// Generate the content of indKeyFile and save it (on server)
  static Future<void> _saveEncKeyFile() async {
    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    await createResource(_encKeyUrl!, content: await _genEncKeyTTLStr());
  }

  /// Load the file with encrypted individual keys
  static Future<void> _loadIndKeyFile({bool forceReload = false}) async {
    if (_indKeyMap != null && !forceReload) {
      return;
    }

    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    _indKeyMap ??= <String, _IndKeyRecord>{};

    final map = await loadPrvTTL(_indKeyUrl!);

    for (final entry in map.entries) {
      final k = entry.key;
      final v = entry.value as Map;
      if (v.containsKey(sessionKeyPred)) {
        _checkDuplicatedValue(
          value: v[sessionKeyPred],
          errMsg: 'ERROR: Duplicated encryption key for resource "$k"',
        );
        _checkDuplicatedValue(
          value: v[ivPred],
          errMsg: 'ERROR: Duplicated IV for resource "$k"',
        );
        _checkDuplicatedValue(
          value: v[pathPred],
          errMsg: 'ERROR: Duplicated path for resource "$k"',
        );

        // Add to _indKeyMap
        _indKeyMap![await getFileUrl(v[pathPred] as String)] = _IndKeyRecord(
          encKeyBase64: v[sessionKeyPred] as String,
          ivBase64: v[ivPred] as String,
          resourcePath: v[pathPred] as String,
        );
      }
    }
  }

  /// Generate the content of indKeyFile and save it (on server)
  static Future<void> _saveIndKeyFile() async {
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    await createResource(_indKeyUrl!, content: await _genIndKeyTTLStr());
  }

  /// Load the file with public key
  static Future<void> _loadPubKeyFile({bool forceReload = false}) async {
    if (_pubKey != null && !forceReload) {
      return;
    }

    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    // Get and parse the pubKeyFile
    final map = await loadPrvTTL(_pubKeyUrl!);

    if (!map.containsKey(_pubKeyUrl)) {
      throw Exception('Invalid content in file: "$_pubKeyUrl"');
    }

    _checkDuplicatedValue(
      value: map[_pubKeyUrl][pubKeyPred],
      errMsg: 'ERROR: Duplicated public key',
    );

    _pubKey = map[_pubKeyUrl][pubKeyPred] as String;
  }

  /// Generate the content of pubKeyFile and save it (on server)
  static Future<void> _savePubKeyFile() async {
    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    await createResource(_pubKeyUrl!, content: await _genPubKeyTTLStr());
  }

  /// Load the file with encrypted individual keys
  static Future<void> _loadSharedIndKeyFile({bool forceReload = false}) async {
    if (_sharedIndKeyMap != null && !forceReload) {
      return;
    }

    _sharedIndKeyUrl ??= await getFileUrl(await getSharedKeyFilePath());
    _sharedIndKeyMap ??= <String, _SharedIndKeyRecord>{};
    Encrypter? encrypter;

    final map = await loadPrvTTL(_sharedIndKeyUrl!);

    for (final entry in map.entries) {
      final v = entry.value as Map;
      if (v.containsKey(sharedKeyPred)) {
        // Get private key
        if (_prvKeyRecord == null) {
          await _loadEncKeyFile();
        }
        assert(_prvKeyRecord != null);
        _prvKeyRecord!.key ??= await getPrivateKey();
        encrypter ??= Encrypter(
          RSA(
              privateKey:
                  RSAKeyParser().parse(_prvKeyRecord!.key!) as RSAPrivateKey),
        );
        ;
        _sharedIndKeyMap![encrypter.decrypt64(v[pathPred] as String)] =
            _SharedIndKeyRecord(
          encFilePath: v[pathPred] as String,
          encAccessList: v[accessListPred] as String,
          encKey: v[sharedKeyPred] as String,
        );
      }
    }
  }

  /// Generate the content of encKeyFile
  static Future<String> _genEncKeyTTLStr() async {
    assert(_verificationKey != null);
    assert(_prvKeyRecord != null);

    _encKeyUrl ??= await getFileUrl(await getEncKeyPath());

    final triples = {
      URIRef(_encKeyUrl!): {
        termsNS.ns.withAttr(titlePred): encKeyFileTitle,
        solidTermsNS.ns.withAttr(encKeyPred): _verificationKey!,
        solidTermsNS.ns.withAttr(ivPred): _prvKeyRecord!.ivBase64,
        solidTermsNS.ns.withAttr(prvKeyPred): _prvKeyRecord!.encKeyBase64,
      },
    };

    final bindNS = {
      solidTermsNS.prefix: solidTermsNS.ns,
      termsNS.prefix: termsNS.ns,
    };

    return tripleMapToTurtle(triples, bindNamespaces: bindNS);
  }

  /// Generate the content of indKeyFile
  static Future<String> _genIndKeyTTLStr() async {
    _indKeyUrl ??= await getFileUrl(await getIndKeyPath());

    final triples = <URIRef, Map<URIRef, String>>{};
    triples[URIRef(_indKeyUrl!)] = {
      termsNS.ns.withAttr(titlePred): indKeyFileTitle,
    };

    if (_indKeyMap != null && _indKeyMap!.isNotEmpty) {
      for (final entry in _indKeyMap!.entries) {
        final fileUrl = entry.key;
        final record = entry.value;

        final indKey = record.key;
        assert(indKey != null);

        triples[URIRef(fileUrl)] = {
          solidTermsNS.ns.withAttr(pathPred): record.resourcePath,
          solidTermsNS.ns.withAttr(ivPred): record.ivBase64,
          solidTermsNS.ns.withAttr(sessionKeyPred): record.encKeyBase64,
        };
      }
    }

    final bindNS = {
      solidTermsNS.prefix: solidTermsNS.ns,
      termsNS.prefix: termsNS.ns,
    };

    return tripleMapToTurtle(triples, bindNamespaces: bindNS);
  }

  /// Generate the content of pubKeyFile
  static Future<String> _genPubKeyTTLStr() async {
    assert(_pubKey != null);

    _pubKeyUrl ??= await getFileUrl(await getPubKeyPath());

    final triples = {
      URIRef(_pubKeyUrl!): {
        termsNS.ns.withAttr(titlePred): pubKeyFileTitle,
        solidTermsNS.ns.withAttr(pubKeyPred): _pubKey!,
      },
    };

    final bindNS = {
      solidTermsNS.prefix: solidTermsNS.ns,
      termsNS.prefix: termsNS.ns,
    };

    return tripleMapToTurtle(triples, bindNamespaces: bindNS);
  }
}

/// [_IndKeyRecord] is a simple class to store encrypted and decrypted AES keys
/// of individual data files.

class _IndKeyRecord {
  /// Constructor
  _IndKeyRecord({
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

class _SharedIndKeyRecord {
  /// Constructor
  _SharedIndKeyRecord({
    required this.encFilePath,
    required this.encAccessList,
    required this.encKey,
  });

  /// The path of file corresponds to the key
  String? filePath;

  /// The access list
  String? accessList;

  /// The corresponding decrypted key
  Key? key;

  /// The encrypted path of file corresponds to the key
  final String encFilePath;

  /// The encrypted access list
  final String encAccessList;

  /// The encrypted key string
  final String encKey;

  @override
  String toString() => 'SharedIndividualKeyRecord {\n'
      '    encFilePath: $filePath,\n'
      '    encAccessList: $accessList,\n'
      '    encKey: $key\n'
      '}';
}

/// [_PrvKeyRecord] is a simple class to store encrypted and decrypted
/// private key for data sharing.

class _PrvKeyRecord {
  /// Constructor
  _PrvKeyRecord({required this.encKeyBase64, required this.ivBase64, this.key});

  /// The base64 string of the encrypted private key
  String encKeyBase64;

  /// The base64 string of the IV
  String ivBase64;

  /// The corresponding decrypted private key
  String? key;
}
