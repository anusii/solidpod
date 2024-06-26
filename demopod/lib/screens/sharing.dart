/// A screen to demonstrate various capabilities of solidlogin.
///
// Time-stamp: <Sunday 2024-05-26 11:04:50 +1000 Graham Williams>
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
///
/// Authors: Zheyuan Xu, Anushka Vidanage, Kevin Wang, Dawei Chen, Graham Williams

// TODO 20240411 gjw EITHER REPAIR ALL CONTEXT ISSUES OR EXPLAIN WHY NOT?

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:demopod/dialogs/about.dart';
import 'package:demopod/screens/edit_keyvalue.dart';
import 'package:demopod/constants/app.dart';
import 'package:demopod/utils/rdf.dart';

import 'package:solidpod/solidpod.dart'
    show getDataDirPath, readPod, readPermission, grantPermission;

// TODO 20240515 gjw For now we will list all the imports so we can manage the
// API evolution. Eventually we will simply just import the package.

/// A widget for the demonstration screen of the application.

class SharingScreen extends StatefulWidget {
  /// Initialise widget variables.

  const SharingScreen({super.key});

  @override
  SharingScreenState createState() => SharingScreenState();
}

class SharingScreenState extends State<SharingScreen>
    with SingleTickerProviderStateMixin {
  String sampleText = '';
  // Step 1: Loading state variable.

  bool _isLoading = false;

  // Indicator for write encrypted/plaintext data
  bool _writeEncrypted = true;

  bool readChecked = false;
  bool writeChecked = false;
  bool controlChecked = false;

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final formControllerWebId = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _writePrivateData() async {
    setState(() {
      // Begin loading.
      _isLoading = true;
    });

    // final appName = await getAppName();

    // final fileName = 'test-101.ttl';
    // final fileContent = 'This is for testing writePod.';

    final fileName = _writeEncrypted ? dataFile : dataFilePlain;

    try {
      final dataDirPath = await getDataDirPath();
      final filePath = [dataDirPath, fileName].join('/');

      final fileContent =
          await readPod(filePath, context, const SharingScreen());
      final pairs = fileContent == null ? null : await parseTTLStr(fileContent);

      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => KeyValueEdit(
                  title: 'Basic Key Value Editor',
                  fileName: fileName,
                  keyValuePairs: pairs,
                  encrypted: _writeEncrypted,
                  child: const SharingScreen())));
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
  }

  Widget _build(BuildContext context, String title, List<Object>? loadedData) {
    // Build the widget.

    // Include a timestamp on the screen.

    final dateStr = DateFormat('HH:mm:ss dd MMMM yyyy').format(DateTime.now());

    // Some vertical spacing for the widget.

    const smallGapV = SizedBox(height: 10.0);
    const largeGapV = SizedBox(height: 40.0);

    // A small horizontal spacing for the widget.

    const smallGapH = SizedBox(width: 10.0);

    // Some handy widgets that will be displyed. These are defined here to
    // reduce the complexity of the code below.

    final about = IconButton(
      icon: const Icon(
        Icons.info,
        color: Colors.purple,
      ),
      onPressed: () async {
        await aboutDialog(context);
      },
      tooltip: 'Popup a window about the app.',
    );

    final date = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date: $dateStr',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    const webid = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WebID: TO BE IMPLEMENTED',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    const welcomeHeading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share your key/value pair file with other PODs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    // Load the permission data
    final filePermMap = loadedData?.first as Map;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: titleBackgroundColor,
        title: Text(title),
        actions: [
          about,
        ],
      ),
      body: _isLoading
          // If loading show the loading indicator.
          ? const Center(child: CircularProgressIndicator())
          // Otherwise we show the screen.
          : SingleChildScrollView(
              child: Column(
                children: [
                  smallGapV,
                  Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          date,
                          webid,
                          largeGapV,
                          welcomeHeading,
                          smallGapV,
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  controller: formControllerWebId,
                                  decoration: const InputDecoration(
                                      hintText:
                                          'Recipient\'s WebID (Eg: https://pods.solidcommunity.au/john-doe/profile/card#me)'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Empty field';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              smallGapH,
                              ElevatedButton(
                                child: const Text('Check Permission'),
                                onPressed: () {
                                  final webId = formControllerWebId.text;

                                  Map permControllerMap = {
                                    'Read': readChecked,
                                    'Write': writeChecked,
                                    'Control': controlChecked,
                                  };

                                  if (webId.isNotEmpty) {
                                    if (filePermMap.containsKey(webId)) {
                                      final permList =
                                          filePermMap[webId] as List;

                                      if (permList.contains('Read') ||
                                          permList.contains('read')) {
                                        setState(() {
                                          readChecked = true;
                                        });
                                      } else {
                                        setState(() {
                                          readChecked = false;
                                        });
                                      }
                                      if (permList.contains('Write') ||
                                          permList.contains('write')) {
                                        setState(() {
                                          writeChecked = true;
                                        });
                                      } else {
                                        setState(() {
                                          writeChecked = false;
                                        });
                                      }
                                      if (permList.contains('Control') ||
                                          permList.contains('control')) {
                                        setState(() {
                                          controlChecked = true;
                                        });
                                      } else {
                                        setState(() {
                                          controlChecked = false;
                                        });
                                      }
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('INFO!'),
                                          content: const Text(
                                              'You have not provided any permissions for this webId.'),
                                          actions: [
                                            ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('OK'))
                                          ],
                                        ),
                                      );
                                    }
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('ERROR!'),
                                        content:
                                            const Text('Please enter a webID.'),
                                        actions: [
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('OK'))
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                              smallGapH,
                              CheckboxListTile(
                                title: const Text('Read'),
                                value: readChecked,
                                onChanged: (newValue) {
                                  setState(() {
                                    readChecked = newValue!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity
                                    .leading, //  <-- leading Checkbox
                              ),
                              CheckboxListTile(
                                title: const Text('Write'),
                                value: writeChecked,
                                onChanged: (newValue) {
                                  setState(() {
                                    writeChecked = newValue!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity
                                    .leading, //  <-- leading Checkbox
                              ),
                              CheckboxListTile(
                                title: const Text('Control'),
                                value: controlChecked,
                                onChanged: (newValue) {
                                  setState(() {
                                    controlChecked = newValue!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity
                                    .leading, //  <-- leading Checkbox
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                  child: const Text('Grant Permission'),
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      if (readChecked ||
                                          writeChecked ||
                                          controlChecked) {
                                        final webId = formControllerWebId.text;

                                        final permList = [];
                                        if (readChecked) {
                                          permList.add('Read');
                                        }
                                        if (writeChecked) {
                                          permList.add('Write');
                                        }
                                        if (controlChecked) {
                                          permList.add('Control');
                                        }
                                        assert(permList.isNotEmpty);

                                        await grantPermission(
                                            dataFile,
                                            permList,
                                            webId,
                                            true,
                                            context,
                                            const SharingScreen());

                                        await Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SharingScreen(),
                                          ),
                                        );
                                      } else {
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('ERROR!'),
                                            content: const Text(
                                                'Please select one or more permissions'),
                                            actions: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('OK'))
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              largeGapV,
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Granted permissions',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // ElevatedButton(
                              //   child: const Text('Read Permission'),
                              //   onPressed: () {
                              //     readPermission(dataFile, context, widget);
                              //   },
                              // ),
                              DataTable(columnSpacing: 20, columns: const [
                                DataColumn(
                                    label: Expanded(
                                      child: Center(
                                        child: Text(
                                          'Receiver WebID',
                                        ),
                                      ),
                                    ),
                                    tooltip:
                                        'WebID of the POD receiving permissions'),
                                DataColumn(
                                    label: Expanded(
                                      child: Center(
                                        child: Text(
                                          'Permissions',
                                        ),
                                      ),
                                    ),
                                    tooltip: 'List of permissions given'),
                                DataColumn(
                                    label: Expanded(
                                      child: Center(
                                        child: Text(
                                          'Actions',
                                        ),
                                      ),
                                    ),
                                    tooltip: 'Delete permission'),
                              ], rows: [
                                for (final receiverWebId in filePermMap.keys)
                                  DataRow(cells: [
                                    DataCell(Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 10, 0, 0),
                                      //width: cWidth,
                                      child: Column(
                                        children: <Widget>[
                                          SelectableText(
                                            receiverWebId as String,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        ],
                                      ),
                                    )),
                                    DataCell(
                                      Text(
                                        (filePermMap[receiverWebId] as List)
                                            .join(', '),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 24.0,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (ctx) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                        'Please Confirm'),
                                                    content: const Text(
                                                        'Are you sure you want to remove this permission?'),
                                                    actions: [
                                                      // The "Yes" button
                                                      TextButton(
                                                          onPressed:
                                                              () async {},
                                                          child: const Text(
                                                              'Yes')),
                                                      TextButton(
                                                          onPressed: () {
                                                            // Close the dialog
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const Text('No'))
                                                    ],
                                                  );
                                                });
                                          }),
                                    )
                                  ])
                              ])
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([readPermission(dataFile, context, widget)]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // final appName = snapshot.data?[0];
          // final title = 'Demonstrating data sharing functionality using '
          //     '${appName!.isNotEmpty ? appName[0].toUpperCase() + appName.substring(1) : ""}';
          const title = 'Demonstrating data sharing functionality';
          return _build(context, title, snapshot.data);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
