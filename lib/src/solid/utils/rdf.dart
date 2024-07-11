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

/// Parse the Turtle string into triples stored in a map:
/// {subject: {predicate: {object}}}
/// - subject: URIRef String
/// - predicate: URIRef String
/// - object: {dynamic}
Map<String, Map<String, List<dynamic>>> turtleToTripleMap(String turtleString) {
  final g = Graph();
  g.parseTurtle(turtleString);
  final triples = <String, Map<String, List<dynamic>>>{};
  for (final t in g.triples) {
    final sub = t.sub.value as String;
    final pre = t.pre.value as String;
    final obj = t.obj.value as String;
    if (triples.containsKey(sub)) {
      if (triples[sub]!.containsKey(pre)) {
        triples[sub]![pre]!.add(obj);
      } else {
        triples[sub]![pre] = [obj];
      }
    } else {
      triples[sub] = {
        pre: [obj]
      };
    }
  }
  return triples;
}

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
      final objList = objs is Iterable ? List.from(objs) : [objs];
      if (objList.length != Set.from(objList).length) {
        throw Exception('Duplicated triples \n'
            'subject: ${sub.value},\n'
            'predicate: ${pre.value},\n'
            'objects: ${[for (final o in objList) o.toString()]}.');
      }

      for (final obj in objList) {
        g.addTripleToGroups(sub, pre, obj);
      }
    }
  }

  if (bindNamespaces != null) {
    bindNamespaces.forEach(g.bind);
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}

// TODO (dc): Deprecate tripleMapToTTLStr()
/// Generate TTL string from triples stored in a map:
/// {subject: {predicate: object}}
/// where
/// - subject: usually the URL of a file
/// - predicate-object: the key-value pairs to be stores in the file
@Deprecated('''
[tripleMapToTTLStr] is deprecated.
Use [tripleMapToTurtle(tripls, bindNamespaces)] instead.
''')
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

// TODO (dc): Unify parseTTL() and parseACL()
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

/// Generate permission log file content
String genPermLogTTLStr(String resourceUrl) => tripleMapToTurtle({
      URIRef(resourceUrl): {
        termsNS.ns.withAttr(titlePred): logFileTitle,
        rdfNS.ns.withAttr(typePred): foafNS.ns.withAttr(profileDoc),
      }
    }, bindNamespaces: {
      termsNS.prefix: termsNS.ns
    });
