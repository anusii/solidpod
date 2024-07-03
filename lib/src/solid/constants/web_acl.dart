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
/// Authors: Dawei Chen

library;

import 'package:rdflib/rdflib.dart' show Namespace, URIRef;
import 'package:solidpod/src/solid/constants/common.dart' show acl, foaf, rdf;
import 'package:solidpod/src/solid/constants/schema.dart' show NS, aclNS;

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

/// Predicates for web access control

enum Predicate {
  /// Predicate of acl:Authorization
  aclRdfType('${rdf}type'),

  /// Operations the agents can perform on a resource
  aclMode('${acl}mode'),

  /// The resource to which access is being granted
  accessTo('${acl}accessTo'),

  /// The container resource whose Authorization can be applied to
  /// a resource lower in the collection hierarchy
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
  const Predicate(this._value);

  /// String value of access predicate
  final String _value;

  /// Return the URIRef of predicate
  URIRef get uriRef => URIRef(_value);
}

/// Mode of access to a resource

enum AccessMode {
  /// Read access
  read('Read', 'permission to read the content of the shared file'),

  /// Write access
  write('Write',
      'permission to add/delete/modify content to/from the shared file'),

  /// Control access: read and write access to the ACL file
  control('Control',
      'permission to alter the access permission to the shared file'),

  /// Append data (a type of write)
  append('Append',
      'permission to add content but not remove or modify content from the shared file');

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
