/// Common functions used across the package.
///
// Time-stamp: <Friday 2024-02-16 10:59:10 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';
import 'package:solidpod/src/widgets/build_message_container.dart';

/// Get the height of screen.

// double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

/// Get the width of screen.

// double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

/// A widget displaying an alert for the user noticing about the newly
/// created POD or missing resources from the POD.
///
/// The widget will inform the user about creating/ re-creating these recources.

SizedBox initialSetupWelcome(BuildContext context) {
  return SizedBox(
    child: Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: lightGreen,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.playlist_add,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            initialStructureWelcome,
            style: TextStyle(
              fontSize: 25,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: buildMsgBox(
                context, 'warning', initialStructureTitle, initialStructureMsg),
          ),
        ],
      ),
    ),
  );
}

/// Creates a row widget displaying a piece of profile information.
///
/// This function constructs a `Row` widget designed to display a single piece
/// of information in a profile UI. It is primarily used for laying out text-based
/// information such as names, titles, or other key details in the profile section.
///
/// // comment out the following function as it is not used in the current version
// of the app, anushka might need to use to in the future so keeping it here.

// Row buildInfoRow(String profName) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: <Widget>[
//       Text(
//         profName,
//         style: TextStyle(
//           color: Colors.grey[800],
//           letterSpacing: 2.0,
//           fontSize: 17.0,
//           fontWeight: FontWeight.bold,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ],
//   );
// }

/// Builds a row widget displaying a label and its corresponding value.
///
/// This function creates a [Column] widget containing a [Row] with two text elements:
/// one for the label and the other for the profile name. It's used to display
/// information in a key-value pair format, where `labelName` is the key and
/// `profName` is the value.
///
/// // comment out the following function as it is not used in the current version
// of the app, anushka might need to use to in the future so keeping it here.

// Column buildLabelRow(String labelName, String profName, BuildContext context) {
//   return Column(
//     children: [
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: <Widget>[
//           Text(
//             '$labelName: ',
//             style: TextStyle(
//               color: kTitleTextColor,
//               letterSpacing: 2.0,
//               fontSize: screenWidth(context) * 0.015,
//               fontWeight: FontWeight.bold,
//               //fontFamily: 'Poppins',
//             ),
//           ),
//           profName.length > longStrLength
//               ? Tooltip(
//                   message: profName,
//                   height: 30,
//                   textStyle: const TextStyle(fontSize: 15, color: Colors.white),
//                   verticalOffset: kDefaultPadding / 2,
//                   child: Text(
//                     truncateString(profName),
//                     style: TextStyle(
//                       color: Colors.grey[800],
//                       letterSpacing: 2.0,
//                       fontSize: screenWidth(context) * 0.015,
//                     ),
//                   ),
//                 )
//               : Text(
//                   profName,
//                   style: TextStyle(
//                       color: Colors.grey[800],
//                       letterSpacing: 2.0,
//                       fontSize: screenWidth(context) * 0.015),
//                 ),
//         ],
//       ),
//       SizedBox(
//         height: screenHeight(context) * 0.005,
//       )
//     ],
//   );
// }
