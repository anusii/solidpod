/// A simple file explorer for navigating through both own and external PODs
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
import 'package:solidpod/src/solid/utils/exceptions.dart';
import 'package:solidpod/src/solid/utils/snack_bar.dart';
import 'package:solidpod/src/solid/write_external_pod.dart';
import 'package:solidpod/src/widgets/loading_screen.dart';

/// A simple file explorer class with two input parameters
class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({
    super.key,
    required this.folderPath,
    required this.child,
    required this.isEditable,
    required this.ownerWebId,
  });

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();

  final String folderPath;
  final Widget child;
  final bool isEditable;
  final String ownerWebId;
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
    try {
      final res = await getResourcesInContainer(widget.folderPath);
      setState(() {
        folderList = res.subDirs;
        fileList = res.files;
        currentPath = widget.folderPath;
        isLoading = false;
      });
    } on AccessForbiddenException catch (e) {
      debugPrint('Exception occured: $e');
      setState(() {
        errMsg = 'You do not have access to this directory';
        isLoading = false;
      });
    } on AccessFailedException catch (e) {
      debugPrint('Exception occured: $e');
      setState(() {
        errMsg = 'Reading directory content failed. Please try again';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Unknown exception occured: $e');
      setState(() {
        errMsg = 'Unkown error occured: $e';
        isLoading = false;
      });
    }
  }

  PreferredSizeWidget defaltAppBar() {
    return AppBar(
      title: const Text('Go back'),
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
            style: const TextStyle(fontSize: 16, color: Colors.grey),
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
        body: const Center(
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
                          trailing: (!section.isFolder && widget.isEditable)
                              ? IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final filePath =
                                        '${widget.folderPath}$item';
                                    final fileContent = await readExternalPod(
                                      filePath,
                                      context,
                                      widget.child,
                                    );

                                    final TextEditingController editController =
                                        TextEditingController(
                                      text: fileContent,
                                    );

                                    if (!context.mounted) return;
                                    await showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Edit File Content'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: TextField(
                                              controller: editController,
                                              autofocus: true,
                                              maxLines:
                                                  null, // allows multiple lines
                                              minLines:
                                                  3, // starts with 3 visible lines
                                              textInputAction:
                                                  TextInputAction.newline,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Enter your file content',
                                                border: OutlineInputBorder(),
                                                alignLabelWithHint: true,
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Cancel -> close dialog
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final newContent =
                                                    editController.text;
                                                // Check if the content has changed
                                                if (newContent != fileContent) {
                                                  final writeFileStatus =
                                                      await writeExternalPod(
                                                    filePath,
                                                    newContent,
                                                    widget.ownerWebId,
                                                    context,
                                                    widget.child,
                                                  );

                                                  if (writeFileStatus ==
                                                      SolidFunctionCallStatus
                                                          .success) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    showSnackBar(
                                                      context,
                                                      'Changes saved successfully!',
                                                      Colors.green,
                                                    );
                                                  } else {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    showSnackBar(
                                                      context,
                                                      'Something went wrong! Please try again.',
                                                      Colors.red,
                                                    );
                                                  }
                                                } else {
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  showSnackBar(
                                                    context,
                                                    'Content has not changed',
                                                    Colors.orange,
                                                  );
                                                }

                                                Navigator.of(context)
                                                    .pop(); // Save -> return value
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                )
                              : null,
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
                                    isEditable: widget.isEditable,
                                    ownerWebId: widget.ownerWebId,
                                    child: FileExplorerScreen(
                                      folderPath: widget.folderPath,
                                      isEditable: widget.isEditable,
                                      ownerWebId: widget.ownerWebId,
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
              },
            ),
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
