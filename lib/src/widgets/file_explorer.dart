/// A simple file explorer for navigating through both own and external PODs
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Anushka Vidanage
///
library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/read_external_pod.dart';
import 'package:solidpod/src/solid/solid_func_call_status.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A simple file explorer class with two input parameters
class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({
    super.key,
    required this.folderPath,
    required this.child,
  });

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();

  final String folderPath;
  final Widget child;
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  String currentPath = '';
  List<String> folderList = [];
  List<String> fileList = [];

  bool isLoading = true;
  String errMsg = '';

  @override
  void initState() {
    super.initState();
    _getResources();
  }

  Future<void> _getResources() async {
    final res = await getResourcesInExContainer(widget.folderPath);

    setState(() {
      if (res == SolidFunctionCallStatus.forbidden) {
        errMsg = 'You do not have access to this directory';
        isLoading = false;
      } else if (res == SolidFunctionCallStatus.fail) {
        errMsg = 'Reading directory conten failed. Please try again';
        isLoading = false;
      } else {
        folderList = res.subDirs;
        fileList = res.files;
        currentPath = widget.folderPath;
        isLoading = false;
      }
    });
  }

  PreferredSizeWidget defaltAppBar() {
    return AppBar(
      title: Text('Go back'),
      leading: currentPath.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // final parent = Directory(currentPath).parent;
                // _loadDirectory(parent.path);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => widget.child),
                );
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: loadingScreen(normalLoadingScreenHeight));
    }

    if (errMsg.isNotEmpty) {
      return Scaffold(
        appBar: defaltAppBar(),
        body: Center(
          child: Text(
            errMsg,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final List<_Section> sections = [];

    if (folderList.isNotEmpty) {
      sections.add(
        _Section(
          title: 'Folders',
          items: folderList,
          isFolder: true,
        ),
      );
    }

    if (fileList.isNotEmpty) {
      sections.add(
        _Section(
          title: 'Files',
          items: fileList,
          isFolder: false,
        ),
      );
    }

    // If both are empty, show placeholder
    if (sections.isEmpty) {
      return Scaffold(
        appBar: defaltAppBar(),
        body: Center(
          child: Text(
            'No directories or files found.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: defaltAppBar(),
      body: // One scrollable list
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentPath,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis, // truncate if long
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = sections[sectionIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // List items
                      ListView.builder(
                        itemCount: section.items.length,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable inner scroll
                        itemBuilder: (context, index) {
                          final item = section.items[index];
                          return ListTile(
                            leading: Icon(
                              section.isFolder
                                  ? Icons.folder
                                  : Icons.insert_drive_file,
                              color:
                                  section.isFolder ? Colors.amber : Colors.blue,
                            ),
                            title: Text(item),
                            onTap: () async {
                              if (section.isFolder) {
                                final newFolderPath =
                                    '${widget.folderPath}$item/';
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FileExplorerScreen(
                                      folderPath: newFolderPath,
                                      child: FileExplorerScreen(
                                        folderPath: widget.folderPath,
                                        child: widget.child,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                final filePath = '${widget.folderPath}$item';
                                final fileContent = await readExternalPod(
                                  filePath,
                                  context,
                                  widget.child,
                                );
                                print(fileContent);

                                if (fileContent != null &&
                                    fileContent !=
                                        SolidFunctionCallStatus.notLoggedIn) {
                                  if (!context.mounted) return;
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('File content'),
                                      content: Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          Container(
                                            width: double.infinity,
                                            height: 300,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Text(fileContent as String),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            // Close the dialog
                                            Navigator.of(ctx).pop();
                                          },
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  await alert(
                                    context,
                                    'The file $item could not be found!',
                                  );
                                }
                              }
                              // handle open file/folder
                            },
                          );
                        },
                      ),
                    ],
                  );
                }),
          ),
        ],
      ),
    );
  }
}

// Helper class for sections
class _Section {
  final String title;
  final List<String> items;
  final bool isFolder;

  _Section({
    required this.title,
    required this.items,
    required this.isFolder,
  });
}
