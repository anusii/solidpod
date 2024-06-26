/// A template app to begin a Solid Pod project.
///
// Time-stamp: <Saturday 2024-05-25 18:48:24 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:keypod/screens/home.dart';
import 'package:keypod/utils/is_desktop.dart';

void main() async {
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

      title: 'KeyPod - Private Solid Pod for Storing Key-Value Pairs',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  // Ready to run the app.

  runApp(const KeyPod());
}

class KeyPod extends StatelessWidget {
  const KeyPod({super.key});

  // This widget is the root of our application.

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Solid Key Pod',
      home: SolidLogin(
        // Images generated using Bing Image Creator from Designer, powered by
        // DALL-E3.

        title: 'SOLID KEY/VALUE POD',
        image: AssetImage('assets/images/keypod_image.jpg'),
        logo: AssetImage('assets/images/keypod_logo.png'),
        link: 'https://github.com/anusii/keypod/blob/main/README.md',
        required: false,
        infoButtonStyle: InfoButtonStyle(
          tooltip: 'Visit the KeyPod documentation.',
        ),
        loginButtonStyle: LoginButtonStyle(
          background: Colors.lightGreenAccent,
        ),
        child: HomeScreen(),
      ),
    );
  }
}
