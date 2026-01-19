/// A widget for showing selected recipients in the grant permission form.
///
// Time-stamp: <Sunday 2026-01-18 23:46:10 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Jess Moore, Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/constants/web_acl.dart';

/// A [StatelessWidget] for showing selected recipients in the
/// grant permission form.
///
/// Parameters:
/// - [isExternalRes] - Boolean flag describing whether
/// the resource is externally owned.
/// - [recipientTypeList] - List of recipient type options to show.
/// - [setPublicFunction] - a function for setting recipients to
/// the public.
/// - [setAuthUsersFunction] - a function for setting recipients
/// to all authorised users.
/// - [setIndividualFunction] - a function for selecting an
/// individual recipient webId.
/// - [setGroupFunction] - a function for selecting a
/// group of webIds as recipients.
/// - [updateIndWebIdFunction] - a function to update the selected
/// individual webId.
/// - [updateGroupWebIdFunction] - a function to update the selected
/// group webId list and group name.

class ShowSelectedRecipients extends StatelessWidget {
  const ShowSelectedRecipients({
    super.key,
    required this.selectedRecipientType,
    required this.selectedRecipientDetails,
  });

  /// Selected recipient

  final RecipientType selectedRecipientType;

  /// Selected recipient details

  final String selectedRecipientDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text(
            'Recipient/s: ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Flexible(
            // Show recipients if selected
            child: Text(
              '${selectedRecipientType.type}${selectedRecipientDetails.isEmpty ? "" : " ($selectedRecipientDetails)"}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                // 20251008 gjw Choose blue rather than
                // orange which looks red. The red looks
                // like it is an error. Blue is more
                // neutral.
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
