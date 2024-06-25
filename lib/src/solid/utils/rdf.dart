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
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';

// /// Create and return a namespace
// Namespace getNamespace(String ns) => Namespace(ns: ns);

// /// Create and return a URIRef
// URIRef getURIRef(String url) => URIRef(url);

// /// Create and return a URIRef with given namespace and attribute
// URIRef getURIRefFromNS(Namespace ns, String attr) => ns.withAttr(attr);

/// Generate Turtle string from triples stored in a map:
/// {subject: {predicate: {object}}}
/// - subject: URIRef String
/// - predicate: URIRef String
/// - object: {dynamic}
String tripleMapToTurtle(Map<URIRef, Map<URIRef, dynamic>> triples,
    {Map<String, Namespace>? bindNamespaces}) {
  final g = Graph();

  for (final sub in triples.keys) {
    final predMap = triples[sub];
    for (final pre in predMap!.keys) {
      final objs = predMap[pre];
      final objSet = objs is Iterable ? Set.from(objs) : {objs};

      for (final obj in objSet) {
        g.addTripleToGroups(sub, pre, obj);
      }
    }
  }

  if (bindNamespaces != null) {
    bindNamespaces.forEach(g.bind);
    print('To bind: ${[for (final ns in bindNamespaces.values) ns.ns]}');
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}

/// Generate TTL string from triples stored in a map:
/// {subject: {predicate: object}}
/// where
/// - subject: usually the URL of a file
/// - predicate-object: the key-value pairs to be stores in the file

String tripleMapToTTLStr(Map<String, Map<String, String>> tripleMap) {
  assert(tripleMap.isNotEmpty);
  final g = Graph();
  final nsTerms = Namespace(ns: appsTerms);

  for (final sub in tripleMap.keys) {
    assert(tripleMap[sub] != null && tripleMap[sub]!.isNotEmpty);
    final f = URIRef(sub);
    for (final pre in tripleMap[sub]!.keys) {
      final obj = tripleMap[sub]![pre] as String;
      final ns = (pre == titlePred) ? termsNS.ns : nsTerms;
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

/// Parse ACL content into a map {subject: {predicate: object}}
Map<String, dynamic> parseACL(String aclContent) {
  final g = Graph();
  g.parseTurtle(aclContent);
  final dataMap = <String, dynamic>{};
  String extract(String str) => str.contains('#') ? str.split('#')[1] : str;
  for (final t in g.triples) {
    final sub = extract(t.sub.value as String);
    final pre = extract(t.pre.value as String);
    var obj = '';
    if (pre == 'agent') {
      obj = t.obj.value as String;
    } else {
      obj = extract(t.obj.value as String);
    }

    if (dataMap.containsKey(sub)) {
      if ((dataMap[sub] as Map).containsKey(pre)) {
        dataMap[sub][pre].add(obj);
      } else {
        dataMap[sub][pre] = [obj];
      }
    } else {
      dataMap[sub] = {
        pre: [obj]
      };
    }
  }
  return dataMap;
}

// /// Generate TTL string for ACL file of a given resource
// Future<String> genAclTTLStr(String resourceUrl,
//     {AccessMode ownerAccess = AccessMode.control,
//     AccessMode publicAccess = AccessMode.read}) async {
//   final webId = await AuthDataManager.getWebId();
//   assert(webId != null);

//   final g = Graph();
//   final f = URIRef(resourceUrl);
//   final nsSub = Namespace(ns: '$resourceUrl.acl#');

//   // URIRef(RESOURCE_URL.acl#owner):
//   // 	       URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://www.w3.org/ns/auth/acl#Authorization'),
//   //         URIRef('http://www.w3.org/ns/auth/acl#accessTo'): URIRef(RESOURCE_URL),
//   //         URIRef('http://www.w3.org/ns/auth/acl#agent'): URIRef(WEB_ID),
//   //         URIRef('http://www.w3.org/ns/auth/acl#mode'): URIRef('http://www.w3.org/ns/auth/acl#Control')},

//   final ownerSub = nsSub.withAttr('owner');
//   g.addTripleToGroups(
//       ownerSub, rdfNS.ns.withAttr(typePred), aclNS.ns.withAttr(aclAuth));
//   g.addTripleToGroups(ownerSub, aclNS.ns.withAttr(accessToPred), f);
//   g.addTripleToGroups(ownerSub, aclNS.ns.withAttr(agentPred), URIRef(webId!));
//   g.addTripleToGroups(ownerSub, aclNS.ns.withAttr(modePred),
//       aclNS.ns.withAttr(ownerAccess.mode));

//   // URIRef(RESOURCE_URL.acl#public'):
//   //    URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://www.w3.org/ns/auth/acl#Authorization'),
//   //    URIRef('http://www.w3.org/ns/auth/acl#accessTo'): URIRef(RESOURCE_URL),
//   //    URIRef('http://www.w3.org/ns/auth/acl#agentClass'): URIRef('http://xmlns.com/foaf/0.1/Agent'),
//   //    URIRef('http://www.w3.org/ns/auth/acl#mode'): URIRef('http://www.w3.org/ns/auth/acl#Read')

//   final publicSub = nsSub.withAttr('public');
//   g.addTripleToGroups(
//       publicSub, rdfNS.ns.withAttr(typePred), aclNS.ns.withAttr(aclAuth));
//   g.addTripleToGroups(publicSub, aclNS.ns.withAttr(accessToPred), f);
//   g.addTripleToGroups(publicSub, aclNS.ns.withAttr(agentClassPred),
//       foafNS.ns.withAttr(aclAgent));
//   g.addTripleToGroups(publicSub, aclNS.ns.withAttr(modePred),
//       aclNS.ns.withAttr(publicAccess.mode));

//   // Bind the long namespace to shorter string for better readability

//   g.bind(aclNS.prefix, aclNS.ns);
//   // g.bind('foaf', nsFoaf); // causes "Exception: foaf: already exists in prefixed namespaces!"
//   g.bind(rdfNS.prefix, rdfNS.ns);

//   // Serialise to TTL string

//   g.serialize(abbr: 'short');

//   return g.serializedString;
// }

/// Generate permission log file content
Future<String> genPermLogTTLStr(String resourceUrl) async {
  final g = Graph();
  final f = URIRef(resourceUrl);

  // URIRef(RESOURCE_URL):
  //     URIRef('http://purl.org/dc/terms/title'): Literal('Permissions Log'),
  //     URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://xmlns.com/foaf/0.1/PersonalProfileDocument')

  g.addTripleToGroups(f, termsNS.ns.withAttr(titlePred), logFileTitle);
  g.addTripleToGroups(
      f, rdfNS.ns.withAttr(typePred), foafNS.ns.withAttr(profileDoc));

// Bind the long namespace to shorter string for better readability

  g.bind(termsNS.prefix, termsNS.ns);
  // g.bind('foaf', nsFoaf);
  g.bind(rdfNS.prefix, rdfNS.ns);

  // Serialise to TTL string

  g.serialize(abbr: 'short');

  return g.serializedString;
}
