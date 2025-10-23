/// A template app to begin a Solid Pod project.
///
// Time-stamp: <Monday 2025-07-14 11:46:50 +1000 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

import 'package:solidui/solidui.dart' show SolidLogin, InfoButtonStyle;

import 'package:demopod/home.dart';
import 'package:demopod/utils/is_desktop.dart';

void main() async {
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

      title: 'DemoPod - Demonstrate Private Solid Pod',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  // Ready to run the app.

  runApp(const DemoPod());
}

class DemoPod extends StatelessWidget {
  const DemoPod({super.key});

  // This widget is the root of our application.

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Solid Pod Demonstrator',
      home: SolidLogin(
        // Images generated using Bing Image Creator from Designer, powered by
        // DALL-E3.

        title: 'SOLID POD DEMONSTRATOR',
        appDirectory: 'exampleApp',
        image: AssetImage('assets/images/demopod_image.png'),
        logo: AssetImage('assets/images/demopod_logo.png'),
        link: 'https://github.com/anusii/solidpod/blob/main/demopod/README.md',
        required: false,
        infoButtonStyle: InfoButtonStyle(
          tooltip: 'Visit the DemoPod documentation.',
        ),
        child: Home(),
      ),
    );
  }
}
