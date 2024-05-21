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
import 'package:solidpod/src/solid/constants.dart';

/// Generate TTL string from triples stored in a map:
/// {subject: {predicate: object}}
/// where
/// - subject: usually the URL of a file
/// - predicate-object: the key-value pairs to be stores in the file

String tripleMapToTTLStr(Map<String, Map<String, String>> tripleMap) {
  assert(tripleMap.isNotEmpty);
  final g = Graph();
  final nsTerms = Namespace(ns: appsTerms);
  final nsTitle = Namespace(ns: terms);

  for (final sub in tripleMap.keys) {
    assert(tripleMap[sub] != null && tripleMap[sub]!.isNotEmpty);
    final f = URIRef(sub);
    for (final pre in tripleMap[sub]!.keys) {
      final obj = tripleMap[sub]![pre] as String;
      final ns = (pre == titlePred) ? nsTitle : nsTerms;
      g.addTripleToGroups(f, ns.withAttr(pre), obj);
    }
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}

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
