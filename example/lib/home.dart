/// A screen to demonstrate various capabilities of solidlogin.
///
// Time-stamp: <Wednesday 2025-09-17 08:23:30 +1000 Graham Williams>
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
///
/// Authors: Zheyuan Xu, Anushka Vidanage, Kevin Wang, Dawei Chen, Graham Williams

// TODO 20240411 gjw EITHER REPAIR ALL CONTEXT ISSUES OR EXPLAIN WHY NOT?

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart'
    show
        changeKeyPopup,
        getKeyFromUserIfRequired,
        largeGapV,
        loginIfRequired,
        smallGapV;

import 'package:demopod/constants/app.dart';
import 'package:demopod/dialogs/about.dart';
import 'package:demopod/dialogs/alert.dart';
import 'package:demopod/dialogs/file_metadata.dart';
import 'package:demopod/features/create_acl_inherited_file.dart';
import 'package:demopod/features/edit_keyvalue.dart';
import 'package:demopod/features/file_service.dart';
import 'package:demopod/features/read_acl_inherited_file.dart';
import 'package:demopod/features/view_keys.dart';
import 'package:demopod/main.dart';
import 'package:demopod/utils/rdf.dart';
import 'package:demopod/widgets/home_sections.dart';

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

    try {
      final fileContent = await readPod(
        await getEncKeyPath(),
        pathType: PathType.relativeToPod,
      );

      //await Navigator.pushReplacement( // this won't show the file content if POD initialisation has just been performed
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewKeys(
            keyInfo: fileContent,
            title: title,
          ),
        ),
      );
      //}
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

  Future<void> _readWritePrivateData() async {
    setState(() {
      // Begin loading.
      _isLoading = true;
    });

    // final appName = await getAppName();

    // final fileName = 'test-101.ttl';
    // final fileContent = 'This is for testing writePod.';

    final fileName = _writeEncrypted ? dataFile : dataFilePlain;

    // final dataDirPath = await getDataDirPath();
    // final filePath = [dataDirPath, fileName].join('/');

    List<({String key, dynamic value})>? pairs;

    try {
      final fileContent = await readPod(fileName);

      pairs = await parseTTLStr(fileContent);
    } on Exception catch (e) {
      debugPrint('Exception: $e');
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => KeyValueEdit(
                  title: 'Basic Key Value Editor',
                  fileName: fileName,
                  keyValuePairs: pairs,
                  encrypted: _writeEncrypted,
                  child: widget,
                )));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _readMetaData() async {
    final fileName = _writeEncrypted ? dataFile : dataFilePlain;

    try {
      final fileMetadata = await readResMetadata(fileName);

      final dateFormatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss');

      showFileMetadataDialog(
        context: context,
        fileName: fileName,
        lastModified: dateFormatter.format(fileMetadata.lastModified),
        contentLength: fileMetadata.contentLength.toString(),
        contentType: fileMetadata.contentType,
        allowdAccess: fileMetadata.wacAllow,
      );
    } on Exception catch (e) {
      debugPrint('Exception: $e');
    }
  }

  // Helper method to demonstrate the security key prompt.

  Future<void> _showSecurityKeyPrompt() async {
    // First ensure we are logged in.

    final loggedIn = await loginIfRequired(
      context,
    );

    if (loggedIn) {
      // Forget the security key to ensure the prompt appears.

      await KeyManager.forgetSecurityKey();

      // Inform user about what will happen next.

      await alert(context,
          'The security key has been forgotten locally. The next step will show the security key prompt which you would normally see when accessing secured data after logging in.');

      // Directly show the security key prompt with WebID.

      try {
        // This will trigger the security key prompt since we've forgotten the key.

        await getKeyFromUserIfRequired(context, widget);

        // Only show this if the user enters the correct key.

        await alert(context,
            'Your security key was entered correctly and has been saved for this session.');
      } catch (e) {
        debugPrint('Error: $e');
        await alert(context, 'Error or cancelled: $e');
      }
    }
  }

  Widget _build(BuildContext context, String title) {
    // Build the widget.

    // Include a timestamp on the screen.

    final dateStr = DateFormat('HH:mm:ss dd MMMM yyyy').format(DateTime.now());

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

    final fileDemoButton = ElevatedButton(
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            context,
          );
          if (loggedIn) {
            final webId = await getWebId();
            setState(() {
              _webId = webId;
            });

            await getKeyFromUserIfRequired(context, widget);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FileService(webId: webId!, child: widget),
                ),
              );
            }
          }
        },
        child: const Text('Upload/Download Large File'));

    final inheritanceDemoButton = ElevatedButton(
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            context,
          );
          if (loggedIn) {
            final webId = await getWebId();
            setState(() {
              _webId = webId;
            });

            await getKeyFromUserIfRequired(context, widget);

            if (context.mounted) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateAclInheritedFile()));
            }
          }
        },
        child: const Text('Create Resource with ACL Inheritance'));

    final inheritanceReadButton = ElevatedButton(
        onPressed: () async {
          final loggedIn = await loginIfRequired(
            context,
          );
          if (loggedIn) {
            final webId = await getWebId();
            setState(() {
              _webId = webId;
            });

            await getKeyFromUserIfRequired(context, widget);

            if (context.mounted) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReadAclInheritedFile()));
            }
          }
        },
        child: const Text('Read Resource with ACL Inheritance'));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                                  });
                                },
                              )
                            ]),
                        smallGapV,

                        ElevatedButton(
                          child: const Text('Read/Write Pod Data File'),
                          onPressed: () async {
                            await loginIfRequired(context);
                            await _readWritePrivateData();
                          },
                        ),
                        smallGapV,

                        ElevatedButton(
                          child: const Text('Read Metadata of Pod Data File'),
                          onPressed: () async {
                            await loginIfRequired(context);
                            await _readMetaData();
                          },
                        ),
                        smallGapV,

                        // SolidPod API: deleteDataFile()
                        ElevatedButton(
                            onPressed: () async {
                              final loggedIn = await loginIfRequired(
                                context,
                              );
                              if (loggedIn) {
                                deleteDataFileDialog(dataFile, context);
                              }
                            },
                            child: const Text('Delete Pod Data File')),
                        smallGapV,

                        fileDemoButton,

                        largeGapV,

                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACL Inheritance',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        inheritanceDemoButton,

                        smallGapV,

                        inheritanceReadButton,

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
                          child: const Text(
                              'Show Security Key Prompt (For Demonstration)'),
                          onPressed: () async {
                            // Use the dedicated helper method.

                            await _showSecurityKeyPrompt();
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
                        ...buildLoginManagementSection(
                          context,
                          _resetWebId,
                          () => const DemoPod(),
                        ),
                        ...buildPermissionSection(
                          context,
                          widget,
                          () => const Home(),
                        ),
                        ...buildSetupWizardSection(
                          context,
                          () => const Home(),
                        ),
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
