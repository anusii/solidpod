/// Organized constants structure for the solidpod package.
///
/// This file provides a structured way to access constants, avoiding
/// potential name conflicts when importing the package.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Graham Williams, Anushka Vidanage

library;

import 'package:solidpod/src/solid/constants/common.dart' as common;
import 'package:solidpod/src/solid/constants/schema.dart' as schema;

// Re-export enums and types that need to be directly accessible
export 'package:solidpod/src/solid/constants/common.dart'
    show ResourceStatus, ResourceContentType, FileOpenMode;
export 'package:solidpod/src/solid/constants/path_type.dart' show PathType;
export 'package:solidpod/src/solid/constants/schema.dart' show SIIPredicate;

/// Organized structure for Solid-related constants.
///
/// Use this class to access constants in a namespaced way:
/// ```dart
/// import 'package:solidpod/solidpod.dart';
///
/// // Access namespace URIs
/// final foafUri = SolidConstants.namespaces.foaf;
/// final termsUri = SolidConstants.namespaces.terms;
///
/// // Access directory names
/// final dataDir = SolidConstants.directories.data;
///
/// // Access file names
/// final encKeyFile = SolidConstants.files.encryptionKeys;
///
/// // Access predicate names
/// final titlePred = SolidConstants.predicates.title;
/// ```
abstract final class SolidConstants {
  /// Namespace URIs for RDF/Turtle operations.
  static const namespaces = _Namespaces();

  /// Standard directory names used in POD structure.
  static const directories = _Directories();

  /// Standard file names used in POD structure.
  static const files = _Files();

  /// Common predicate names used in TTL files.
  static const predicates = _Predicates();

  /// Schema URIs for SolidCommunity.au predicates.
  static const schemaUris = _SchemaUris();
}

/// Namespace URIs for RDF/Turtle operations.
class _Namespaces {
  const _Namespaces();

  /// ACL (Access Control List) namespace: http://www.w3.org/ns/auth/acl#
  String get acl => common.acl;

  /// FOAF (Friend of a Friend) namespace: http://xmlns.com/foaf/0.1/
  String get foaf => common.foaf;

  /// RDF namespace: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  String get rdf => common.rdf;

  /// Dublin Core Terms namespace: http://purl.org/dc/terms/
  String get terms => common.terms;

  /// VCard namespace: http://www.w3.org/2006/vcard/ns#
  String get vcard => common.vcard;

  /// XSD (XML Schema Definition) namespace: http://www.w3.org/2001/XMLSchema#
  String get xsd => common.xsd;
}

/// Standard directory names used in POD structure.
class _Directories {
  const _Directories();

  /// Data directory name
  String get data => common.dataDir;

  /// Sharing directory name
  String get sharing => common.sharingDir;

  /// Shared directory name
  String get shared => common.sharedDir;

  /// Encryption directory name
  String get encryption => common.encDir;

  /// Logs directory name
  String get logs => common.logsDir;

  /// Profile directory name
  String get profile => common.profileDir;

  /// The current application directory name
  String get app => common.appDirName;
}

/// Standard file names used in POD structure.
class _Files {
  const _Files();

  /// Encryption keys file: enc-keys.ttl
  String get encryptionKeys => common.encKeyFile;

  /// Public key file: public-key.ttl
  String get publicKey => common.pubKeyFile;

  /// Individual keys file: ind-keys.ttl
  String get individualKeys => common.indKeyFile;

  /// Permissions log file: permissions-log.ttl
  String get permissionsLog => common.permLogFile;

  /// Shared keys file: shared-keys.ttl
  String get sharedKeys => common.sharedKeyFile;

  /// Public individual keys file: public-ind-keys.ttl
  String get publicIndividualKeys => common.pubIndKeyFile;

  /// Authenticated user individual keys file: auth-user-ind-keys.ttl
  String get authUserIndividualKeys => common.authUserIndKeyFile;

  /// Profile picture file: avatar.png
  String get profilePicture => common.profilePictureFile;

  /// Display name file: display-name.txt
  String get displayName => common.displayNameFile;
}

/// Common predicate names used in TTL files.
class _Predicates {
  const _Predicates();

  /// Profile card predicate
  String get profileCard => common.profCard;

  /// Initialization vector predicate
  String get iv => common.ivPred;

  /// Title predicate
  String get title => common.titlePred;

  /// Private key predicate
  String get privateKey => common.prvKeyPred;

  /// Public key predicate
  String get publicKey => common.pubKeyPred;

  /// Encryption key predicate
  String get encryptionKey => common.encKeyPred;

  /// Path predicate
  String get path => common.pathPred;

  /// Access list predicate
  String get accessList => common.accessListPred;

  /// File path list predicate
  String get filePathList => common.filePathListPred;

  /// Authenticated user predicate
  String get authUser => common.authUserPred;

  /// Shared key predicate
  String get sharedKey => common.sharedKeyPred;

  /// Session key predicate
  String get sessionKey => common.sessionKeyPred;

  /// Encrypted data predicate
  String get encryptedData => common.encDataPred;

  /// Inherit key predicate
  String get inheritKey => common.inheritKeyPred;

  /// Type predicate
  String get type => common.typePred;

  /// Agent predicate
  String get agent => common.agentPred;

  /// Agent group predicate
  String get agentGroup => common.agentGroupPred;

  /// Mode predicate
  String get mode => common.modePred;

  /// Agent class predicate
  String get agentClass => common.agentClassPred;
}

/// Schema URIs for SolidCommunity.au predicates.
class _SchemaUris {
  const _SchemaUris();

  /// Apps terms predicate URI
  String get appsTerms => schema.appsTerms;

  /// Resource ID predicate URI
  String get appsResourceId => schema.appsResId;

  /// Log ID predicate URI
  String get appsLogId => schema.appsLogId;

  /// Data predicate URI
  String get appsData => schema.appsData;

  /// SII (Software Innovation Institute) namespace
  String get sii => schema.sii;
}
