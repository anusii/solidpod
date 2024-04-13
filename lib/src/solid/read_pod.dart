// ignore_for_file: use_build_context_synchronously

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
  final defaultFolders = generateDefaultFolders(appInfo.name);
  final defaultFiles = generateDefaultFiles(appInfo.name);
  final webId = await getWebId();
  assert(webId != null);
  final authData = await AuthDataManager.loadAuthData();
  assert(authData != null);

  final resCheckList =
      await initialStructureTest(appInfo.name, defaultFolders, defaultFiles);
  final allExists = resCheckList.first as bool;

  if (!allExists) {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => InitialSetupScreen(
                authData: authData as Map<dynamic, dynamic>,
                webId: webId as String,
                appName: appInfo.name,
                resCheckList: resCheckList,
                child: child,
              )),
    );
  }

  final fileUrl = await createFileUrl(filePath);
  final tokens = await getTokens(fileUrl);
  final fileContent =
      await fetchPrvFile(fileUrl, tokens.accessToken, tokens.dPopToken);

  return fileContent;
}
