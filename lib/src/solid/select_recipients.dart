/// Button list for selecting recipients.
///
// Time-stamp: <Sunday 2026-01-18 22:46:10 +1100 Graham Williams>
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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/grant_permission_helper.dart';

/// A [StatefulWidget] for a container of buttons for
/// selecting recipients in the grant permission form.
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

class SelectRecipients extends StatefulWidget {
  /// A flag denoting whether the resource is externally owned.

  final bool isExternalRes;

  /// The list of types of recipients to show in form. By default
  /// all four types of recipient are listed.

  final List<String> recipientTypeList;

  /// Map of data files on a user's POD used to extract the
  /// user's recipient list by the WebIdTextInputScreen.
  /// If not provided, the WebIdTextInputScreen will read the
  /// user's files in their app data folder on their Pod to
  /// fetch the ACLs needed to derive the user's recipient list.

  final Map<String, dynamic> dataFilesMap;

  /// A function for setting recipients to the public.

  final Function setPublicFunction;

  /// A function for setting recipients to all authorised users.

  final Function setAuthUsersFunction;

  /// A function for selecting an individual recipient webId.

  final Function setIndividualFunction;

  /// A function for selecting a group of webIds as recipients.

  final Function setGroupFunction;

  /// A function to update the selected individual webId.
  ///
  final Function updateIndWebIdFunction;

  /// A function to update the selected group webId list and group
  /// name.

  final Function updateGroupWebIdFunction;

  const SelectRecipients({
    super.key,
    required this.isExternalRes,
    required this.recipientTypeList,
    required this.setPublicFunction,
    required this.setAuthUsersFunction,
    required this.setIndividualFunction,
    required this.setGroupFunction,
    required this.updateIndWebIdFunction,
    required this.updateGroupWebIdFunction,
    this.dataFilesMap = const {},
  });

  @override
  State<SelectRecipients> createState() => _SelectRecipientsState();
}

class _SelectRecipientsState extends State<SelectRecipients> {
  /// Define recipient type list

  List<RecipientType> recipientTypeList = [];

  /// Selected recipient type

  RecipientType? _selectedRecipientType;

  // Allowed recipient types

  List<RecipientType> allowedRecipientTypes = [];

  @override
  void initState() {
    super.initState();

    // Load recipient type list to be displayed
    for (final recTypeStr in widget.recipientTypeList) {
      recipientTypeList.add(RecipientType.getInstanceByValue(recTypeStr));
    }

    // jesscmoore 20260118: requires check grant/revoke to
    // public/auth works on external resources
    // av 20250526:
    // Public and Authenticated recipient buttons are
    // disabled currently because
    // providing public or authenticated permissions to
    // external resources is not yet implemented in
    // [grantPermission()] function.
    widget.isExternalRes
        ? allowedRecipientTypes = granterRecipientTypes
        : allowedRecipientTypes = ownerRecipientTypes;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          RadioGroup<RecipientType>(
            groupValue: _selectedRecipientType,
            onChanged: (RecipientType? value) {
              switch (value) {
                case RecipientType.public:
                  widget.setPublicFunction();
                case RecipientType.authUser:
                  widget.setAuthUsersFunction();
                case RecipientType.individual:
                  widget.setIndividualFunction();
                case RecipientType.group:
                  widget.setGroupFunction();
                case RecipientType.none:
                  return;
                case null:
                  return;
              }
              setState(() {
                _selectedRecipientType = value;
              });
            },
            child: Column(
              children: [
                for (final rtype in ownerRecipientTypes)
                  if (recipientTypeList.contains(rtype))
                    MarkdownTooltip(
                      message: recipientToolTips[rtype]!,
                      child: ListTile(
                        title: Text(rtype.description),
                        leading: Radio<RecipientType>(value: rtype),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
