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
  String? filePath;
  double percent = 0.0;
  bool done = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Upload File: ${filePath ?? 'No file chosen'}'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  filePath = result.files.single.path!;
                });
              }
            },
            child: const Text('Browse'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: filePath == null
                ? null
                : () async {
                    final remoteFileUrl = await getFileUrl([
                      await getDataDirPath(),
                      path.basename(filePath!)
                    ].join('/'));
                    await sendLargeFile(
                        localFilePath: filePath!,
                        remoteFileUrl: remoteFileUrl,
                        onProgress: (sent, total) {
                          setState(() {
                            done = sent == total;
                            percent = sent / total;
                          });
                        });
                  },
            child: const Text('Upload'),
          ),
          const SizedBox(height: 10),
          Text('Upload progress: ${(100 * percent).toInt()}%'),
        ],
      ),
    );
  }
}
