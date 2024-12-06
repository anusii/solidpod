/// A function call status for different function calls
///
// Time-stamp: <Thursday 2024-06-27 13:13:12 +1000 Graham Williams>
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

/// Solid function call results
enum SolidFunctionCallStatus {
  /// Read POD data file
  success('success'),

  /// Write to POD data file
  fail('fail'),

  /// Grant permission to other WebIds
  notLoggedIn('notLoggedIn'),

  /// Other WebIds not initialised
  notInitialised('notInitialised');

  /// Constructor
  const SolidFunctionCallStatus(this.value);

  /// String value of the solid function
  final String value;
}
