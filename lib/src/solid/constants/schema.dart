/// Hard coded schema URIs that are defined once.
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
/// Authors: Anushka Vidanage, Dawei Chen

library;

import 'package:rdflib/rdflib.dart';

import 'package:solidpod/src/solid/constants/common.dart'
    show acl, foaf, ldp, rdf, rdfs, terms, vcard, xsd;

// /// Predicates schema.

// const String yarrabahPredicates = 'http://yarrabah.net/predicates#';

// /// Survey schema.

// const String yarrabahPredicatesSurvey =
//     'http://yarrabah.net/predicates/survey#';

// /// Medical schema.

// const String yarrabahPredicatesMedical =
//     'http://yarrabah.net/predicates/medical#';

// /// Solid Health schema.

// const String yarrabahSolidHealth = 'http://yarrabah.net/data/solid-health#';

// /// Analytic schema.

// const String yarrabahPredicatesAnalytic =
//     'http://yarrabah.net/predicates/analytic#';

// /// Terms schema.

// const String yarrabahPredicatesTerms = 'http://yarrabah.net/predicates/terms#';

// /// Data schema.

// const String yarrabahPredicatesData = 'http://yarrabah.net/predicates/data#';

// /// File schema.

// const String yarrabahPredicatesFile = 'http://yarrabah.net/predicates/file#';

// /// Logid schema.

// const String yarrabahPredicatesLogid = 'http://yarrabah.net/predicates/logid#';

// /// Activity Logid schema.
// const String yarrabahPredicatesActLogid =
//     'http://yarrabah.net/predicates/activityLogid#';

// /// SII schema.

// const String siiSolidHealth = 'http://sii.cecs.anu.edu.au/onto/solid-health#';

// /// Vcard schema.

// const String httpVcard = 'http://www.w3.org/2006/vcard/ns#';

// /// Http Basic Container schema.

// const String httpContainer = '${httpNsIdp}BasicContainer';

// /// Http Resource schema.

// const String httpResource = '${httpNsIdp}Resource';

// /// Http Ns schema.

// const String httpNsIdp = 'http://www.w3.org/ns/ldp#';

// /// Http Solid schema.

// const String httpSolidTerms = 'http://www.w3.org/ns/solid/terms#';

// /// Http XMLS schema.

// const String httpXMLSchema = 'http://www.w3.org/2001/XMLSchema#';

// /// Http Pim schema.

// const String httpPimSpace = 'http://www.w3.org/ns/pim/space#';

// /// Http schema.

// const String httpSchema = 'http://schema.org/';

// /// RDF schema.

// const String rdfSchema = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

// /// OWL schema.

// const String owlSchema = 'http://www.w3.org/2002/07/owl#';

// /// RDFS schema.

// const String rdfsSchema = 'http://www.w3.org/2000/01/rdf-schema#';

// /// SDO schema.

// const String sdoSchema = 'https://schema.org/';

// /// SOLID page URL.
// const SOLID_PAGE_URL = "https://yarrabah.net/";

// /// SOLID register URL.
// const SOLID_REGISTER_URL = "/idp/register/";

// /// SOLID server URL.
// const SOLID_SERVER_URL = "https://solid.yarrabah.net/";

// /// Medical reference constants.
// const WAIST_HEIGHT_RATIO_REFERENCE_URL =
//     "https://www.health.gov.au/topics/overweight-and-obesity/bmi-and-waist";

/// Namespaces and their prefixes used in TTL file

typedef NS = ({String prefix, Namespace ns});

///

final NS aclNS = (prefix: 'acl', ns: Namespace(ns: acl));

///

final NS foafNS = (prefix: 'foaf', ns: Namespace(ns: foaf));

///

final NS ldpNS = (prefix: 'ldp', ns: Namespace(ns: ldp));

///

final NS rdfNS = (prefix: 'rdf', ns: Namespace(ns: rdf));

///

final NS rdfsNS = (prefix: 'rdfs', ns: Namespace(ns: rdfs));

///

final NS termsNS = (prefix: 'terms', ns: Namespace(ns: terms));

///

final NS vcardNS = (prefix: 'vcard', ns: Namespace(ns: vcard));

///

final NS xsdNS = (prefix: 'xsd', ns: Namespace(ns: xsd));

///
final NS solidTermsNS = (prefix: 'solidTerms', ns: Namespace(ns: appsTerms));

/// Xmlns schema.

String httpFoaf = foaf;

/// Terms schema.

String httpDcTerms = terms;

/// Title schema.

String httpTitle = '${httpDcTerms}title';

/// Auth Acl schema.

String httpAuthAcl = acl;

/// File predicate

const String appsFile = 'https://solidcommunity.au/predicates/file#';

/// Resource ID predicate

const String appsResId = 'https://solidcommunity.au/predicates/resourceid#';

/// Terms predicate

const String appsTerms = 'https://solidcommunity.au/predicates/terms#';

/// Log ID predicate

const String appsLogId = 'https://solidcommunity.au/predicates/logid#';

/// Data predicate

const String appsData = 'https://solidcommunity.au/predicates/data#';

/// Placeholder of namespace for SII customised predicates
const String sii = 'https://solidproject.au/sii/';

/// SII namespace
final NS siiNS = (prefix: 'sii', ns: Namespace(ns: sii));

/// SII customised predicates
enum SIIPredicate {
  /// Initialization vector (base64 encoded) for AES en-/de-cryption
  ivB64('ivB64'),

  /// AES encrypted data
  ciphertext('ciphertext'),

  /// Resource path
  filePath('filePath'),

  /// AES encrypted individual key for en-/de-crypt individual file
  encryptionKey('encryptionKey'),

  /// AES encrypted RSA private key
  privateKey('privateKey'),

  /// Verification code of the security key
  securityKeyCheck('securityKeyCheck'),

  /// Trimed RSA public key
  publicKey('publicKey'),

  /// Data chunk
  dataChunk('dataChunk'),

  /// Data size in bytes
  dataSize('dataSize');

  /// Generative enum constructor
  const SIIPredicate(this._value);

  /// String value of access predicate
  final String _value;

  /// Return the URIRef of predicate
  URIRef get uriRef => URIRef('$sii$_value');
}
