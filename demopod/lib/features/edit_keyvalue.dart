/// A widget to edit key/value pairs and save them in a POD.
///
// Time-stamp: <Friday 2024-06-28 13:35:54 +1000 Graham Williams>
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
/// Authors: Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:editable/editable.dart';
import 'package:demopod/dialogs/alert.dart';
import 'package:demopod/constants/app.dart';
import 'package:demopod/utils/rdf.dart';

import 'package:solidpod/solidpod.dart' show writePod;

class KeyValueEdit extends StatefulWidget {
  /// Constructor
  const KeyValueEdit(
      {required this.title,
      required this.fileName,
      required this.child,
      this.encrypted = true,
      this.keyValuePairs,
      super.key});

  final String title;
  final String fileName; // file to be saved in PODs
  final Widget child;
  final bool encrypted;
  final List<({String key, dynamic value})>?
      keyValuePairs; // initial key value pairs

  @override
  State<KeyValueEdit> createState() => _KeyValueEditState();
}

class _KeyValueEditState extends State<KeyValueEdit> {
  /// Create a Key for EditableState
  final _editableKey = GlobalKey<EditableState>();
  final regExp = RegExp(r'\s+');
  static const rowKey = 'row'; // key of row index in editedRows
  static const keyStr = 'key';
  static const valStr = 'value';
  final List<dynamic> rows = [];
  final List<dynamic> cols = [
    {'title': 'Key', 'key': keyStr},
    {'title': 'Value', 'key': valStr},
  ];
  final dataMap = <int, ({String key, dynamic value})>{};
  bool _isLoading = false; // Loading indicator for data submission

  @override
  void initState() {
    super.initState();

    // A column is a {'title': TITLE, 'key': KEY}
    // A row is a {KEY: VALUE}

    // Initialise the rows
    if (widget.keyValuePairs != null) {
      for (final (:key, :value) in widget.keyValuePairs!) {
        rows.add({keyStr: key, valStr: value});
      }
    }

    // Save initial data
    for (var i = 0; i < rows.length; i++) {
      dataMap[i] = (key: rows[i][keyStr], value: rows[i][valStr]);
    }
  }

  // Add a new row using the global key assigined to the Editable widget
  // to access its current state
  void _addNewRow() {
    setState(() {
      _editableKey.currentState?.createRow();
    });
  }

  void _saveEditedRows() {
    final editedRows = _editableKey.currentState?.editedRows as List;
    // print('edited_rows: ${editedRows}');
    // print('#rows: ${_editableKey.currentState?.rowCount}');
    // print('#cols: ${_editableKey.currentState?.columnCount}');
    // print('rows:');
    // print(rows); // edits are not saved in `rows'
    if (editedRows.isEmpty) {
      return;
    }
    for (final r in editedRows) {
      final rowInd = r[rowKey] as int;
      dataMap[rowInd] = (key: r[keyStr] as String, value: r[valStr]);
      rows[rowInd] = {keyStr: r[keyStr], valStr: r[valStr]};
    }
  }

  Future<void> _alert(String msg) async => alert(context, msg);

  // Get key value pairs
  Future<List<({String key, dynamic value})>?> _getKeyValuePairs() async {
    final rowInd = dataMap.keys.toList()..sort();
    final keys = <String>{};
    final pairs = <({String key, dynamic value})>[];
    for (final i in rowInd) {
      final k = dataMap[i]!.key.trim();
      if (k.isEmpty) {
        await _alert('Invalide key: "$k"');
        return null;
      }
      if (keys.contains(k)) {
        await _alert('Invalide key: Duplicate key "$k"');
        return null;
      }
      if (regExp.hasMatch(k)) {
        await _alert('Invalided key: Whitespace found in key "$k"');
        return null;
      }
      keys.add(k);
      final v = dataMap[i]!.value;
      pairs.add((key: k, value: v));
    }
    return pairs;
  }

  // Save data to PODs
  Future<bool> _saveToPod(BuildContext context) async {
    _saveEditedRows();

    final pairs = await _getKeyValuePairs();
    if (dataMap.isEmpty) {
      await _alert('No data to submit');
      return false;
    }

    setState(() {
      // Begin loading.

      _isLoading = true;
    });

    try {
      // Generate TTL str with dataMap
      final ttlStr = await genTTLStr(pairs!);

      // Write to POD
      await writePod(widget.fileName, ttlStr, context, widget.child,
          encrypted: widget.encrypted);

      await _alert('Successfully saved ${dataMap.length} key-value pairs'
          ' to "${widget.fileName}" in PODs');
      return true;
    } on Exception catch (e) {
      debugPrint('Exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          // End loading.

          _isLoading = false;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: titleBackgroundColor,
          leadingWidth: 100,
          actions: [
            Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton.icon(
                    onPressed: _addNewRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () async {
                        final saved = await _saveToPod(context);
                        if (saved) {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => widget.child));
                        }
                      },
                      child: const Text('Submit',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ])),
          ],
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator
              : Editable(
                  key: _editableKey,
                  columns: cols,
                  rows: rows,
                  // zebraStripe: false,
                  // stripeColor1: Colors.blue[50]!,
                  // stripeColor2: Colors.grey[200]!,
                  onRowSaved: print,
                  onSubmitted: print,
                  borderColor: Colors.blueGrey,
                  tdStyle: const TextStyle(fontWeight: FontWeight.bold),
                  trHeight: 20,
                  thStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  thAlignment: TextAlign.center,
                  thVertAlignment: CrossAxisAlignment.end,
                  thPaddingBottom: 3,
                  // showSaveIcon:
                  //     false, // do not show the save icon at the right of a row
                  // saveIconColor: Colors.black,
                  // showCreateButton: false, // do not show the + button at top-left
                  tdAlignment: TextAlign.left,
                  tdEditableMaxLines: 100, // don't limit and allow data to wrap
                  tdPaddingTop: 5,
                  tdPaddingBottom: 5,
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.zero),
                ),
        ));
  }
}
