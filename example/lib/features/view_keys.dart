/// A widget to view private key data in a Solid Pod.
///
// Time-stamp: <Wednesday 2024-05-15 10:13:40 +1000 Graham Williams>
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
/// Authors: Anushka Vidanage, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show KeyManager;

import 'package:demopod/constants/app.dart';
import 'package:demopod/utils/rdf.dart' show getEncKeyContent;

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

  /// Decrypted data cache
  Map<dynamic, dynamic>? _decryptedData;
  bool _isDecrypting = false;

  /// Decrypt encrypted key values using KeyManager.
  ///
  /// This function attempts to decrypt the 'prvKey' (private key) value
  /// using KeyManager.getPrivateKey(). If decryption fails or
  /// the master key is not available, the original encrypted values are returned.
  Future<Map<dynamic, dynamic>> _decryptKeyValues(
      Map<dynamic, dynamic> encFileData) async {
    final result = Map<dynamic, dynamic>.from(encFileData);

    try {
      // Get the decrypted private key from KeyManager
      final decryptedPrvKey = await KeyManager.getPrivateKey();

      // Update the result with decrypted value, show truncated for security
      if (encFileData.containsKey('prvKey')) {
        final displayValue = decryptedPrvKey.length > 80
            ? '${decryptedPrvKey.substring(0, 80)}...'
            : decryptedPrvKey;
        result['prvKey'] = [
          encFileData['prvKey'][0],
          '✓ Decrypted: $displayValue',
        ];
      }
    } on Exception catch (e) {
      debugPrint('ViewKeys: Failed to decrypt private key: $e');
      // Keep original encrypted values, add status note
      result['_status'] = ['', '✗ Decryption unavailable'];
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadDecryptedData();
  }

  Future<void> _loadDecryptedData() async {
    setState(() {
      _isDecrypting = true;
    });

    try {
      final encFileData = getEncKeyContent(widget.keyInfo);
      final decrypted = await _decryptKeyValues(encFileData);
      if (mounted) {
        setState(() {
          _decryptedData = decrypted;
          _isDecrypting = false;
        });
      }
    } on Exception catch (e) {
      debugPrint('ViewKeys: Error loading data: $e');
      if (mounted) {
        setState(() {
          _isDecrypting = false;
          // Fallback to encrypted data on error
          _decryptedData = getEncKeyContent(widget.keyInfo);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: titleBackgroundColor,
        ),
        body: _buildBody());
  }

  Widget _buildBody() {
    if (_isDecrypting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_decryptedData == null) {
      return const Center(child: Text('No data available'));
    }

    return _loadedScreen(_decryptedData!);
  }

  Widget _loadedScreen(Map<dynamic, dynamic> data) {
    final dataRows = data.entries.map((entry) {
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
