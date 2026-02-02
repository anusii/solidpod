/// A dialog to input individual WebID.
///
// Time-stamp: <Sunday 2024-07-11 12:23:00 +1000 Anushka Vidange>
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
///
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/utils/alert.dart';

/// A [StatefulWidget] dialog for entering group of webIds.
///
/// Parameters:
/// - [onSubmitFunction] - function to be called on submit.

class GroupWebIdTextInput extends StatefulWidget {
  /// Function run on Submit button press.
  final Function onSubmitFunction;

  const GroupWebIdTextInput({
    super.key,
    required this.onSubmitFunction,
  });

  @override
  State<GroupWebIdTextInput> createState() => _GroupWebIdTextInputState();
}

class _GroupWebIdTextInputState extends State<GroupWebIdTextInput> {
  /// Text controller for webId list field
  final formControllerGroupWebIds = TextEditingController();

  /// Text controller for group name for webId list

  final formControllerGroupName = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // dispose text controller when the widget is unmounted
  @override
  void dispose() {
    formControllerGroupWebIds.dispose();
    formControllerGroupName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallGapV,
        // Explain webId with example
        MarkdownTooltip(
          message: '$whatIsWebID Eg: $demoWebID',
          child: makeSubHeading(
            'Enter recipient group WebIds',
          ),
        ),
        // Add padding to webid textformfield and suggestion drop down
        Container(
          padding: GrantPermFormLayout.inputPadding,
          child: Column(
            children: [
              // Group name. Should be a single string
              TextFormField(
                controller: formControllerGroupName,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  hintText:
                      'Multiple words will be combined using the symbol -',
                ),
              ),
              smallGapV,
              // List of Web IDs divided by semicolon
              TextFormField(
                controller: formControllerGroupWebIds,
                decoration: const InputDecoration(
                  labelText: 'List of WebIDs',
                  hintText: 'Divide multiple WebIDs using the semicolon (;)',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      // Check if all the input entries are correct
                      final groupName = formControllerGroupName.text.trim();
                      final groupWebIds = formControllerGroupWebIds.text.trim();

                      // Check if both fields are not empty
                      if (groupName.isNotEmpty && groupWebIds.isNotEmpty) {
                        final webIdList = groupWebIds.split(';');

                        // Check if all the webIds are true links
                        var trueWebIdsFlag = true;
                        for (final webId in webIdList) {
                          if (!Uri.parse(webId.replaceAll('#me', ''))
                                  .isAbsolute ||
                              !(await checkResourceStatus(webId) ==
                                  ResourceStatus.exist)) {
                            trueWebIdsFlag = false;
                          }
                        }

                        if (trueWebIdsFlag) {
                          // Save selected webid group
                          widget.onSubmitFunction(groupName, webIdList);
                        } else {
                          if (!context.mounted) return;
                          await alert(
                            context,
                            'At least one of the Web IDs you entered is not valid',
                          );
                        }
                      } else {
                        if (!context.mounted) return;
                        await alert(
                          context,
                          'Please enter a group name and a list of Web IDs',
                        );
                      }
                    },
                    child: const Text('Select Group of WebIds'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
