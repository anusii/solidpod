/// Contains functions for generating bodies of different ttl files.
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

library;

import 'package:solidpod/src/solid/constants.dart';

/// Removes header and footer from a PEM-formatted public key string.
///
/// This function takes a public key string, typically in PEM format, and removes
/// the standard PEM headers and footers.

String dividePubKeyStr(String keyStr) {
  final itemList = keyStr.split('\n');
  itemList.remove('-----BEGIN RSA PUBLIC KEY-----');
  itemList.remove('-----END RSA PUBLIC KEY-----');
  itemList.remove('-----BEGIN PUBLIC KEY-----');
  itemList.remove('-----END PUBLIC KEY-----');

  final keyStrTrimmed = itemList.join();

  return keyStrTrimmed;
}

/// Generates an encryption key body string.
///
/// Constructs a TTL (Time To Live) file body string using the provided parameters.
/// This string is formatted with specific resource URL, private key, private key initialization vector,
/// and encrypted master key. These elements are organized in a predefined structured format.
///
/// The function primarily serves the purpose of assembling a structured text representation
/// of encryption keys and related data, which can be utilized in further cryptographic operations
/// or data transmission.

String genEncKeyBody(
  String encMasterKey,
  String prvKey,
  String prvKeyIvz,
  String resUrl,
) {
  // Create a ttl file body.

  final keyFileBody =
      '<$resUrl> <$terms$titlePred> "Encryption keys";\n    <$appsTerms$ivPred> "$prvKeyIvz";\n    <$appsTerms$encKeyPred> "$encMasterKey";\n    <$appsTerms$prvKeyPred> "$prvKey".';

  return keyFileBody;
}

/// Generates an ACL (Access Control List) log body for a specified web ID and permission file.
///
/// This function creates an ACL log body with specific prefixes and authorization settings.
/// It modifies the web ID by removing 'me' and constructs an ACL log with various permissions.
///
/// [webId] is the web identifier, which is altered within the function.
/// [permFileName] is the name of the file for which the ACL settings are being generated.
///
/// Returns a [String] containing the ACL log body.

String genLogAclBody(String webId, String permFileName) {
  final webIdStr = webId.replaceAll('me', '');
  final logAclFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix foaf: <$foaf>.\n@prefix c: <$webIdStr>.\n\n:owner\n    a acl:Authorization;\n    acl:accessTo <$permFileName>;\n    acl:agent c:me;\n    acl:mode acl:Control, acl:Read, acl:Write.\n\n:public\n    a acl:Authorization;\n    acl:accessTo <$permFileName>;\n    acl:agentClass foaf:Agent;\n    acl:mode acl:Append.';

  return logAclFileBody;
}

/// Generates a string representing the public file ACL (Access Control List) body.
///
/// This function creates an ACL body for a given file, setting up authorization
/// rules for both the owner and public access. It formats the ACL data using
/// specific prefixes and access rules. The owner is granted full control (read,
/// write, and control), while public access is limited to read and write permissions.
///
/// The generated ACL body uses a RDF (Resource Description Framework) format, specifying
/// the permissions using ACL ontology. This format is often used in web standards for
/// describing the rules about who can access a specific resource.

String genPubFileAclBody(String fileName) {
  // Create file body
  final resName = fileName.replaceAll('.acl', '');
  final pubFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix foaf: <$foaf>.\n@prefix c: <card#>.\n\n:owner\n    a acl:Authorization;\n    acl:accessTo <$resName>;\n    acl:agent c:me;\n    acl:mode acl:Control, acl:Read, acl:Write.\n\n:public\n    a acl:Authorization;\n    acl:accessTo <$resName>;\n    acl:agentClass foaf:Agent;\n    acl:mode acl:Read, acl:Write.';

  return pubFileBody;
}

/// Generates the body for a public directory ACL (Access Control List).
///
/// This function constructs a string representing the body of an ACL file.
/// The ACL (Access Control List) is defined using Web Access Control (WAC)
/// vocabulary, specifying authorization policies for a web resource.

String genPubDirAclBody() {
  // Create file body
  const pubFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix foaf: <$foaf>.\n@prefix shrd: <./>.\n@prefix c: </profile/card#>.\n\n:owner\n    a acl:Authorization;\n    acl:accessTo shrd:;\n    acl:agent c:me;\n    acl:mode acl:Control, acl:Read, acl:Write.\n\n:public\n    a acl:Authorization;\n    acl:accessTo shrd:;\n    acl:default shrd:;\n    acl:agentClass foaf:Agent;\n    acl:mode acl:Read, acl:Write.';

  return pubFileBody;
}

/// Generates the body of an individual encryption key file in Turtle (Terse RDF Triple Language) format.
///
/// This function constructs a string representing the body of an RDF file, which includes various
/// prefixed namespaces such as FOAF (Friend of a Friend) and custom application-specific terms.
/// The key file body includes a definition for a personal profile document with a title
/// "Individual Encryption Keys". The prefixes used ('foaf:', 'terms:', etc.) are placeholders
/// that should be replaced with actual URIs in a real-world application.

String genIndKeyFileBody() {
  const keyFileBody =
      '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix terms: <$terms>.\n@prefix file: <$appsFile>.\n@prefix appsTerms: <$appsTerms>.\n:me\n    a foaf:PersonalProfileDocument;\n    terms:title "Individual Encryption Keys".';

  return keyFileBody;
}

/// Generates a public key file body in string format.
///
/// This function creates a string that represents the body of a public key file.
/// It formats the resource URL and the public key string into a predefined template.
///
/// The template includes a resource URL and a public key string, formatted
/// with specific predicates and a title. The `<$terms$titlePred>` is used for the
/// title "Public key" and `<$appsTerms$pubKeyPred>` for the public key itself.

String genPubKeyFileBody(String resUrl, String pubKeyStr) {
  final keyFileBody =
      '<$resUrl> <$terms$titlePred> "Public key";\n    <$appsTerms$pubKeyPred> "$pubKeyStr";';

  return keyFileBody;
}

/// Generates a profile file body in a predefined format.
///
/// This function takes two maps, `profData` and `authData`, as inputs. The `profData`
/// map contains user profile information such as name and gender. The `authData` map
/// includes authentication information, specifically an access token.
///
/// // comment out the following function as it is not used in the current version
// of the app, anushka might need to use to in the future so keeping it here.

// String genProfFileBody(
//     Map<dynamic, dynamic> profData, Map<dynamic, dynamic> authData) {
//   final decodedToken = JwtDecoder.decode(authData['accessToken'] as String);
//   final issuerUri = decodedToken['iss'] as String;

//   final name = profData['name'];
//   final gender = profData['gender'];

//   final fileBody =
//       '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix solid: <$solid>.\n@prefix vcard: <http://www.w3.org/2006/vcard/ns#>.\n@prefix pro: <./>.\n\npro:card a foaf:PersonalProfileDocument; foaf:maker :me; foaf:primaryTopic :me.\n\n:me\n    solid:oidcIssuer <$issuerUri>;\n    a foaf:Person;\n    vcard:fn "$name";\n    vcard:Gender "$gender";\n    foaf:name "$name".';

//   return fileBody;
// }

/// Generates the body of a log file in Turtle (Terse RDF Triple Language) format.
///
/// This function constructs a string representing RDF data with specific prefixes
/// and a structured layout. It defines a personal profile document with
/// predefined namespaces (foaf, terms, logid, appsTerms) and a title.
///
/// The resulting string is formatted for use in semantic web applications or
/// any context where RDF data is required.

String genLogFileBody() {
  const logFileBody =
      '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix terms: <$terms>.\n@prefix logid: <$appsLogId>.\n@prefix appsTerms: <$appsTerms>.\n:me\n    a foaf:PersonalProfileDocument;\n    terms:title "Permissions Log".';

  return logFileBody;
}

/// A constant map of file extensions to MIME types.
///
/// This map is used to associate common file extensions with their corresponding
/// MIME type strings. It includes types for 'acl' and 'ttl' as 'text/turtle',
/// and 'log' as 'text/plain'. This can be utilized for file type identification
/// or setting content types in network communications.

const Map<String, String> fileType = {
  'acl': 'text/turtle',
  'log': 'text/plain',
  'ttl': 'text/turtle',
};
