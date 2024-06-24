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

import 'package:rdflib/rdflib.dart' show URIRef;

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Generate TTL string for ACL file of a given resource
Future<String> genAclTurtle(
  String resourceUrl, {
  bool fileFlag = true,
  Set<AccessMode>? ownerAccessModes,
  Set<AccessMode>? publicAccessModes,
  Map<String, Set<AccessMode>>? thirdPartyAccess,
}) async {
  // URIRef(RESOURCE_URL.acl#owner):
  // 	       URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://www.w3.org/ns/auth/acl#Authorization'),
  //         URIRef('http://www.w3.org/ns/auth/acl#accessTo'): URIRef(RESOURCE_URL),
  //         URIRef('http://www.w3.org/ns/auth/acl#agent'): URIRef(WEB_ID),
  //         URIRef('http://www.w3.org/ns/auth/acl#mode'): URIRef('http://www.w3.org/ns/auth/acl#Control')},
  //
  // URIRef(RESOURCE_URL.acl#public'):
  //    URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'): URIRef('http://www.w3.org/ns/auth/acl#Authorization'),
  //    URIRef('http://www.w3.org/ns/auth/acl#accessTo'): URIRef(RESOURCE_URL),
  //    URIRef('http://www.w3.org/ns/auth/acl#agentClass'): URIRef('http://xmlns.com/foaf/0.1/Agent'),
  //    URIRef('http://www.w3.org/ns/auth/acl#mode'): URIRef('http://www.w3.org/ns/auth/acl#Read')

  // The resource to be accessed
  final r = fileFlag ? URIRef(resourceUrl.split('/').last) : thisDir;

  // Full access for owner
  ownerAccessModes ??= {
    AccessMode.read,
    AccessMode.write,
    AccessMode.control,
  };

  final accessMap = {
    AccessMode.read: <String>{},
    AccessMode.write: <String>{},
    AccessMode.control: <String>{},
    AccessMode.append: <String>{},
  };
  final agents = <String>{};

  final c0 = await AuthDataManager.getWebId() as String;
  agents.add(c0);
  ownerAccessModes.forEach((mode) => accessMap[mode]!.add(c0));

  if (publicAccessModes != null) {
    agents.add(publicAgent.value);
    publicAccessModes
        .forEach((mode) => accessMap[mode]!.add(publicAgent.value));
  }

  if (thirdPartyAccess != null) {
    for (final webId in thirdPartyAccess.keys) {
      agents.add(webId);
      thirdPartyAccess[webId]!.forEach((mode) => accessMap[mode]!.add(webId));
    }
  }

  // Returns map {predicate: object | {objects}}
  Map<URIRef, dynamic> getPredicateMap(
    Predicate accessSubjectPred,
    URIRef accessSubjectVal,
    Set<AccessMode> accessModes,
  ) =>
      {
        Predicate.aclRdfType.uriRef: aclAuthorization,
        Predicate.accessTo.uriRef: r,
        accessSubjectPred.uriRef: accessSubjectVal,
        Predicate.aclMode.uriRef: {for (final m in accessModes) m.uriRef},
      };

  final triples = {
    thisFile.ns.withAttr('owner'): getPredicateMap(Predicate.agent,
        URIRef(await AuthDataManager.getWebId() as String), ownerAccessModes),
    if (publicAccessModes != null)
      thisFile.ns.withAttr('public'):
          getPredicateMap(Predicate.agentClass, publicAgent, publicAccessModes),
  };

  if (thirdPartyAccess != null) {
    thirdPartyAccess.forEach((webId, accessModes) => triples[URIRef(webId)] =
        getPredicateMap(Predicate.agent, URIRef(webId), accessModes));
  }

  return tripleMapToTurtle(triples, bindNamespaces: bindAclNamespaces);
}
