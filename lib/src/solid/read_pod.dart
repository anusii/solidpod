import 'package:flutter/material.dart';
import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/popup_login.dart';

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
          builder: (context) => const PopupLogin(),
        ));
  }

  final appInfo = await getAppNameVersion();
  final defaultFolders = generateDefaultFolders(appInfo[0] as String);
  final defaultFiles = generateDefaultFiles(appInfo[0] as String);
  final webId = await getWebId();
  final authData = await getAuthData();

  final resCheckList = await initialStructureTest(
      appInfo[0] as String, defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists) {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => InitialSetupScreen(
                authData: authData,
                webId: webId as String,
                appName: appInfo[0] as String,
                resCheckList: resCheckList,
                child: child,
              )),
    );
  }

  final fileUrl = await createFileUrl(filePath);
  final tokenList = await getTokens(fileUrl);
  final fileContent = await fetchPrvFile(
      fileUrl, tokenList[0] as String, tokenList[1] as String);

  return fileContent;
}
