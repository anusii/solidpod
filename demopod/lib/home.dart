/// A screen to demonstrate various capabilities of solidlogin.
///
// Time-stamp: <Thursday 2024-06-27 13:13:12 +1000 Graham Williams>
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:demopod/dialogs/about.dart';
import 'package:demopod/main.dart';
import 'package:demopod/features/edit_keyvalue.dart';
import 'package:demopod/features/view_keys.dart';
import 'package:demopod/constants/app.dart';
import 'package:demopod/utils/rdf.dart';

import 'package:solidpod/solidpod.dart'
    show
        AppInfo,
        GrantPermissionUi,
        KeyManager,
        changeKeyPopup,
        deleteDataFile,
        deleteLogIn,
        getDataDirPath,
        getEncKeyPath,
        getWebId,
        logoutPopup,
        uploadFile,
        downloadFile,
        getFileSize,
        readPod;

// TODO 20240515 gjw For now we will list all the imports so we can manage the
// API evolution. Eventually we will simply just import the package.

/// A widget for the demonstration screen of the application.

class Home extends StatefulWidget {
  /// Initialise widget variables.

  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  String sampleText = '';
  // Step 1: Loading state variable.

  bool _isLoading = false;

  // Indicator for write encrypted/plaintext data
  bool _writeEncrypted = true;

  // The current webID
  String? _webId;

  @override
  void initState() {
    super.initState();
  }

  void _resetWebId() {
    setState(() {
      _webId = null;
    });
  }

  Future<void> _showPrivateData(String title) async {
    setState(() {
      // Begin loading.

      _isLoading = true;
    });

    // final appName = await getAppName();
    try {
      // final filePath = '$appName/encryption/enc-keys.ttl';
      final filePath = await getEncKeyPath();
      final fileContent = await readPod(
        filePath,
        context,
        const Home(),
      );

      //await Navigator.pushReplacement( // this won't show the file content if POD initialisation has just been performed
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewKeys(
            keyInfo: fileContent!,
            title: title,
          ),
        ),
      );
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

      final fileContent = await readPod(filePath, context, const Home());
      final pairs = fileContent == null ? null : await parseTTLStr(fileContent);

      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => KeyValueEdit(
                  title: 'Basic Key Value Editor',
                  fileName: fileName,
                  keyValuePairs: pairs,
                  encrypted: _writeEncrypted,
                  child: const Home())));
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

  Widget _build(BuildContext context, String title) {
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

    final webid = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _webId == null ? 'WebID: Not Logged In' : 'WebID: $_webId',
          style: TextStyle(
            color: _webId == null ? Colors.red : Colors.green,
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
          'Pod Data File',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final uploadButton = ElevatedButton(
        child: const Text('Upload Binary Data'),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles();

          if (result != null) {
            final file = File(result.files.single.path!);
            await uploadFile(file);
          } else {
            // User canceled the picker
            print('No file selected');
          }
        });

    final downloadButton = ElevatedButton(
        child: const Text('Download Binary Data'),
        onPressed: () async {
          final localFile = 'binary_data.bin';
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: localFile,
          );

          if (outputFile == null) {
            // User canceled the picker
            debugPrint('Cancelled');
          } else {
            final remoteFileName = localFile;
            await downloadFile(remoteFileName, File(outputFile));
          }
        });

    // TODO 20240524 gjw A WORK IN PROGRESS TO MIGRATE THE WIDGETS BELOW UP
    // HERE.

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
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        date,
                        webid,
                        largeGapV,
                        welcomeHeading,
                        smallGapV,
                        ElevatedButton(
                          child: const Text('Show Pod Data File'),
                          onPressed: () async {
                            // TODO 20240627 gjw LOGICALLY THIS SEEMS ODD. I
                            // WANT TO SHOW THE POD DATA FILE BUT I CALL A
                            // FUNCTION TO WIRE PRIVATE DATA?
                            await _writePrivateData();
                          },
                        ),
                        smallGapV,
                        uploadButton,
                        smallGapV,
                        downloadButton,
                        smallGapV,
                        // ElevatedButton(
                        //     child: const Text('Get File Header'),
                        //     onPressed: () async {
                        //       final fileUrl = await getFileUrl([
                        //         await getDataDirPath(),
                        //         'binary_data.bin'
                        //       ].join('/'));
                        //       final header = await getResourceHeader(fileUrl);
                        //       print(header);
                        //     }),
                        // smallGapV,

                        // SolidPod API: deleteDataFile()
                        ElevatedButton(
                            onPressed: () async =>
                                deleteDataFile(dataFile, context),
                            child: const Text('Delete Pod Data File')),
                        smallGapV,
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              smallGapH,
                              const Text(
                                'Encrypt Data?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              smallGapH,
                              Switch(
                                value: _writeEncrypted,
                                onChanged: (val) {
                                  setState(() {
                                    _writeEncrypted = val;
                                    debugPrint(
                                        '_writeEncrypted = $_writeEncrypted');
                                  });
                                },
                              )
                            ]),
                        largeGapV,
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Security Key Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        smallGapV,
                        ElevatedButton(
                          child: const Text('Show Security Key (Encrypted)'),
                          onPressed: () async {
                            await _showPrivateData(title);
                          },
                        ),
                        smallGapV,
                        ElevatedButton(
                            onPressed: () {
                              changeKeyPopup(context, widget);
                            },
                            child: const Text('Change Security Key on Pod')),
                        smallGapV,
                        ElevatedButton(
                          child: const Text('Forget Security Key Locally'),
                          onPressed: () async {
                            late String msg;
                            try {
                              await KeyManager.forgetSecurityKey();
                              msg = 'Successfully forgot local security key.';
                              _resetWebId();
                            } on Exception catch (e) {
                              msg = 'Failed to forget local security key: $e';
                            }
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Notice'),
                                content: Text(msg),
                                actions: [
                                  ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'))
                                ],
                              ),
                            );
                          },
                        ),
                        largeGapV,
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solid Server Login Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // TODO 20240515 gjw Add a tooltip for the next button:
                        //
                        // This will remove from our local device's memory the
                        // solid pod login information so that the next time you
                        // start up the app you will need to login to your solid
                        // server hosting your pod.
                        ElevatedButton(
                          child: const Text('Forget Remote Solid Server Login'),
                          onPressed: () async {
                            final deleteRes = await deleteLogIn();

                            var deleteMsg = '';

                            if (deleteRes) {
                              deleteMsg =
                                  'Successfully forgot remote solid server login info';
                            } else {
                              deleteMsg =
                                  'Failed to forget login info. Try again in a while';
                            }

                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Notice'),
                                content: Text(deleteMsg),
                                actions: [
                                  ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'))
                                ],
                              ),
                            );

                            _resetWebId();
                          },
                        ),
                        smallGapV,
                        // TODO 20240515 gjw Add a tooltip for the next button:
                        //
                        // This will remove send a request through the browser
                        // to the remote solid server to log the suer out of their
                        // Pod.
                        //
                        // Some clarifications needed here:
                        //
                        // 1. On my Brave browser it displays the sign out page
                        // with Yes/No options. Apparently that does not appear
                        // on all browsers?
                        //
                        // 2. Anushka commented that it may not actually log you
                        // out?
                        //
                        // 3. Explain how this is different conceptually to the
                        // delteLogIn().
                        //
                        ElevatedButton(
                            onPressed: () async {
                              await logoutPopup(context, const DemoPod());
                            },
                            child:
                                const Text('Logout From Remote Solid Server')),
                        largeGapV,
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resource Permission Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          child: const Text(
                              'Add/Delete Permissions from Resources'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GrantPermissionUi(
                                backgroundColor: titleBackgroundColor,
                                child: Home(),
                              ),
                            ),
                          ),
                        ),
                        smallGapV,
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<({String name, String? webId})> _getInfo() async =>
      (name: await AppInfo.name, webId: await getWebId());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String name, String? webId})>(
      future: _getInfo(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final appName = snapshot.data?.name;
          final title = 'Demonstrating solidpod functionality using '
              '${appName!.isNotEmpty ? appName[0].toUpperCase() + appName.substring(1) : ""}';
          _webId = snapshot.data?.webId;
          return _build(context, title);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
