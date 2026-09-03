/// Utilities for working on Turtle (Terse RDF Triple Language) formated string.
///
/// Copyright (C) 2024-2026, Software Innovation Institute, ANU.
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
/// Authors: Dawei Chen, Tony Chen

library;

import 'package:petitparser/petitparser.dart';
import 'package:rdf/rdf.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';

// Sentinel characters used to mark string literal boundaries during parsing.

const String _literalStart = '\u0002';
const String _literalEnd = '\u0003';

// Parser definition that wraps every STRING literal with the sentinel
// characters so literals remain distinguishable from prefixed names when the
// parse tree is walked.
//
// The overridden method names use the SCREAMING_SNAKE_CASE convention defined
// by the W3C Turtle grammar and inherited from the `rdf` package's [EvaluatorDefinition],
// so the `non_constant_identifier_names` lint is intentionally ignored.

// ignore_for_file: non_constant_identifier_names
class _LiteralPreservingEvaluator extends EvaluatorDefinition {
  @override
  Parser STRING_LITERAL_QUOTE() => super
      .STRING_LITERAL_QUOTE()
      .map((value) => '$_literalStart$value$_literalEnd');

  @override
  Parser STRING_LITERAL_SINGLE_QUOTE() => super
      .STRING_LITERAL_SINGLE_QUOTE()
      .map((value) => '$_literalStart$value$_literalEnd');

  @override
  Parser STRING_LITERAL_LONG_QUOTE() => super
      .STRING_LITERAL_LONG_QUOTE()
      .map((value) => '$_literalStart$value$_literalEnd');

  @override
  Parser STRING_LITERAL_LONG_SINGLE_QUOTE() => super
      .STRING_LITERAL_LONG_SINGLE_QUOTE()
      .map((value) => '$_literalStart$value$_literalEnd');
}

// Build the literal-preserving Turtle parser once and reuse it for every call
// to [turtleToTripleMap].

final Parser _turtleParser = _LiteralPreservingEvaluator().build();

/// Parse the Turtle string into triples stored in a map:
/// {subject: {predicate: object(s)}
/// - subject: URIRef String
/// - predicate: URIRef String
/// - object: dynamic

Map<String, Map<String, dynamic>> turtleToTripleMap(String turtleStr) {
  final preprocessed = _preprocessLongLiterals(turtleStr);
  final stripped = _stripComments(preprocessed);

  final result = _turtleParser.parse(stripped);
  if (result is! Success || result.value is! List) {
    return <String, Map<String, dynamic>>{};
  }

  final ast = result.value as List;
  final prefixes = <String, String>{};
  String? baseIri;
  final tripleMap = <String, Map<String, dynamic>>{};

  for (final statement in ast) {
    if (statement is! List || statement.isEmpty) continue;

    final head = statement[0];

    // Prefix and base directives are matched case-insensitively so that
    // both `@prefix` / `@base` and the SPARQL `PREFIX` / `BASE` keywords
    // are recognised.

    if (head is String) {
      final keyword = head.toLowerCase();
      if (keyword == '@prefix' || keyword == 'prefix') {
        if (statement.length >= 3) {
          final ns = statement[1] as String;
          prefixes[ns] = _stripAngleBrackets(statement[2] as String);
        }
        continue;
      }
      if (keyword == '@base' || keyword == 'base') {
        if (statement.length >= 2) {
          baseIri = _stripAngleBrackets(statement[1] as String);
        }
        continue;
      }
    }

    if (head is List && head.length >= 2) {
      final subjectRaw = head[0];
      final predicateObjectList = head[1];
      if (subjectRaw is! String || predicateObjectList is! List) continue;

      final subject = _expandIri(subjectRaw, prefixes, baseIri);
      final subjectEntry =
          tripleMap.putIfAbsent(subject, () => <String, dynamic>{});

      for (final predicateObject in predicateObjectList) {
        if (predicateObject is! List || predicateObject.length < 2) continue;

        final predicateRaw = predicateObject[0];
        final objectList = predicateObject[1];
        if (predicateRaw is! String || objectList is! List) continue;

        final predicate = _expandPredicate(predicateRaw, prefixes, baseIri);

        for (final obj in objectList) {
          final value = _convertObject(obj, prefixes, baseIri);
          if (value == null) continue;

          if (subjectEntry.containsKey(predicate)) {
            final existing = subjectEntry[predicate];
            subjectEntry[predicate] =
                existing is List ? existing + [value] : [existing, value];
          } else {
            subjectEntry[predicate] = value;
          }
        }
      }
    }
  }

  return tripleMap;
}

// Resolve a predicate token: 'a' is shorthand for rdf:type.

String _expandPredicate(
  String raw,
  Map<String, String> prefixes,
  String? base,
) {
  if (raw.trim() == 'a') {
    return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
  }
  return _expandIri(raw, prefixes, base);
}

// Expand an IRI-like token (IRIREF, PrefixedName, blank node, or relative
// IRI) into a full IRI string suitable for use as a map key.

String _expandIri(String raw, Map<String, String> prefixes, String? base) {
  final trimmed = raw.trim();

  if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
    return trimmed.substring(1, trimmed.length - 1);
  }

  if (trimmed.startsWith('_:')) {
    return trimmed;
  }

  if (trimmed.startsWith(':')) {
    final nsValue = prefixes[':'] ?? base ?? '';
    return '$nsValue${trimmed.substring(1)}';
  }

  final colonIdx = trimmed.indexOf(':');
  if (colonIdx > 0) {
    final ns = trimmed.substring(0, colonIdx + 1);
    final localName = trimmed.substring(colonIdx + 1);
    final nsValue = prefixes[ns];
    if (nsValue != null) {
      return '$nsValue$localName';
    }
  }

  return trimmed;
}

// Convert a parsed object token into its serialised value. String literals
// are returned without their sentinels and without any trailing lang tag or
// datatype IRI, matching the historical behaviour of using `Literal.value`.

dynamic _convertObject(
  dynamic obj,
  Map<String, String> prefixes,
  String? base,
) {
  if (obj is! String) {
    return obj.toString();
  }

  if (obj.startsWith(_literalStart)) {
    final end = obj.indexOf(_literalEnd);
    if (end < 0) {
      return obj.substring(_literalStart.length);
    }
    return obj.substring(_literalStart.length, end);
  }

  final trimmed = obj.trim();

  if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
    return trimmed.substring(1, trimmed.length - 1);
  }

  if (trimmed.startsWith('_:')) {
    return trimmed;
  }

  // Numeric and boolean literals are returned as their original lexical form.

  if (trimmed == 'true' || trimmed == 'false') {
    return trimmed;
  }
  if (double.tryParse(trimmed) != null) {
    return trimmed;
  }

  if (trimmed.contains(':')) {
    return _expandIri(trimmed, prefixes, base);
  }

  return trimmed;
}

String _stripAngleBrackets(String token) {
  if (token.length >= 2 && token.startsWith('<') && token.endsWith('>')) {
    return token.substring(1, token.length - 1);
  }
  return token;
}

// Remove Turtle comments. Mirrors the `rdf` package's behaviour: a line starting with
// `#` is dropped entirely, and an inline ` # ` comment is trimmed to the end
// of the line. Comments inside string literals are not stripped, as the
// pattern only matches ` # ` preceded by whitespace, which cannot appear
// inside an unbroken single-line literal.

String _stripComments(String content) {
  final lines = content.split('\n');
  final buffer = StringBuffer();
  final inlineCommentRe = RegExp(r'\s+#\s.*$');
  for (final line in lines) {
    if (line.trimLeft().startsWith('#')) continue;
    buffer.write(line.replaceFirst(inlineCommentRe, ''));
    buffer.write('\n');
  }
  return buffer.toString();
}

// Collapse a `"""..."""` (or `'''...'''`) long literal onto a single line so
// the line-based grammar can match it. Mirrors the preprocessing performed
// by the `rdf` package's [Graph.parseTurtle].

String _preprocessLongLiterals(String content) {
  final regex = RegExp(
    content.contains("'''") ? r"'''(.*?)'''" : r'"""(.*?)"""',
    dotAll: true,
  );
  return content.replaceAllMapped(regex, (match) {
    var inner = match.group(1)!;
    inner = inner.replaceAll('\n', r'\n');
    inner = inner.replaceAll('"', r'\"');
    return '"$inner"';
  });
}

/// Generate Turtle string from triples stored in a map:
/// {subject: {predicate: {object}}}
/// - subject: URIRef String
/// - predicate: URIRef String
/// - object: {dynamic}

String tripleMapToTurtle(
  Map<URIRef, Map<URIRef, dynamic>> triples, {
  Map<String, Namespace>? bindNamespaces,
}) {
  final g = Graph();

  for (final sub in triples.keys) {
    final predMap = triples[sub];
    for (final pre in predMap!.keys) {
      final objs = predMap[pre];
      final objList = objs is Iterable ? List.from(objs) : [objs];
      if (objList.length != Set.from(objList).length) {
        throw Exception(
          'Duplicated triples \n'
          'subject: ${sub.value},\n'
          'predicate: ${pre.value},\n'
          'objects: ${[for (final o in objList) o.toString()]}.',
        );
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

// TODO (dc): Unify parseTTL() and parseACL()
/// Parse TTL content into a map {subject: {predicate: object}}
// Map<String, dynamic> parseTTL(String ttlContent) {
//   final triples = turtleToTripleMap(ttlContent);
//   String extract(String str) => str.contains('#') ? str.split('#')[1] : str;
//   return {
//     for (final sub in triples.keys)
//       extract(sub): {
//         for (final pre in triples[sub]!.keys)
//           extract(pre): triples[sub]![pre]! is Iterable
//               ? [for (final obj in triples[sub]![pre]!) extract(obj as String)]
//               : extract(triples[sub]![pre]! as String),
//       },
//   };
// }

// TODO av: The function parseTTL needs to be converted to parseTTLMap in all
// places where it has been used. A TTl can contain multiple objects with same
// predicate. Also the function extract() can be removed when we have properly
// defined our namespaces
/// Parse TTL content into a map {subject: {predicate: {objects}}}

Map<String, dynamic> parseTTLMap(String ttlContent) {
  final g = Graph();
  g.parseTurtle(ttlContent);
  final dataMap = <String, dynamic>{};
  for (final t in g.triples) {
    final sub = t.sub.value as String;
    final pre = t.pre.value as String;
    final obj = t.obj.value as String;
    if (dataMap.containsKey(sub)) {
      if ((dataMap[sub] as Map).containsKey(pre)) {
        dataMap[sub][pre].add(obj);
      } else {
        dataMap[sub][pre] = {obj};
      }
    } else {
      dataMap[sub] = {
        pre: {obj},
      };
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
    if (['agent', 'agentClass'].contains(pre)) {
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
        pre: [obj],
      };
    }
  }
  return dataMap;
}

/// Generate permission log file content

String genPermLogTTLStr(String resourceUrl) => tripleMapToTurtle(
      {
        URIRef(resourceUrl): {
          termsNS.ns.withAttr(titlePred): logFileTitle,
          rdfNS.ns.withAttr(typePred): foafNS.ns.withAttr(profileDoc),
        },
      },
      bindNamespaces: {termsNS.prefix: termsNS.ns},
    );
