/// A default app bar.
///
// Time-stamp: <Sunday 2024-07-11 12:55:00 +1000 Anushka Vidange>
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
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
///
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

/// A default app bar that is used when user does not define an app bar for
/// the UI
PreferredSizeWidget defaultAppBar(
  BuildContext context,
  String title,
  Color backgroundColor,
  Widget child,
) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => child),
      ),
    ),
    backgroundColor: backgroundColor,
    title: Text(title),
  );
}
