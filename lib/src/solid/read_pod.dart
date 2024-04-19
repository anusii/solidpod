// TODO 20240417 WHERE'S THER LICENSE AND AUTHOR?

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/popup_login.dart';
import 'package:solidpod/src/solid/utils.dart';

/// Read file content from a POD
///
/// First check if the user is logged in and then
/// read the file content

Future<String> readPod(
    String filePath, BuildContext context, Widget child) async {
  final loggedIn = await checkLoggedIn();

  if (!loggedIn) {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SolidPopupLogin(),
        ));
  }

  // final appInfo = await getAppNameVersion();
  final defaultFolders = await generateDefaultFolders();
  final defaultFiles = await generateDefaultFiles();

  final resCheckList = await initialStructureTest(defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists) {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => InitialSetupScreen(
                resCheckList: resCheckList,
                child: child,
              )),
    );
  }

  final fileUrl = await getResourceUrl(filePath);
  final fileContent = await fetchPrvFile(fileUrl);

  return fileContent;
}
