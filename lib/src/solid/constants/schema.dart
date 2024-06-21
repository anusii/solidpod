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
/// Authors: Anushka Vidanage

library;

import 'package:solidpod/src/solid/constants.dart';

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

/// Xmlns schema.

String httpFoaf = foaf.ns.ns;

/// Terms schema.

String httpDcTerms = terms.ns.ns;

/// Title schema.

String httpTitle = '${httpDcTerms}title';

/// Auth Acl schema.

String httpAuthAcl = acl.ns.ns;

/// File predicate

const String appsFile = 'https://solidcommunity.au/predicates/file#';

/// Terms predicate

const String appsTerms = 'https://solidcommunity.au/predicates/terms#';

/// Log ID predicate

const String appsLogId = 'https://solidcommunity.au/predicates/logid#';

/// Data predicate

const String appsData = 'https://solidcommunity.au/predicates/data#';
