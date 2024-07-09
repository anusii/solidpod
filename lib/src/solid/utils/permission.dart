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
import 'package:solidpod/src/solid/api/rest_api.dart';

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/utils/rdf.dart'
    show parseACL, tripleMapToTurtle;

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
  Set<AccessMode>? authUserAccess,
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
    if (publicAccess != null && publicAccess.isNotEmpty) ...{
      publicAgent: publicAccess,
    },
    if (authUserAccess != null && authUserAccess.isNotEmpty) ...{
      authenticatedAgent: authUserAccess,
    },
  });

  // Create acl triples
  final triples = <URIRef, Map<URIRef, dynamic>>{};
  for (final entry in accessMap.entries) {
    if (entry.value.isNotEmpty) {
      var agentClassAccess = false;
      final agentClassSet = <URIRef>{};

      if (entry.value.contains(publicAgent)) {
        agentClassAccess = true;
        agentClassSet.add(publicAgent);
        entry.value.remove(publicAgent);
      }

      if (entry.value.contains(authenticatedAgent)) {
        agentClassAccess = true;
        agentClassSet.add(authenticatedAgent);
        entry.value.remove(authenticatedAgent);
      }

      triples[thisFile.ns.withAttr(entry.key.mode)] = {
        Predicate.aclRdfType.uriRef: aclAuthorization,
        Predicate.accessTo.uriRef: r,
        if (agentClassAccess) ...{
          Predicate.agentClass.uriRef: agentClassSet,
        },
        if (entry.value.isNotEmpty) ...{
          Predicate.agent.uriRef: entry.value,
        },
        Predicate.aclMode.uriRef: entry.key.uriRef,
      };
    }
  }

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

/// Retrieves the permission details of a file from the respective ACL file.
///
/// Returns a Future that completes with a Map containing the permission data.
/// The Map structure is defined by the REST API response.
Future<Map<dynamic, dynamic>> readAcl(String resourceUrl,
    [bool fileFlag = true]) async {
  final resourceAclUrl = getResAclFile(resourceUrl, fileFlag);

  final aclContent = await fetchPrvFile(resourceAclUrl);
  return parseACL(aclContent);
}
