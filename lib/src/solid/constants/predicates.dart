/// Common predicates used across the package for RDF/Turtle operations.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
///
// ignore_for_file: unused_element
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
/// Authors: Anushka Vidanage, Dawei Chen

library;

import 'package:rdf/rdf.dart' show URIRef;

import 'package:solidpod/src/solid/constants/common.dart'
    show acl, foaf, rdf, terms, vcard, xsd;

// ============================================================================
// Base Predicate Interface
// ============================================================================

/// Abstract base for all predicate enums providing common functionality.
abstract mixin class PredicateBase {
  /// The string value of the predicate URI.
  String get value;

  /// Return the URIRef of predicate.
  URIRef get uriRef => URIRef(value);
}

// ============================================================================
// RDF Predicates
// ============================================================================

/// Common RDF predicates from http://www.w3.org/1999/02/22-rdf-syntax-ns#
enum RdfPredicate with PredicateBase {
  /// rdf:type - Used to state that a resource is an instance of a class.
  type('${rdf}type');

  const RdfPredicate(this._value);
  final String _value;

  @override
  String get value => _value;
}

// ============================================================================
// FOAF Predicates
// ============================================================================

/// FOAF (Friend of a Friend) predicates from http://xmlns.com/foaf/0.1/
enum FoafPredicate with PredicateBase {
  /// foaf:Agent - An agent (person, group, software, etc.)
  agent('${foaf}Agent'),

  /// foaf:Person - A person
  person('${foaf}Person'),

  /// foaf:name - A name for the thing
  name('${foaf}name'),

  /// foaf:mbox - A personal mailbox
  mbox('${foaf}mbox'),

  /// foaf:knows - A person known by this person
  knows('${foaf}knows'),

  /// foaf:PersonalProfileDocument - A personal profile RDF document
  personalProfileDocument('${foaf}PersonalProfileDocument');

  const FoafPredicate(this._value);
  final String _value;

  @override
  String get value => _value;
}

// ============================================================================
// ACL (Web Access Control) Predicates
// ============================================================================

/// Pure Web Access Control predicates from http://www.w3.org/ns/auth/acl#
/// For combined ACL predicates used in ACL file operations, see AclPredicate
/// in web_acl.dart which includes predicates from multiple namespaces.
enum CommonAclPredicate with PredicateBase {
  /// acl:Authorization - The class of Authorization resources
  authorization('${acl}Authorization'),

  /// acl:mode - Operations the agents can perform on a resource
  mode('${acl}mode'),

  /// acl:Read - Read access mode
  read('${acl}Read'),

  /// acl:Write - Write access mode
  write('${acl}Write'),

  /// acl:Append - Append access mode
  append('${acl}Append'),

  /// acl:Control - Control access mode
  control('${acl}Control'),

  /// acl:accessTo - The resource to which access is being granted
  accessTo('${acl}accessTo'),

  /// acl:default - Default access for resources in the container
  defaultAccess('${acl}default'),

  /// acl:agent - An agent being given access permission
  agent('${acl}agent'),

  /// acl:agentClass - A class of agents being given access permission
  agentClass('${acl}agentClass'),

  /// acl:agentGroup - A group of agents being given access permission
  agentGroup('${acl}agentGroup'),

  /// acl:origin - Origin of an HTTP request being given access permission
  origin('${acl}origin'),

  /// acl:owner - The owner of a resource
  owner('${acl}owner');

  const CommonAclPredicate(this._value);
  final String _value;

  @override
  String get value => _value;
}

// ============================================================================
// VCard Predicates
// ============================================================================

/// VCard predicates from http://www.w3.org/2006/vcard/ns#
enum VcardPredicate with PredicateBase {
  /// vcard:Group - A group of vcards
  group('${vcard}Group'),

  /// vcard:hasMember - Has a member in a group
  hasMember('${vcard}hasMember'),

  /// vcard:fn - Formatted name
  fn('${vcard}fn'),

  /// vcard:hasEmail - Has an email address
  hasEmail('${vcard}hasEmail'),

  /// vcard:hasPhoto - Has a photo
  hasPhoto('${vcard}hasPhoto'),

  /// vcard:hasTelephone - Has a telephone number
  hasTelephone('${vcard}hasTelephone'),

  /// vcard:organization-name - Name of organization
  organizationName('${vcard}organization-name'),

  /// vcard:role - Role in organization
  role('${vcard}role');

  const VcardPredicate(this._value);
  final String _value;

  @override
  String get value => _value;
}

// ============================================================================
// Dublin Core Terms Predicates
// ============================================================================

/// Dublin Core Terms predicates from http://purl.org/dc/terms/
enum DcTermsPredicate with PredicateBase {
  /// terms:title - A name given to the resource
  title('${terms}title'),

  /// terms:description - An account of the resource
  description('${terms}description'),

  /// terms:creator - An entity responsible for making the resource
  creator('${terms}creator'),

  /// terms:created - Date of creation
  created('${terms}created'),

  /// terms:modified - Date of last modification
  modified('${terms}modified'),

  /// terms:subject - The topic of the resource
  subject('${terms}subject'),

  /// terms:type - The nature or genre of the resource
  type('${terms}type'),

  /// terms:format - The file format
  format('${terms}format'),

  /// terms:identifier - An unambiguous reference to the resource
  identifier('${terms}identifier');

  const DcTermsPredicate(this._value);
  final String _value;

  @override
  String get value => _value;
}

// ============================================================================
// XSD (XML Schema) Predicates
// ============================================================================

/// XML Schema datatypes from http://www.w3.org/2001/XMLSchema#
enum XsdDatatype with PredicateBase {
  /// xsd:string - String datatype
  string('${xsd}string'),

  /// xsd:integer - Integer datatype
  integer('${xsd}integer'),

  /// xsd:decimal - Decimal datatype
  decimal('${xsd}decimal'),

  /// xsd:boolean - Boolean datatype
  boolean('${xsd}boolean'),

  /// xsd:dateTime - DateTime datatype
  dateTime('${xsd}dateTime'),

  /// xsd:date - Date datatype
  date('${xsd}date'),

  /// xsd:time - Time datatype
  time('${xsd}time');

  const XsdDatatype(this._value);
  final String _value;

  @override
  String get value => _value;
}
