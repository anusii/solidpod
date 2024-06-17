/// Utilities for working on Turtle (Terse RDF Triple Language) formated string.
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
/// Authors: Dawei Chen

library;

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/src/solid/constants.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';

/// Generate TTL string from triples stored in a map:
/// {subject: {predicate: object}}
/// where
/// - subject: usually the URL of a file
/// - predicate-object: the key-value pairs to be stores in the file

String tripleMapToTTLStr(Map<String, Map<String, String>> tripleMap) {
  assert(tripleMap.isNotEmpty);
  final g = Graph();
  final nsTerms = Namespace(ns: appsTerms);
  final nsTitle = Namespace(ns: terms);

  for (final sub in tripleMap.keys) {
    assert(tripleMap[sub] != null && tripleMap[sub]!.isNotEmpty);
    final f = URIRef(sub);
    for (final pre in tripleMap[sub]!.keys) {
      final obj = tripleMap[sub]![pre] as String;
      final ns = (pre == titlePred) ? nsTitle : nsTerms;
      g.addTripleToGroups(f, ns.withAttr(pre), obj);
    }
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}

/// Parse TTL content into a map {subject: {predicate: object}}
Map<String, dynamic> parseTTL(String ttlContent) {
  final g = Graph();
  g.parseTurtle(ttlContent);
  final dataMap = <String, dynamic>{};
  String extract(String str) => str.contains('#') ? str.split('#')[1] : str;
  for (final t in g.triples) {
    final sub = extract(t.sub.value as String);
    final pre = extract(t.pre.value as String);
    final obj = extract(t.obj.value as String);
    if (dataMap.containsKey(sub)) {
      assert(!(dataMap[sub] as Map).containsKey(pre));
      dataMap[sub][pre] = obj;
    } else {
      dataMap[sub] = {pre: obj};
    }
  }
  return dataMap;
}

/// Generate TTL string for ACL file of a given resource
Future<String> genAclTTLStr(String resourceUrl,
    {AccessType ownerAccess = AccessType.control,
    AccessType publicAccess = AccessType.read}) async {
  final webId = await AuthDataManager.getWebId();
  assert(webId != null);

  final g = Graph();
  final f = URIRef(resourceUrl);
  final nsSub = Namespace(ns: '$resourceUrl.acl#');
  final nsAcl = Namespace(ns: acl);
  final nsFoaf = Namespace(ns: foaf);
  final nsSyntax = Namespace(ns: rdfSyntax);

  // URIRef(RESOURCE_URL.acl#owner):
  // 	       URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://www.w3.org/ns/auth/acl#Authorization'),
  //         URIRef('http://www.w3.org/ns/auth/acl#accessTo'): URIRef(RESOURCE_URL),
  //         URIRef('http://www.w3.org/ns/auth/acl#agent'): URIRef(WEB_ID),
  //         URIRef('http://www.w3.org/ns/auth/acl#mode'): URIRef('http://www.w3.org/ns/auth/acl#Control')},

  final ownerSub = nsSub.withAttr('owner');
  g.addTripleToGroups(
      ownerSub, nsSyntax.withAttr(typePred), nsAcl.withAttr(aclAuth));
  g.addTripleToGroups(ownerSub, nsAcl.withAttr(accessToPred), f);
  g.addTripleToGroups(ownerSub, nsAcl.withAttr(agentPred), URIRef(webId!));
  g.addTripleToGroups(
      ownerSub, nsAcl.withAttr(modePred), nsAcl.withAttr(ownerAccess.value));

  // URIRef(RESOURCE_URL.acl#public'):
  //    URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://www.w3.org/ns/auth/acl#Authorization'),
  //    URIRef('http://www.w3.org/ns/auth/acl#accessTo'): URIRef(RESOURCE_URL),
  //    URIRef('http://www.w3.org/ns/auth/acl#agentClass'): URIRef('http://xmlns.com/foaf/0.1/Agent'),
  //    URIRef('http://www.w3.org/ns/auth/acl#mode'): URIRef('http://www.w3.org/ns/auth/acl#Read')

  final publicSub = nsSub.withAttr('public');
  g.addTripleToGroups(
      publicSub, nsSyntax.withAttr(typePred), nsAcl.withAttr(aclAuth));
  g.addTripleToGroups(publicSub, nsAcl.withAttr(accessToPred), f);
  g.addTripleToGroups(
      publicSub, nsAcl.withAttr(agentClassPred), nsFoaf.withAttr(aclAgent));
  g.addTripleToGroups(
      publicSub, nsAcl.withAttr(modePred), nsAcl.withAttr(publicAccess.value));

  // Bind the long namespace to shorter string for better readability

  g.bind('acl', nsAcl);
  // g.bind('foaf', nsFoaf); // causes "Exception: foaf: already exists in prefixed namespaces!"
  g.bind('syntax', nsSyntax);

  // Serialise to TTL string

  g.serialize(abbr: 'short');

  return g.serializedString;
}

/// Generate permission log file content
Future<String> genPermLogTTLStr(String resourceUrl) async {
  final g = Graph();
  final f = URIRef(resourceUrl);
  final nsTerm = Namespace(ns: terms);
  final nsFoaf = Namespace(ns: foaf);
  final nsSyntax = Namespace(ns: rdfSyntax);

  // URIRef(RESOURCE_URL):
  //     URIRef('http://purl.org/dc/terms/title'): Literal('Permissions Log'),
  //     URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://xmlns.com/foaf/0.1/PersonalProfileDocument')

  g.addTripleToGroups(f, nsTerm.withAttr(titlePred), logFileTitle);
  g.addTripleToGroups(
      f, nsSyntax.withAttr(typePred), nsFoaf.withAttr(profileDoc));

// Bind the long namespace to shorter string for better readability

  g.bind('terms', nsTerm);
  // g.bind('foaf', nsFoaf);
  g.bind('syntax', nsSyntax);

  // Serialise to TTL string

  g.serialize(abbr: 'short');

  return g.serializedString;
}
