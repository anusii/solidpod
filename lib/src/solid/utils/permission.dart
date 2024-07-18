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
/// Authors: Dawei Chen, Anushka Vidanage

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
  Map<String, Set<AccessMode>>? groupAccess,
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
    URIRef(ownerWebId!): [AclPredicate.agent.uriRef, ownerAccess],
    if (thirdPartyAccess != null && thirdPartyAccess.isNotEmpty) ...{
      for (final entry in thirdPartyAccess.entries)
        URIRef(entry.key): [AclPredicate.agent.uriRef, entry.value]
    },
    if (groupAccess != null && groupAccess.isNotEmpty) ...{
      for (final entry in groupAccess.entries)
        URIRef(entry.key): [AclPredicate.agentGroup.uriRef, entry.value]
    },
    if (publicAccess != null && publicAccess.isNotEmpty) ...{
      publicAgent: [AclPredicate.agentClass.uriRef, publicAccess],
    },
    if (authUserAccess != null && authUserAccess.isNotEmpty) ...{
      authenticatedAgent: [AclPredicate.agentClass.uriRef, authUserAccess],
    },
  });

  // Create acl triples
  final triples = <URIRef, Map<URIRef, dynamic>>{};
  for (final entry in accessMap.entries) {
    if (entry.value.isNotEmpty) {
      triples[thisFile.ns.withAttr(entry.key.mode)] = {
        AclPredicate.aclRdfType.uriRef: aclAuthorization,
        AclPredicate.accessTo.uriRef: r,

        // This seems necessary for accessing resources in a container
        if (!fileFlag) AclPredicate.defaultAccess.uriRef: r,

        for (final agentEntry in entry.value.entries) ...{
          agentEntry.key: agentEntry.value,
        },
        AclPredicate.aclMode.uriRef: entry.key.uriRef,
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

Map<AccessMode, Map<URIRef, Set<URIRef>>> getAccessMap(
    Map<URIRef, List<dynamic>> permissions) {
  final accessMap = {
    for (final mode in [
      AccessMode.read,
      AccessMode.write,
      AccessMode.control,
      AccessMode.append,
    ])
      mode: <URIRef, Set<URIRef>>{}
  };

  for (final uriRef in permissions.keys) {
    final agent = permissions[uriRef]!.first;
    final modes = permissions[uriRef]!.last;
    for (final mode in modes as Set) {
      if (accessMap[mode]!.containsKey(agent)) {
        accessMap[mode]![agent]!.add(uriRef);
      } else {
        accessMap[mode]![agent as URIRef] = {uriRef};
      }
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
