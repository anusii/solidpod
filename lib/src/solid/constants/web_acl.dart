/// Constants defined in the Web Access Control specification.
/// https://solidproject.org/TR/wac
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
/// Authors: Dawei Chen, Anushka Vidanage

library;

import 'package:rdflib/rdflib.dart' show Namespace, URIRef;
import 'package:solidpod/src/solid/constants/common.dart'
    show
        acl,
        agentClassPred,
        agentGroupPred,
        agentPred,
        foaf,
        rdf,
        terms,
        vcard;
import 'package:solidpod/src/solid/constants/schema.dart'
    show NS, aclNS, appsTerms, solidTermsNS, termsNS, vcardNS;
import 'package:solidpod/src/solid/utils/rdf.dart';

/// Namespace of the file itself
final NS thisFile = (prefix: '', ns: Namespace(ns: '#'));

/// URI of the directory itself
final thisDir = URIRef('./');

/// Namespaces to bind

final bindAclNamespaces = {
  thisFile.prefix: thisFile.ns,
  aclNS.prefix: aclNS.ns,
  // foafNS.prefix: foafNS.ns, // already binded in rdflib
  // rdfNS.prefix: rdfNS.ns // already binded in rdflib
};

/// TODO:av - Move the class Predicate to a common location and
/// add all the other relavant predicates

/// Predicates for web access control

enum AclPredicate {
  /// Predicate of acl:Authorization
  aclRdfType('${rdf}type'),

  /// Operations the agents can perform on a resource
  aclMode('${acl}mode'),

  /// Vcard group predicate
  vcardGroup('${vcard}Group'),

  /// Vcard has member predicate
  vcardHasMember('${vcard}hasMember'),

  /// Personal profile document predicate
  personalDocument('${foaf}PersonalProfileDocument'),

  /// Title predicate
  title('${terms}title'),

  /// The resource to which access is being granted
  accessTo('${acl}accessTo'),

  /// The container resource whose Authorization can be applied to
  /// a resource lower in the collection hierarchy,
  /// i.e., inheriting the authorizations
  defaultAccess('${acl}default'),

  /// An agent being given access permission
  agent('${acl}agent'),

  /// A class of agents being given access permission
  agentClass('${acl}agentClass'),

  /// A group of agents being given access permission
  agentGroup('${acl}agentGroup'),

  /// Origin of an HTTP request being given access permission
  origin('${acl}origin'),

  /// The owner of a resource
  owner('${acl}owner');

  /// Generative enum constructor
  const AclPredicate(this._value);

  /// String value of access predicate
  final String _value;

  /// Return the URIRef of predicate
  URIRef get uriRef => URIRef(_value);

  /// Return the string of predicate
  String get value => _value;
}

/// Mode of access to a resource

enum AccessMode {
  /// Read access
  read('Read', 'permission to read the content of the shared file'),

  /// Write access
  write(
    'Write',
    'permission to add/delete/modify content to/from the shared file',
  ),

  /// Control access: read and write access to the ACL file
  control(
    'Control',
    'permission to alter the access permission to the shared file',
  ),

  /// Append data (a type of write)
  append(
    'Append',
    'permission to add content but not remove or modify content from the shared file',
  );

  /// Constructor
  const AccessMode(this._value, this._description);

  /// String value of the access type
  final String _value;

  /// String value of the access type
  final String _description;

  /// Return the URIRef
  URIRef get uriRef => URIRef('$acl$_value');

  /// Return the mode
  String get mode => _value;

  /// Return the description of access mode
  String get description => _description;
}

/// Return access mode based on a given String value
AccessMode getAccessMode(String mode) {
  switch (mode.toLowerCase()) {
    case 'read':
      return AccessMode.read;
    case 'write':
      return AccessMode.write;
    case 'control':
      return AccessMode.control;
    default:
      return AccessMode.append;
  }
}

/// Type of access recipient to a resource

enum RecipientType {
  /// Public
  public('Public'),

  /// Authenticated users
  authUser('Authenticated Users'),

  /// Individual WebID
  individual('Individual'),

  /// Group of WebIDs
  group('Group'),

  /// No recipient
  none('');

  /// Constructor
  const RecipientType(this._value);

  /// String value of the recipient type
  final String _value;

  /// Return type
  String get type => _value;
}

/// Get agent types as a human readable string
RecipientType getRecipientType(String agentType, String receiverUri) {
  late RecipientType recipientType;

  if (agentType == agentPred) {
    recipientType = RecipientType.individual;
  } else if (agentType == agentGroupPred) {
    recipientType = RecipientType.group;
  } else if (agentType == agentClassPred) {
    if (URIRef(receiverUri) == publicAgent) {
      recipientType = RecipientType.public;
    } else if (URIRef(receiverUri) == authenticatedAgent) {
      recipientType = RecipientType.authUser;
    }
  }
  return recipientType;
}

/// Generate the content of encKeyFile
Future<String> genGroupWebIdTTLStr(List<dynamic> groupWebIdList) async {
  var triples = <URIRef, Map<URIRef, dynamic>>{};
  triples = {
    URIRef('${thisFile.ns.ns}me'): {
      AclPredicate.aclRdfType.uriRef: AclPredicate.vcardGroup.uriRef,
      AclPredicate.vcardHasMember.uriRef: {
        for (final webId in groupWebIdList) ...{
          URIRef(webId as String),
        },
      },
    },
  };

  final bindNS = {
    thisFile.prefix: thisFile.ns,
    vcardNS.prefix: vcardNS.ns,
  };

  return tripleMapToTurtle(triples, bindNamespaces: bindNS);
}

/// Generate the content of pubKeyFile
Future<String> genUserClassIndKeyTTLStr([List<String>? initialDataList]) async {
  if (initialDataList != null) {
    assert(initialDataList.length == 2);
  }
  var triples = <URIRef, Map<URIRef, dynamic>>{};
  triples = {
    URIRef('${thisFile.ns.ns}me'): {
      AclPredicate.aclRdfType.uriRef: {
        AclPredicate.personalDocument.uriRef,
      },
    },
    if (initialDataList != null) ...{
      URIRef(initialDataList.first): {
        URIRef('${appsTerms}sessionKey'): initialDataList.last,
      },
    },
  };

  final bindNS = {
    thisFile.prefix: thisFile.ns,
    solidTermsNS.prefix: solidTermsNS.ns,
    termsNS.prefix: termsNS.ns,
  };

  return tripleMapToTurtle(triples, bindNamespaces: bindNS);
}

/// Two objects/values for predicate acl:agentClass
/// foaf:Agent for public access
/// acl:AutenticatedAgent for allowing access by authenticated agents

/// Allows access to any agent, i.e., the public
final publicAgent = URIRef('${foaf}Agent');

/// Allows access to any authenticated agent
final authenticatedAgent = URIRef('${acl}AuthenticatedAgent');

// Object representing a group of persons or entities,
// members of a group are usually specified by the hasMember property.
// vcard:Group,

// To include a member in an agent group
// vcard:hasMember';

// An applicable Authorization has the following properties:
// - At least one rdf:type property whose object is acl:Authorization.
// - At least one acl:accessTo or acl:default property value (Access Objects).
// - At least one acl:mode property value (Access Modes).
// - At least one acl:agent, acl:agentGroup, acl:agentClass or acl:origin
//   property value (Access Subjects).

/// Object of rdf:type
final aclAuthorization = URIRef('${acl}Authorization');
