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

const int longStrLength = 12;

/// String terms used for files created and used inside a POD.

const String encKeyFile = 'enc-keys.ttl';
const String pubKeyFile = 'public-key.ttl';
const String indKeyFile = 'ind-keys.ttl';
const String permLogFile = 'permissions-log.ttl';

// const String sharingDir = 'sharing';
// const String sharedDir = 'shared';
const String encDir = 'encryption';
// const String logsDir = 'logs';

/// String terms used as predicates in ttl files.

const String profCard = 'profile/card#me';
const String ivPred = 'iv';
const String titlePred = 'title';
const String prvKeyPred = 'prvKey';
const String pubKeyPred = 'pubKey';
const String encKeyPred = 'encKey';
const String pathPred = 'path';
const String sessionKeyPred = 'sessionKey';
// const String createdDateTimePred = 'createdDateTime';
// const String modifiedDateTimePred = 'modifiedDateTime';
// const String noteTitlePred = 'noteTitle';
// const String encNoteContentPred = 'encNoteContent';
// const String noteFileNamePrefix = 'note-';

/// String link variables used in files generation process for defining ttl
/// file content.

const String appsTerms = 'https://solidcommunity.au/predicates/terms#';
const String terms = 'http://purl.org/dc/terms/';
const String acl = 'http://www.w3.org/ns/auth/acl#';
const String foaf = 'http://xmlns.com/foaf/0.1/';
const String appsFile = 'https://solidcommunity.au/predicates/file#';
const String appsLogId = 'https://solidcommunity.au/predicates/logid#';
// const String solid = 'http://www.w3.org/ns/solid/terms#';

/// Initialize a constant instance of FlutterSecureStorage for secure data storage.
/// This instance provides encrypted storage to securely store key-value pairs.

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

