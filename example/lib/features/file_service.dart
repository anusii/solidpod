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
  String? uploadSharedFile;
  String? downloadFile;
  String? downloadSharedFile;

  double uploadPercent = 0.0;
  double uploadSharedPercent = 0.0;
  double downloadPercent = 0.0;
  double downloadSharedPercent = 0.0;
  double deletePercent = 0.0;

  bool uploadDone = false;
  bool uploadSharedDone = false;
  bool downloadDone = false;
  bool downloadSharedDone = false;
  bool deleteDone = false;

  bool uploadInProgress = false;
  bool uploadSharedInProgress = false;
  bool downloadInProgress = false;
  bool downloadSharedInProgress = false;
  bool deleteInProgress = false;

  final remoteFolderController = TextEditingController();
  final keyRefFolderController = TextEditingController();
  final sharedUrlController = TextEditingController();
  final uploadSharedUrlController = TextEditingController();
  final uploadSharedKeyRefController = TextEditingController();

  final smallGapH = const SizedBox(width: 10);
  final smallGapV = const SizedBox(height: 10);
  final largeGapV = const SizedBox(height: 30);

  String getRemoteFileName() =>
      '${remoteFolderController.text.trim()}$defaultRemoteFileName';

  String? getKeyRefPath() {
    final folder = keyRefFolderController.text.trim();
    return folder.isNotEmpty ? folder : null;
  }

  String? getUploadSharedKeyRefPath() {
    final folder = uploadSharedKeyRefController.text.trim();
    return folder.isNotEmpty ? folder : null;
  }

  /// Parse an external large-file URL of the form
  /// `https://SERVER/POD_NAME/APP_NAME/data/FILE_PATH` into the owner's WebID
  /// and the path of the file relative to the POD root.
  ///
  /// The returned [podRelativePath] keeps the `APP_NAME/data/FILE_PATH`
  /// segments verbatim, so the file is read/written at exactly the URL the
  /// user supplied (rather than under the current app's own data directory).
  /// Pass it to the large-file APIs together with `isPodRelativePath: true`.
  ///
  /// Throws a [FormatException] with an actionable message if [url] is not a
  /// valid http(s) URL with at least the four expected path segments. We
  /// validate explicitly (rather than via `assert`) so the error reaches the
  /// user instead of crashing in debug or silently misbehaving in release.

  ({String ownerWebId, String podRelativePath}) parseExternalFileUrl(
      String url) {
    final uri = Uri.parse(url);

    // Ignore any empty segments produced by leading/trailing slashes.
    // Expected: [POD_NAME, APP_NAME, data, FILE_PATH, ...].

    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList(growable: false);

    if ((uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        segments.length < 4) {
      throw const FormatException(
        'Invalid destination URL. Expected the form '
        'https://SERVER/POD_NAME/APP_NAME/data/FILE_PATH',
      );
    }

    final podName = segments.first;
    final ownerWebId = [uri.origin, podName, 'profile/card#me'].join('/');

    // Everything after POD_NAME is relative to the POD root, i.e.
    // APP_NAME/data/FILE_PATH.

    final podRelativePath = segments.skip(1).join('/');

    return (ownerWebId: ownerWebId, podRelativePath: podRelativePath);
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
    keyRefFolderController.dispose();
    sharedUrlController.dispose();
    uploadSharedUrlController.dispose();
    uploadSharedKeyRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browseButton = ElevatedButton(
      onPressed: () async {
        final result = await FilePicker.pickFiles();
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
              uploadSharedInProgress ||
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

    final browseSharedButton = ElevatedButton(
      onPressed: () async {
        final result = await FilePicker.pickFiles();
        if (result != null) {
          setState(() {
            uploadSharedFile = result.files.single.path!;
            uploadSharedDone = false;
            uploadSharedPercent = 0.0;
          });
        }
      },
      child: const Text('Browse'),
    );

    final uploadSharedButton = ElevatedButton(
      onPressed: (uploadSharedFile == null ||
              uploadInProgress ||
              uploadSharedInProgress ||
              downloadInProgress ||
              downloadSharedInProgress ||
              deleteInProgress)
          ? null
          : () async {
              try {
                final destUrl = uploadSharedUrlController.text.trim();
                if (destUrl.isEmpty) {
                  const msg = 'Destination URL is empty';
                  await alert(context, msg);
                  throw Exception(msg);
                }

                setState(() {
                  uploadSharedInProgress = true;
                });

                final parsed = parseExternalFileUrl(destUrl);
                final keyPath = getUploadSharedKeyRefPath();

                if (!context.mounted) return;

                await writeLargeFile(
                    localFilePath: uploadSharedFile!,
                    remoteFilePath: parsed.podRelativePath,
                    isPodRelativePath: true,
                    ownerWebId: parsed.ownerWebId,
                    inheritKeyFrom: keyPath,
                    createAcl: false,
                    encrypted: keyPath != null,
                    onProgress: (sent, total) {
                      setState(() {
                        uploadSharedDone = sent == total;
                        uploadSharedPercent = sent / total;
                      });
                    });
                if (uploadSharedDone) {
                  setState(() {
                    uploadSharedInProgress = false;
                  });
                }
              } on Object catch (e) {
                setState(() {
                  uploadSharedInProgress = false;
                });
                if (context.mounted) {
                  await alert(context,
                      'Failed to upload file to external POD. $e', 'Error');
                }
                debugPrint('$e');
              }
            },
      child: const Text('Upload to External POD'),
    );

    final downloadButton = ElevatedButton(
      onPressed: (uploadInProgress ||
              downloadInProgress ||
              downloadSharedInProgress ||
              deleteInProgress)
          ? null
          : () async {
              String? outputFile = await FilePicker.saveFile(
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
              String? outputFile = await FilePicker.saveFile(
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

                  // URL format:
                  // https://SERVER_URL/POD_NAME/APP_NAME/data/FILE_PATH
                  final parsed = parseExternalFileUrl(sharedFileUrl);

                  if (context.mounted) {
                    await readLargeFile(
                        remoteFilePath: parsed.podRelativePath,
                        isPodRelativePath: true,
                        localFilePath: outputFile,
                        ownerWebId: parsed.ownerWebId,
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

    // Widgets of the upload-to-external-POD section

    final uploadSharedSection = buildUploadSharedSectionUI(
      uploadSharedFile: uploadSharedFile,
      uploadSharedDone: uploadSharedDone,
      uploadSharedInProgress: uploadSharedInProgress,
      uploadSharedUrlController: uploadSharedUrlController,
      uploadSharedKeyRefController: uploadSharedKeyRefController,
      browseSharedButton: browseSharedButton,
      uploadSharedButton: uploadSharedButton,
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

                // Upload to external POD

                ...uploadSharedSection,

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

            // Uploading to external POD progress bar

            if (uploadSharedInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: buildProgressBar(
                    'Uploading:', uploadSharedDone, uploadSharedPercent),
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
