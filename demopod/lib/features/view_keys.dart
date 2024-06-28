/// A widget to view private key data in a Solid Pod.
///
// Time-stamp: <Wednesday 2024-05-15 10:13:40 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Anushka Vidanage, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:demopod/utils/rdf.dart' show getEncKeyContent;

import 'package:demopod/constants/app.dart';

/// A widget to show the user all the encryption keys stored in their Solid Pod.

class ViewKeys extends StatefulWidget {
  /// Constructor for the widget.

  const ViewKeys({
    required this.keyInfo,
    required this.title,
    super.key,
  });

  // Name of the app
  // final String appName;

  /// Data of the key file
  final String keyInfo;

  // Title of the page
  final String title;

  @override
  State<ViewKeys> createState() => _ViewKeysState();
}

class _ViewKeysState extends State<ViewKeys> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: titleBackgroundColor,
        ),
        body: loadedScreen(widget.keyInfo));
  }

  @override
  void initState() {
    super.initState();
  }

  Widget loadedScreen(String keyData) {
    final encFileData = getEncKeyContent(keyData);

    //TODO av-20240319: Need to get the encryption key
    // to decrypt the private key value

    // encKey = secureStorage.read(key: 'key')

    // final keyMaster = Key.fromUtf8(encKey);
    // final ivInd = IV.fromBase64(encFileData['iv'][1] as String);
    // final encrypterKey =
    //     Encrypter(AES(keyMaster, mode: AESMode.cbc));

    // final eccKey = Encrypted.from64(medFileKey);
    // final keyIndPlain = encrypterKey.decrypt(eccKey, iv: ivInd);

    final dataRows = encFileData.entries.map((entry) {
      return DataRow(cells: [
        DataCell(Text(
          entry.key as String,
          style: const TextStyle(
            fontSize: 12,
          ),
        )),
        DataCell(SizedBox(
            width: 600,
            child: Text(
              entry.value[1] as String,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
              ),
            ))),
      ]);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DataTable(
                columnSpacing: 30.0,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Parameter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Value',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: dataRows),
          ],
        ),
      ),
    );
  }
}
