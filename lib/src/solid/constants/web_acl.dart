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

import 'package:rdf/rdf.dart' show Namespace, URIRef;

import 'package:solidpod/src/solid/constants/common.dart'
    show
        acl,
        agentClassPred,
        agentGroupPred,
        agentPred,
        authAgent,
        foaf,
        profCard,
        pubAgent,
        rdf,
        terms,
        vcard;
import 'package:solidpod/src/solid/constants/predicates.dart'
    show PredicateBase;
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
  // foafNS.prefix: foafNS.ns, // already binded in `rdf`
  // rdfNS.prefix: rdfNS.ns // already binded in `rdf`
};

// NOTE: Common predicates (RdfPredicate, FoafPredicate, VcardPredicate,
// DcTermsPredicate, XsdDatatype, CommonAclPredicate) have been defined in
// predicates.dart and are re-exported from this file for convenience.
// The AclPredicate enum below is kept for backward compatibility and combines
// predicates from multiple namespaces for ACL operations.

/// Predicates for web access control operations.
/// This enum combines predicates from multiple namespaces (ACL, FOAF, VCard,
/// DC Terms, RDF) for convenience in ACL file generation.
///
/// For namespace-specific predicates, see the re-exported enums:
/// - [CommonAclPredicate] - Pure ACL predicates
/// - [VcardPredicate] - VCard predicates
/// - [FoafPredicate] - FOAF predicates
/// - [DcTermsPredicate] - Dublin Core Terms predicates
/// - [RdfPredicate] - RDF predicates
enum AclPredicate with PredicateBase {
  /// Predicate of rdf:type (alias for convenience)
  aclRdfType('${rdf}type'),

  /// Operations the agents can perform on a resource (alias)
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

  @override
  String get value => _value;
}

/// Mode of access to a resource

enum AccessMode {
  /// Read access
  read('Read', '''

    **Read:** Permission is granted to read the content of the shared file.

    '''),

  /// Write access
  write('Write', '''

    **Write:** Permission is granted to add/delete/modify the content of the
    shared file.

    '''),

  /// Control access: read and write access to the ACL file
  control('Control', '''

    **Control:** Permission is granted to alter the access permission to the
    shared file

    '''),

  /// Append data (a type of write)
  append('Append', '''

    **Append:** Permission is granted to add content but not remove or modify
    content from the shared file.

    ''');

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

  static List<AccessMode> getAllModes() => [
        AccessMode.read,
        AccessMode.write,
        AccessMode.control,
        AccessMode.append,
      ];
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
    case 'append':
      return AccessMode.append;
    default:
      throw Exception(
        'Wrong access mode given'
        '\nMode: $mode',
      );
  }
}

/// Type of recipient receiving access to a resource

enum RecipientType {
  /// Public
  public('public', 'Public'),

  /// Authenticated users
  authUser('auth', 'Authenticated Users'),

  /// Individual WebID
  individual('indi', 'Individual'),

  /// Group of WebIDs
  group('group', 'Group'),

  /// No recipient type
  none('', 'No Recipient');

  /// Constructor
  const RecipientType(this._value, this._description);

  /// String value of the recipient type
  final String _value;
  String get type => _value;

  /// Recipient type description
  final String _description;
  String get description => _description;

  /// Return the RecipientType with the corresponding value
  static RecipientType getInstanceByValue(String typeValue) {
    Map<String, RecipientType> map = {
      for (var m in RecipientType.values) m._value: m,
    };

    if (map.containsKey(typeValue)) {
      return map[typeValue]!;
    } else {
      throw Exception('Invalid value for RecipientType: $typeValue');
    }
  }
}

/// List of recipient types that comprise specific recipients

const List<RecipientType> specificRecipientTypeList = [
  RecipientType.individual,
  RecipientType.group,
];

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

/// Get recipient name from recipient webId
String getRecipientName({
  required String recipientWebId,
  required RecipientType recipientType,
}) {
  final String recipientName;

  if (recipientType == RecipientType.public) {
    recipientName = 'Anyone';
  } else if (recipientType == RecipientType.authUser) {
    recipientName = 'All Loggedin Users';
  } else {
    recipientName = recipientWebId.replaceAll('/$profCard', '').split('/').last;
  }

  return recipientName;
}

/// Get name from webId
String getWebIdName({
  required String webId,
}) {
  final String name;

  if (webId == pubAgent) {
    name = 'Anyone';
  } else if (webId == authAgent) {
    name = 'All Loggedin Users';
  } else {
    name = webId.replaceAll('/$profCard', '').split('/').last;
  }

  return name;
}

/// Get name from webId
String getPermissionTypeLabel({
  required String permissionType,
}) {
  final String permissionTypeLabel;

  if (permissionType == 'grant') {
    permissionTypeLabel = 'granted';
  } else if (permissionType == 'revoke') {
    permissionTypeLabel = 'revoked';
  } else {
    permissionTypeLabel = 'unknown';
  }

  return permissionTypeLabel;
}

/// Get tooltip for ACL permission records
String getPermissionTooltip({
  required String recipientName,
  required RecipientType recipientType,
  required List<String> permList,
}) {
  String toolTip;

  if (recipientType == RecipientType.public) {
    toolTip = 'Accessible with ${permList.join(', ')}'
        ' access to anyone';
  } else if (recipientType == RecipientType.authUser) {
    toolTip = 'Accessible to all loggedin users '
        'with ${permList.join(', ')} access';
  } else {
    toolTip = 'Accessible to $recipientName '
        'with ${permList.join(', ')} access';
  }

  if (permList.contains('Control')) {
    toolTip = '$toolTip '
        '(i.e. they can share or revoke access to others)';
  }

  return toolTip;
}

/// Get tooltip for permission log records
String getPermissionLogTooltip({
  required String recipientWebId,
  required String recipientName,
  required String granterName,
  // required RecipientType recipientType,
  required String permissionTypeLabel,
  required List<String> permList,
}) {
  String toolTip;

  if (recipientWebId == pubAgent) {
    toolTip = '$granterName $permissionTypeLabel '
        '${permList.join(', ')} '
        'access to anyone ';
  } else if (recipientWebId == authAgent) {
    toolTip = '$granterName $permissionTypeLabel '
        '${permList.join(', ')} '
        'access to all logged in users ';
  } else {
    toolTip = '$granterName $permissionTypeLabel '
        '${permList.join(', ')} '
        'access to $recipientName';
  }

  if (permList.contains('control')) {
    toolTip = '$toolTip '
        '(i.e. $recipientName had permission to share or revoke access to others)';
  }

  return toolTip;
}

/// Generate the content of encKeyFile
Future<String> genGroupWebIdTTLStr(List<dynamic> groupWebIdList) async {
  var triples = <URIRef, Map<URIRef, dynamic>>{};
  triples = {
    URIRef('${thisFile.ns.ns}me'): {
      AclPredicate.aclRdfType.uriRef: AclPredicate.vcardGroup.uriRef,
      AclPredicate.vcardHasMember.uriRef: {
        for (final webId in groupWebIdList) ...{URIRef(webId as String)},
      },
    },
  };

  final bindNS = {thisFile.prefix: thisFile.ns, vcardNS.prefix: vcardNS.ns};

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
      AclPredicate.aclRdfType.uriRef: {AclPredicate.personalDocument.uriRef},
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
