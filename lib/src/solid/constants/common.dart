/// Common constants used across the package.
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
/// Authors: Anushka Vidanage

// ignore_for_file: public_member_api_docs

library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Length limit for long strings for a screen.

// const int longStrLength = 12;

/// String terms used for files created and used inside a POD.

const String encKeyFile = 'enc-keys.ttl';
const String pubKeyFile = 'public-key.ttl';
const String indKeyFile = 'ind-keys.ttl';
const String permLogFile = 'permissions-log.ttl';
const String sharedKeyFile = 'shared-keys.ttl';

const dataDir = 'data';
const sharingDir = 'sharing';
const sharedDir = 'shared';
const encDir = 'encryption';
const logsDir = 'logs';

/// String terms used as predicates in ttl files.

const String profCard = 'profile/card#me';
const String ivPred = 'iv';
const String titlePred = 'title';
const String prvKeyPred = 'prvKey';
const String pubKeyPred = 'pubKey';
const String encKeyPred = 'encKey'; // verification key of the master key
const String pathPred = 'path';
const String accessListPred = 'accessList';
const String sharedKeyPred = 'sharedKey';
const String sessionKeyPred = 'sessionKey';
const String encDataPred = 'encData';
const String typePred = 'type';
const String accessToPred = 'accessTo';
const String agentPred = 'agent';
const String agentGroupPred = 'agentGroup';
const String modePred = 'mode';
const String agentClassPred = 'agentClass';
// const String createdDateTimePred = 'createdDateTime';
// const String modifiedDateTimePred = 'modifiedDateTime';
// const String noteTitlePred = 'noteTitle';
// const String encNoteContentPred = 'encNoteContent';
// const String noteFileNamePrefix = 'note-';

/// ACL file map strings
const String permStr = 'permissions';
const String agentStr = 'agentType';

/// String terms used as values in ttl files.

const String aclAuth = 'Authorization';
const String aclRead = 'Read';
const String aclWrite = 'Write';
const String aclAppend = 'Append';
const String aclControl = 'Control';
const String aclAgent = 'Agent';
const String aclAuthAgent = 'AuthenticatedAgent';
const String aclDefault = 'default';
const String profileDoc = 'PersonalProfileDocument';

/// String link variables used in files generation process for defining ttl
/// file content.

const String acl = 'http://www.w3.org/ns/auth/acl#';
const String foaf = 'http://xmlns.com/foaf/0.1/';
const String ldp = 'http://www.w3.org/ns/ldp#';
const String rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
const String rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
const String terms = 'http://purl.org/dc/terms/';
const String vcard = 'http://www.w3.org/2006/vcard/ns#';
const String xsd = 'http://www.w3.org/2001/XMLSchema#';
const String pubAgent = 'http://xmlns.com/foaf/0.1/Agent';
const String authAgent = 'http://xmlns.com/foaf/0.1/AuthenticatedAgent';
// const String solid = 'http://www.w3.org/ns/solid/terms#';

/// String terms used as prfixes in turtle and acl files
const String foafPrefix = 'foaf:';
const String aclPrefix = 'acl:';
const String selfPrefix = ':';
const String termsPrefix = 'terms:';
const String filePrefix = 'file:';
const String dataPrefix = 'data:';
const String resIdPrefix = 'resourceId:';
const String logIdPrefix = 'logId:';

/// String variables for creating files and directories on solid server

String fileTypeLink = '<http://www.w3.org/ns/ldp#Resource>; rel="type"';
String dirTypeLink = '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"';

/// String variables for encryption key files

const String encKeyFileTitle = 'Encryption keys';
const String indKeyFileTitle = 'Individual Encryption Keys';
const String pubKeyFileTitle = 'Public key';

/// String variable for log files

const String logFileTitle = 'Permissions Log';

/// Initialize a constant instance of FlutterSecureStorage for secure data storage.
/// This instance provides encrypted storage to securely store key-value pairs.

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

/// Enum of resource status

enum ResourceStatus {
  /// The resource exist
  exist,

  /// The resource does not exist
  notExist,

  /// Do not know if the resource exist (e.g. error occurred when checking the status)
  unknown
}

/// Types of the content of resources
enum ResourceContentType {
  /// TTL text file
  turtleText('text/turtle'),

  /// Plain text file
  plainText('text/plain'),

  /// Directory
  directory('application/octet-stream'),

  /// Binary data
  binary('application/octet-stream'),

  /// Any
  any('*/*');

  /// Constructor
  const ResourceContentType(this.value);

  /// String value of the access type
  final String value;
}

/// The mode in which a file is opened
enum FileOpenMode {
  /// Text mode
  text('text'),

  /// Binary mode
  binary('binary');

  /// Constructor
  const FileOpenMode(this.value);

  /// String value of the mode
  final String value;
}
