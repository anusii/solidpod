/// Constants used throughout the app.
///
// Time-stamp: <Thursday 2026-06-18 12:22:14 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

const titleBackgroundColor = Color(0xFFF0E4D7);

class AppConstants {
  static const shortName = 'SolidPodEg';
  static const longName = 'Solid Pod Demonstrator';
}

// const dataFile = 'key-value.ttl';
const dataFile = 'keyvalue/key-value.ttl';

//const dataFilePlain = 'key-value-plain.ttl';
const dataFilePlain = dataFile;

String createDemoTtlStr(String fileName) {
  return '''@prefix demo: <#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

demo:sampleData$fileName a demo:DemoResource ;
    rdfs:label "Demo File $fileName" ;
    demo:created "${DateTime.now().toIso8601String()}" ;
    demo:description "This is a file containing some demo ttl content" ;
    foaf:maker "Solid Demo" .

demo:exampleData$fileName
    demo:sampleProperty "Sample value" ;
    demo:category "demo-data".
''';
}

const clientIdVal =
    'https://anushkavidanage.github.io/solidpod/example/client-profile.jsonld';

const redirectUrisList = [
  'https://anushkavidanage.github.io/solidpod/example/redirect.html',
  'http://localhost:4400/redirect',
  'com.example.solidpodeg://redirect',
];

const postLogoutRedirectUrisList = [
  'https://anushkavidanage.github.io/solidpod/example/redirect.html',
  'http://localhost:4400/redirect',
  'com.example.solidpodeg://redirect',
];
