/// A template app to begin a Solid Pod project.
///
// Time-stamp: <Thursday 2026-06-18 12:20:57 +1000 Graham Williams>
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
// You should have received a copy of the GNU General Public License along withk
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'dart:ui' show PlatformDispatcher;

import 'package:solidpodeg/constants/app.dart';
import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart' show SolidLogin, InfoButtonStyle;
import 'package:window_manager/window_manager.dart';

import 'package:solidpodeg/home.dart';
import 'package:solidpodeg/utils/is_desktop.dart';

/// Whether [error] is the benign user-cancellation of an AppAuth/OIDC web
/// authentication session — for example when the user dismisses the system
/// sign-in / end-session web sheet, or when the plugin runs a background
/// session check. It does not affect app state and is safe to ignore.

bool _isBenignAuthCancellation(Object error) {
  if (error.runtimeType.toString().contains('UserCancelled')) {
    return true;
  }
  final msg = error.toString();
  return msg.contains('org.openid.appauth') &&
      (msg.contains('Code=-3') ||
          msg.contains('WebAuthenticationSession') ||
          msg.contains('UserCancelled'));
}

void main() async {
  // Suppress the benign AppAuth/OIDC web-session cancellation that the plugin
  // can raise as an uncaught async error (it otherwise surfaces as an
  // "Unhandled Exception" in the console even though the operation in progress
  // — e.g. granting a permission — has already succeeded). All other errors
  // fall through to the previously installed / default handler.

  final previousOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isBenignAuthCancellation(error)) {
      return true;
    }
    return previousOnError?.call(error, stack) ?? false;
  };

  // Remove [debugPrint] messages from production code.

  debugPrint = (String? message, {int? wrapWidth}) {
    null;
  };

  // Suport window size and top placement for desktop apps.

  if (isDesktop(PlatformWrapper())) {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      // Setting [alwaysOnTop] here will ensure the app starts on top of other
      // apps on the desktop so that it is visible. We later turn it of as we
      // don't want to force it always on top.

      alwaysOnTop: true,

      // The [title] is used for the window manager's window title.

      title: 'SolidPodEg - Demonstrate Private Solid Pod',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  // Ready to run the app.

  runApp(const SolidPodEg());
}

class SolidPodEg extends StatelessWidget {
  const SolidPodEg({super.key});

  // This widget is the root of our application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.longName,
      home: SolidLogin(
        // Images generated using Bing Image Creator from Designer, powered by
        // DALL-E3.

        title: AppConstants.longName.toUpperCase(),
        appDirectory: 'solidpodeg',
        image: AssetImage('assets/images/solidpodeg_image.png'),
        logo: AssetImage('assets/images/solidpodeg_logo.png'),
        link:
            'https://github.com/anusii/solidpod/blob/main/solidpodeg/README.md',
        required: false,
        infoButtonStyle: InfoButtonStyle(
          tooltip: 'Visit the SolidPodEg documentation.',
        ),
        clientId: clientIdVal,
        // Use the following schemas depending on the platform
        //  Web: https://anushkavidanage.github.io/solidpod/example/redirect.html
        //  Mobile: com.example.solidpodeg://redirect
        //  Desktop: http://localhost:4400/redirect
        //    (can use any port as long as it matches with the one in your id document)
        redirectUris: redirectUrisList,
        postLogoutRedirectUris: postLogoutRedirectUrisList,
        autoLogin: true,
        child: Home(),
      ),
    );
  }
}
