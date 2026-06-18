/// about dialog for the app
///
// Time-stamp: <Thursday 2026-06-18 12:20:15 +1000 Graham Williams>
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:solidpodeg/constants/app.dart';

Future<void> aboutDialog(BuildContext context) async {
  final appInfo = await getAppNameVersion();

  // Fix the use_build_context_synchronously lint error.

  if (context.mounted) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.shortName,
      applicationVersion: appInfo.version,
      applicationLegalese: '© 2024 Software Innovation Institute ANU',
      applicationIcon: Image.asset(
        'assets/images/solidpodeg_logo.png',
        width: 100,
        height: 100,
      ),
      children: [
        const SizedBox(
          width: 300, // Limit the width.
          child: SelectableText('\nA demonstrator of SolidPod functionality.'
              '\n\n'
              'SolidPodEg is a demonstrator app for the solidpod package.'
              ' It provides a collection of buttons to exhibit the different'
              ' calabilities provided by solidpod.\n\n'
              'Authors: Anuska Vidanage, Graham Williams, Dawei Chen.'),
        ),
      ],
    );
  }
}
