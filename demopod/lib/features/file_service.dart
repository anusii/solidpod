import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';
import 'package:path/path.dart' as path;

class FileService extends StatefulWidget {
  const FileService({super.key});

  @override
  State<FileService> createState() => _FileServiceState();
}

class _FileServiceState extends State<FileService> {
  String? localFilePath;
  String? remoteFileUrl;
  double percent = 0.0;
  bool done = false;
  // bool inProgress = false;

  Future<String?> getRemoteFileUrl() async {
    if (localFilePath != null) {
      return await getFileUrl(
          [await getDataDirPath(), path.basename(localFilePath!)].join('/'));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final progressBar = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percent,
          color: Colors.green,
        ),
        Text(done ? 'Done' : '${(percent * 100).toInt()}%'),
      ],
    );

    final snackBar = SnackBar(
        content: progressBar,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ));

    final browseButton = ElevatedButton(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles();
        if (result != null) {
          setState(() {
            localFilePath = result.files.single.path!;
          });
          final fileUrl = await getRemoteFileUrl();
          setState(() {
            remoteFileUrl = fileUrl;
          });
        }
      },
      child: const Text('Browse'),
    );

    final uploadButton = ElevatedButton(
      onPressed: localFilePath == null
          ? null
          : () async {
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              await sendLargeFile(
                  localFilePath: localFilePath!,
                  remoteFileUrl: remoteFileUrl!,
                  onProgress: (sent, total) {
                    setState(() {
                      done = sent == total;
                      percent = sent / total;
                    });
                  });
            },
      child: const Text('Upload'),
    );

    final uploadRow = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('Upload: '),
        Text(
          localFilePath ?? 'Choose a file',
          style: TextStyle(
              color: localFilePath != null ? Colors.black : Colors.red),
        ),
        const SizedBox(width: 10),
        browseButton,
        const SizedBox(width: 10),
        uploadButton,
      ],
    );

    final downloadButton = ElevatedButton(
      onPressed: remoteFileUrl == null
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
                await getLargeFile(
                    remoteFileUrl: remoteFileUrl!, localFilePath: outputFile);
              }
            },
      child: const Text('Download'),
    );

    final downloadRow = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('Download: '),
        Text(
          remoteFileUrl ?? 'Please first upload a file',
          style: TextStyle(
              color: remoteFileUrl != null ? Colors.black : Colors.red),
        ),
        const SizedBox(width: 10),
        downloadButton,
      ],
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            uploadRow,
            const SizedBox(height: 10),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            downloadRow,
            // const SizedBox(height: 10),
            // Text('Upload progress: ${(100 * percent).toInt()}%'),
          ],
        ),
      ),
    );
  }
}
