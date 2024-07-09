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
import 'package:solidpod/src/solid/utils/rdf.dart' show tripleMapToTurtle;

/// Generate TTL string for ACL file of a given resource
Future<String> genAclTurtle(
  String resourceUrl, {
  bool fileFlag = true,
  Set<AccessMode> ownerAccess = const {
    AccessMode.read,
    AccessMode.write,
    AccessMode.control,
  },
  Set<AccessMode>? publicAccess,
  Map<String, Set<AccessMode>>? thirdPartyAccess,
}) async {
  // The resource should not be an ACL file
  assert(!resourceUrl.endsWith('.acl'));

  // The resource to be accessed
  final r = fileFlag ? URIRef(resourceUrl.split('/').last) : thisDir;

  final ownerWebId = await AuthDataManager.getWebId();
  assert(ownerWebId != null);
  if (thirdPartyAccess != null) {
    assert(!thirdPartyAccess.containsKey(ownerWebId));
  }

  final accessMap = getAccessMap({
    URIRef(ownerWebId!): ownerAccess,
    if (thirdPartyAccess != null) ...{
      for (final entry in thirdPartyAccess.entries)
        URIRef(entry.key): entry.value
    },
  });

  final triples = {
    for (final entry in accessMap.entries)
      if (entry.value.isNotEmpty)
        thisFile.ns.withAttr(entry.key.mode): {
          AclPredicate.aclRdfType.uriRef: aclAuthorization,
          AclPredicate.accessTo.uriRef: r,
          AclPredicate.agent.uriRef: entry.value,
          if (publicAccess != null && publicAccess.contains(entry.key))
            AclPredicate.agentClass.uriRef: publicAgent,
          AclPredicate.aclMode.uriRef: entry.key.uriRef,
        },
  };

  // Bind namespaces

  const prefix = 'c';
  final bindNS = {
    ...bindAclNamespaces,
    '${prefix}0': Namespace(ns: '${Uri.parse(ownerWebId).removeFragment()}#'),
  };

  if (thirdPartyAccess != null) {
    var k = 1;
    for (final webId in thirdPartyAccess.keys) {
      bindNS['$prefix$k'] =
          Namespace(ns: '${Uri.parse(webId).removeFragment()}#');
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
