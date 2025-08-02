/// Check if we are running a desktop (and not a browser).
///
// Time-stamp: <Saturday 2025-08-02 21:01:01 +1000 Jess Moore>
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
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:universal_io/io.dart' show Platform;

/// Checks the platform type to determine whether running on
/// a mobile device.
bool isPhone() {
  /// Returns true if running on iOS or Android

  if (Platform.isIOS || Platform.isAndroid) {
    return true;
  } else {
    return false;
  }
}

// coverage:ignore-end
