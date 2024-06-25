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

import 'package:rdflib/rdflib.dart' show URIRef, Namespace;

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Generate TTL string for ACL file of a given resource
Future<String> genAclTurtle(
  String resourceUrl, {
  bool fileFlag = true,
  Set<AccessMode>? ownerAccess,
  Set<AccessMode>? publicAccess,
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
  ownerAccess ??= {
    AccessMode.read,
    AccessMode.write,
    AccessMode.control,
  };

  final webId = await AuthDataManager.getWebId();
  assert(webId != null);
  if (thirdPartyAccess != null) {
    assert(!thirdPartyAccess.containsKey(webId));
  }

  final accessMap = getAccessMap({
    URIRef(webId!): ownerAccess,
    // if (publicAccess != null) publicAgent: publicAccess,
    if (thirdPartyAccess != null) ...{
      for (final entry in thirdPartyAccess.entries)
        URIRef(entry.key): entry.value
    },
  });

  final triples = {
    for (final entry in accessMap.entries)
      thisFile.ns.withAttr(entry.key.mode): {
        Predicate.aclRdfType.uriRef: aclAuthorization,
        Predicate.accessTo.uriRef: r,
        Predicate.agent.uriRef: entry.value,
        if (publicAccess != null && publicAccess.contains(entry.key))
          Predicate.agentClass.uriRef: publicAgent,
        Predicate.aclMode.uriRef: entry.key.uriRef,
      },
  };

  // Bind namespaces

  const prefix = 'c';
  final bindNS = {
    ...bindAclNamespaces,
    '${prefix}0': Namespace(ns: webId),
  };

  if (thirdPartyAccess != null) {
    var k = 1;
    for (final _webId in thirdPartyAccess.keys) {
      bindNS['$prefix$k'] = Namespace(ns: _webId);
      k++;
    }
  }

  return tripleMapToTurtle(triples, bindNamespaces: bindNS);
}

/// Convert permissions structure from
/// {webId/agent | publicAgent: {AccessMode}}
/// to
/// {AccessMode: {webId/agent | publicAgent}}
Map<AccessMode, Set<URIRef>> getAccessMap(
    Map<URIRef, Set<AccessMode>> permissions) {
  final accessMap = {
    for (final mode in [
      AccessMode.read,
      AccessMode.write,
      AccessMode.control,
      AccessMode.append,
    ])
      mode: <URIRef>{}
  };

  for (final uriRef in permissions.keys) {
    final modes = permissions[uriRef];
    for (final mode in modes!) {
      accessMap[mode]!.add(uriRef);
    }
  }

  return accessMap;
}
