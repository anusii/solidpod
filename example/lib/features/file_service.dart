/// A widget to demonstrate the upload, download, and delete large files.
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
/// Authors: Dawei Chen

library;

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';

import 'package:demopod/dialogs/alert.dart';
import 'package:demopod/widgets/file_service_sections.dart';

class FileService extends StatefulWidget {
  const FileService({required this.child, required this.webId, super.key});
  final String webId;
  final Widget child;

  @override
  State<FileService> createState() => _FileServiceState();
}

class _FileServiceState extends State<FileService> {
  String defaultRemoteFileName = 'large_file.bin';
  String? uploadFile;
  String? downloadFile;
  String? downloadSharedFile;

  double uploadPercent = 0.0;
  double downloadPercent = 0.0;
  double downloadSharedPercent = 0.0;
  double deletePercent = 0.0;

  bool uploadDone = false;
  bool downloadDone = false;
  bool downloadSharedDone = false;
  bool deleteDone = false;

  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool downloadSharedInProgress = false;
  bool deleteInProgress = false;

  final remoteFolderController = TextEditingController();
  final keyRefFolderController = TextEditingController();
  final sharedUrlController = TextEditingController();

  final smallGapH = const SizedBox(width: 10);
  final smallGapV = const SizedBox(height: 10);
  final largeGapV = const SizedBox(height: 30);

  String getRemoteFileName() =>
      '${remoteFolderController.text.trim()}$defaultRemoteFileName';

  String? getKeyRefPath() {
    final folder = keyRefFolderController.text.trim();
    return folder.isNotEmpty ? folder : null;
  }

  @override
  void initState() {
    super.initState();
    remoteFolderController.addListener(() => remoteFolderController.value =
        remoteFolderController.value.copyWith(
            text: _sanitiseFolderPath(remoteFolderController.text.trim())));
    keyRefFolderController.addListener(() => keyRefFolderController.value =
        keyRefFolderController.value.copyWith(
            text: _sanitiseFolderPath(keyRefFolderController.text.trim())));
  }

  @override
  void dispose() {
    remoteFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browseButton = ElevatedButton(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles();
        if (result != null) {
          setState(() {
            uploadFile = result.files.single.path!;
            uploadDone = false;
            uploadPercent = 0.0;
          });
        }
      },
      child: const Text('Browse'),
    );

    final uploadButton = ElevatedButton(
      onPressed: (uploadFile == null ||
              uploadInProgress ||
              downloadInProgress ||
              downloadSharedInProgress ||
              deleteInProgress)
          ? null
          : () async {
              try {
                setState(() {
                  uploadInProgress = true;
                });

                final keyPath = getKeyRefPath();

                if (keyPath != null) {
                  await setInheritKeyDir(keyPath, createAcl: true);
                }

                if (!context.mounted) return;

                await writeLargeFile(
                    localFilePath: uploadFile!,
                    remoteFilePath: getRemoteFileName(),
                    inheritKeyFrom: keyPath,
                    createAcl: false,
                    onProgress: (sent, total) {
                      setState(() {
                        uploadDone = sent == total;
                        uploadPercent = sent / total;
                      });
                    });
                if (uploadDone) {
                  setState(() {
                    uploadInProgress = false;
                  });
                }
              } on Object catch (e) {
                setState(() {
                  uploadFile = null;
                  uploadInProgress = false;
                });
                if (context.mounted) {
                  await alert(context, 'Failed to send file. $e', 'Error');
                }
                debugPrint('$e');
              }
            },
      child: const Text('Upload'),
    );

    final downloadButton = ElevatedButton(
      onPressed: (uploadInProgress ||
              downloadInProgress ||
              downloadSharedInProgress ||
              deleteInProgress)
          ? null
          : () async {
              String? outputFile = await FilePicker.platform.saveFile(
                dialogTitle: 'Please set the output file:',
                // fileName: 'download.bin',
              );

              if (outputFile == null) {
                // User canceled the picker
                debugPrint('Download is cancelled');
              } else {
                setState(() {
                  downloadFile = outputFile;
                });
                try {
                  // remoteFileUrl ??= await getRemoteFileUrl();
                  setState(() {
                    downloadInProgress = true;
                  });

                  await readLargeFile(
                      remoteFilePath: getRemoteFileName(),
                      localFilePath: outputFile,
                      onProgress: (received, total) {
                        setState(() {
                          downloadDone = received == total;
                          downloadPercent = received / total;
                        });
                      });

                  if (downloadDone) {
                    setState(() {
                      downloadInProgress = false;
                    });
                  }
                } on Object catch (e) {
                  setState(() {
                    downloadFile = null;
                    downloadInProgress = false;
                  });
                  if (context.mounted) {
                    await alert(
                        context, 'Failed to download file. $e', 'Error');
                  }
                  debugPrint('$e');
                }
              }
            },
      child: const Text('Download'),
    );

    final downloadSharedButton = ElevatedButton(
      onPressed: (uploadInProgress ||
              downloadInProgress ||
              downloadSharedInProgress ||
              deleteInProgress)
          ? null
          : () async {
              String? outputFile = await FilePicker.platform.saveFile(
                dialogTitle: 'Please set the output file:',
              );
              if (outputFile == null) {
                // User canceled the picker
                debugPrint('Download is cancelled');
              } else {
                setState(() {
                  downloadSharedFile = outputFile;
                });
                try {
                  setState(() {
                    downloadSharedInProgress = true;
                  });

                  final sharedFileUrl = sharedUrlController.text.trim();
                  if (sharedFileUrl.isEmpty) {
                    final msg = 'Shared file URL is empty';
                    if (context.mounted) await alert(context, msg);
                    throw Exception(msg);
                  }

                  // URL format: https://SERVER_URL/POD_NAME/APP_NAME/data/FILE_PATH
                  final uri = Uri.parse(sharedFileUrl);

                  // [POD_NAME, APP_NAME, data, FILE_PATH]
                  assert(uri.pathSegments.length > 3);

                  final podName = uri.pathSegments.first;
                  final ownerWebId =
                      [uri.origin, podName, 'profile/card#me'].join('/');

                  final fileName = uri.pathSegments
                      .getRange(3, uri.pathSegments.length)
                      .join('/');

                  if (context.mounted) {
                    await readLargeFile(
                        remoteFilePath: fileName,
                        localFilePath: outputFile,
                        ownerWebId: ownerWebId,
                        onProgress: (received, total) {
                          setState(() {
                            downloadSharedDone = received == total;
                            downloadSharedPercent = received / total;
                          });
                        });
                    if (downloadDone) {
                      setState(() {
                        downloadSharedInProgress = false;
                      });
                    }
                  }
                } on Object catch (e) {
                  setState(() {
                    downloadSharedFile = null;
                    downloadSharedInProgress = false;
                  });
                  if (context.mounted) {
                    await alert(
                        context, 'Failed to download shared file. $e', 'Error');
                  }
                  debugPrint('$e');
                }
              }
            },
      child: const Text('Download Shared Large File'),
    );

    final deleteButton = ElevatedButton(
      onPressed: (uploadInProgress ||
              downloadInProgress ||
              downloadSharedInProgress ||
              deleteInProgress)
          ? null
          : () async {
              try {
                // remoteFileUrl ??= await getRemoteFileUrl();
                setState(() {
                  deleteInProgress = true;
                });
                await deleteLargeFile(
                    remoteFilePath: getRemoteFileName(),
                    onProgress: (deleted, total) {
                      setState(() {
                        deleteDone = deleted == total;
                        deletePercent = deleted / total;
                      });
                    });
                if (deleteDone) {
                  setState(() {
                    deleteInProgress = false;
                  });
                }
              } on Object catch (e) {
                setState(() {
                  deleteInProgress = false;
                });
                if (context.mounted) {
                  await alert(context, 'Failed to delete file. $e', 'Error');
                }
                debugPrint('$e');
              }
            },
      child: const Text('Delete'),
    );

    // Widgets of the file upload section

    final uploadSection = buildUploadSectionUI(
      defaultRemoteFileName: defaultRemoteFileName,
      uploadFile: uploadFile,
      uploadDone: uploadDone,
      uploadInProgress: uploadInProgress,
      remoteFolderController: remoteFolderController,
      keyRefFolderController: keyRefFolderController,
      browseButton: browseButton,
      uploadButton: uploadButton,
    );

    // Widgets of the file download section

    final downloadSection = buildDownloadSectionUI(
      defaultRemoteFileName: defaultRemoteFileName,
      downloadFile: downloadFile,
      downloadDone: downloadDone,
      downloadButton: downloadButton,
    );

    // Widgets of the shared file download section

    final downloadSharedSection = buildDownloadSharedSectionUI(
      downloadSharedFile: downloadSharedFile,
      downloadSharedDone: downloadSharedDone,
      downloadSharedInProgress: downloadSharedInProgress,
      sharedUrlController: sharedUrlController,
      downloadSharedButton: downloadSharedButton,
    );

    // Widgets of the file delete section

    final deleteSection = buildDeleteSectionUI(
      defaultRemoteFileName: defaultRemoteFileName,
      deleteInProgress: deleteInProgress,
      deleteDone: deleteDone,
      deleteButton: deleteButton,
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                largeGapV,
                largeGapV,

                // Upload

                ...uploadSection,

                largeGapV,

                // Download

                ...downloadSection,

                largeGapV,

                // Delete

                ...deleteSection,

                largeGapV,

                // Download shared file

                ...downloadSharedSection,
              ],
            ),

            // Uploading progress bar

            if (uploadInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child:
                    buildProgressBar('Uploading:', uploadDone, uploadPercent),
              ),

            // Downloading progress bar

            if (downloadInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: buildProgressBar(
                    'Downloading:', downloadDone, downloadPercent),
              ),

            // Downloading shared file progress bar

            if (downloadSharedInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: buildProgressBar(
                    'Downloading:', downloadSharedDone, downloadSharedPercent),
              ),

            // Deleting progress bar

            if (deleteInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: buildProgressBar('Deleting:', deleteDone, deletePercent),
              ),

            // Navigate back to demo page
            Positioned(
              top: 10,
              left: 10,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Demo'),
              ),
            ),

            // Widget to show Web ID
            Positioned(
              bottom: 10,
              right: 10,
              child: Text(
                'WEB ID - ${widget.webId}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

String _sanitiseFolderPath(String folderPath) {
  final folder = folderPath.endsWith('/') ? folderPath : '$folderPath/';

  return folder.startsWith('/') ? folder.substring(1) : folder;
}
