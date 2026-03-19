/// Extracted UI sections for the FileService screen.
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

/// Builds a progress bar showing operation status.

Widget buildProgressBar(String message, bool isDone, double percent) {
  const smallGapH = SizedBox(width: 10);
  const textStyle = TextStyle(
    color: Colors.green,
    fontWeight: FontWeight.bold,
  );

  final prefix = Text(message, style: textStyle);
  final suffix = Text('${(percent * 100).toInt()}%', style: textStyle);
  final progress = SizedBox(
    width: 300,
    height: 10,
    child: LinearProgressIndicator(
      value: percent,
      minHeight: 2,
      backgroundColor: Colors.black12,
      color: Colors.greenAccent,
    ),
  );

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[prefix, smallGapH, progress, smallGapH, suffix],
  );
}

/// Builds the upload section UI.

List<Widget> buildUploadSectionUI({
  required String defaultRemoteFileName,
  required String? uploadFile,
  required bool uploadDone,
  required bool uploadInProgress,
  required TextEditingController remoteFolderController,
  required TextEditingController keyRefFolderController,
  required Widget browseButton,
  required Widget uploadButton,
}) {
  const smallGapH = SizedBox(width: 10);
  const smallGapV = SizedBox(height: 10);

  return [
    Text(
      'Upload a local large file and save it as "$defaultRemoteFileName" in POD',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    smallGapV,
    Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(450),
      },
      children: [
        TableRow(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  uploadFile ??
                      'Click the Browse button to choose a local file',
                  style: TextStyle(
                    color: uploadFile == null ? Colors.red : Colors.blue,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
                smallGapH,
                if (uploadDone) const Icon(Icons.done, color: Colors.green),
              ],
            ),
          ],
        ),
        TableRow(
          children: [
            TextFormField(
              controller: remoteFolderController,
              enabled: !(uploadInProgress || uploadDone),
              decoration: const InputDecoration(
                hintText:
                    '(Optional) save to folder in POD, e.g. dir1/dir2/',
                hintStyle: TextStyle(
                  color: Colors.brown,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        TableRow(children: [
          TextFormField(
            controller: keyRefFolderController,
            enabled: !(uploadInProgress || uploadDone),
            decoration: const InputDecoration(
              hintText:
                  '(Optional) Inherit encryption key of folder in POD, e.g. dir1/',
              hintStyle: TextStyle(
                color: Colors.brown,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          ),
        ]),
      ],
    ),
    smallGapV,
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        browseButton,
        smallGapH,
        uploadButton,
      ],
    ),
  ];
}

/// Builds the download section UI.

List<Widget> buildDownloadSectionUI({
  required String defaultRemoteFileName,
  required String? downloadFile,
  required bool downloadDone,
  required Widget downloadButton,
}) {
  const smallGapH = SizedBox(width: 10);
  const smallGapV = SizedBox(height: 10);

  return [
    Text(
      'Download the "$defaultRemoteFileName" from POD',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    smallGapV,
    if (downloadFile != null)
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Save file'),
          smallGapH,
          Text(
            downloadFile,
            style: const TextStyle(color: Colors.blue),
          ),
          smallGapH,
          if (downloadDone) const Icon(Icons.done, color: Colors.green),
        ],
      ),
    smallGapV,
    downloadButton,
  ];
}

/// Builds the delete section UI.

List<Widget> buildDeleteSectionUI({
  required String defaultRemoteFileName,
  required bool deleteInProgress,
  required bool deleteDone,
  required Widget deleteButton,
}) {
  const smallGapH = SizedBox(width: 10);
  const smallGapV = SizedBox(height: 10);

  return [
    Text(
      'Delete the "$defaultRemoteFileName" from POD',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    smallGapV,
    if (deleteInProgress || deleteDone)
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Delete remote file'),
          smallGapH,
          Text(
            defaultRemoteFileName,
            style: const TextStyle(color: Colors.blue),
          ),
          smallGapH,
          if (deleteDone) const Icon(Icons.done, color: Colors.green),
        ],
      ),
    smallGapV,
    deleteButton,
  ];
}

/// Builds the download shared file section UI.

List<Widget> buildDownloadSharedSectionUI({
  required String? downloadSharedFile,
  required bool downloadSharedDone,
  required bool downloadSharedInProgress,
  required TextEditingController sharedUrlController,
  required Widget downloadSharedButton,
}) {
  const smallGapH = SizedBox(width: 10);
  const smallGapV = SizedBox(height: 10);

  return [
    const Text(
      'Download a shared large file from an external POD',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    smallGapV,
    SizedBox(
      width: 550,
      child: TextFormField(
        controller: sharedUrlController,
        enabled: !(downloadSharedInProgress || downloadSharedDone),
        decoration: const InputDecoration(
          hintText: 'URL of shared large file in external POD',
          hintStyle: TextStyle(
            color: Colors.brown,
            fontStyle: FontStyle.italic,
            fontSize: 15,
          ),
        ),
      ),
    ),
    smallGapV,
    if (downloadSharedFile != null)
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Save file'),
          smallGapH,
          Text(
            downloadSharedFile,
            style: const TextStyle(color: Colors.blue),
          ),
          smallGapH,
          if (downloadSharedDone)
            const Icon(Icons.done, color: Colors.green),
        ],
      ),
    smallGapV,
    downloadSharedButton,
  ];
}
