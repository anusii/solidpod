/// Extracted widgets for the Permission Callback Demo screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Dawei Chen

library;

import 'package:flutter/material.dart';

/// Builds a step indicator for the workflow progress display.

Widget buildStepIndicator(int step, String label, bool isActive) {
  return Column(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[600] : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.blue[600] : Colors.grey[600],
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ],
  );
}

/// Builds a connector line between step indicators.

Widget buildStepConnector(bool isActive) {
  return Container(
    width: 24,
    height: 2,
    margin: const EdgeInsets.only(bottom: 20),
    color: isActive ? Colors.blue[600] : Colors.grey[300],
  );
}

/// Builds the header section explaining the demo purpose.

Widget buildDemoHeaderSection() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Why Use onPermissionGranted Callback?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'The onPermissionGranted callback allows your app to automatically '
          'continue workflows after users grant permissions. This demo creates '
          'sample files automatically and shows how to share multiple files '
          'sequentially without manual navigation.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
      ],
    ),
  );
}
