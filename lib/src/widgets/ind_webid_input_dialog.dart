/// A dialog to input Group of WebIDs.
///
// Time-stamp: <Tuesday 2025-07-22 13:59:21 +1000 Graham Williams>
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
/// Authors: Anushka Vidanage, Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidui/solidui.dart'
    show WebIdLayout, SecurityColors, DropdownColors;
import 'package:solidpod/src/solid/utils/alert.dart';
import 'package:solidpod/src/solid/utils/is_phone.dart';
import 'package:solidpod/src/widgets/ind_webid_input_screen.dart';

/// A [StatefulWidget] dialog for adding an individual webId.
/// Function call requires the following inputs.
/// [onSubmitFunction] is the function to be called on submit.
/// [uniqRecipWebIdList] is a list of the webIds of unique recipients of the
/// owner's data.
///
class IndWebIdTextInput extends StatefulWidget {
  /// Initialise widget variables.

  const IndWebIdTextInput({
    required this.onSubmitFunction,
    this.uniqRecipWebIdList,
    super.key,
  });

  /// Function run on Submit button press.
  final Function onSubmitFunction;

  /// List of unique recipient webIds
  final List<String>? uniqRecipWebIdList;

  @override
  State<IndWebIdTextInput> createState() => _IndWebIdTextInputState();
}

class _IndWebIdTextInputState extends State<IndWebIdTextInput> {
  /// Text controller for WebId field
  final formControllerWebId = TextEditingController();

  /// Capture whether user has started to enter text
  bool _textEntered = false;

  /// WebId list
  List<String> webIdList = [];

  /// Initialise the matching suggestions list
  List<String> suggestionList = [];
  String hint = '';

  // dispose text controller when the widget is unmounted
  @override
  void dispose() {
    formControllerWebId.dispose();
    super.dispose();
  }

  @override
  void initState() {
    webIdList = widget.uniqRecipWebIdList ?? [];
    super.initState();
  }

  /// Generate advice to help user enter valid WebID
  String? get _helpText {
    final text = formControllerWebId.value.text.trim();
    final uri = Uri.parse(text);

    // Check for https scheme and ://
    if (!uri.isScheme('HTTPS') || !uri.toString().contains('://')) {
      return 'Must start with https://';
    }
    // Check WebID contains host followed by '/'

    if (!uri.path.contains('/')) {
      return 'Must have form https://[POD server host]/[their username]/profile/card#me';
    }
    // Check for WebID path with profile suffix
    if (!uri.path.toLowerCase().contains('/profile/card')) {
      return 'Must end with \'/[their username]/profile/card#me\'';
    }
    // Check ends in #me
    if (!(uri.fragment.toLowerCase() == 'me')) {
      return 'Must end with URL fragment #me after /profile/card';
    }
    // Check fully qualified web address
    // 20250721 jm Retaining this check, may not be needed
    if (!Uri.parse(text.replaceAll('#me', '')).isAbsolute) {
      return 'Must be a fully qualified web address';
    }
    // return null if the text is valid
    return null;
  }

  /// Generate suggestions for users based on input matches to
  /// current complete recipient list of user
  void filterSuggestions(String value) {
    suggestionList.clear();

    if (value.isEmpty) {
      setState(() {});
      return;
    }
    suggestionList = webIdList
        .where((e) => e.toLowerCase().contains(value.toLowerCase()))
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: WebIdLayout.contentPadding,
      title: const Text('WebID of the individual recipient'),
      content: SizedBox(
        // Use full width on phones, else use a preset narrower width
        width: (!isPhone()) ? WebIdLayout.dialogWidth : double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provide info on what a WebId is
            const Text(
              whatIsWebID,
            ),
            // Show an example WebId that remains visible once user is typing
            const Text('Eg: $demoWebID'),
            WebIdLayout.paraVertGap,
            const Text('Type their WebId or select a recently used WebId.'),
            const SizedBox(height: 20),
            // Web ID text field
            TextFormField(
              controller: formControllerWebId,
              decoration: InputDecoration(
                labelText: 'Individual\'s webID',
                // Once user has started entering text, use formfield
                // error message to advise user how to specify
                // valid webId
                errorText: _textEntered ? _helpText : null,
              ),
              onFieldSubmitted: (value) {},
              onChanged: (value) => setState(() {
                // User has started entering text
                _textEntered = true;
                // Filter suggestions
                filterSuggestions(value);
              }),
            ),
            // const SizedBox(height: 10),
            WebIdLayout.paraVertGap,
            if (webIdList.isNotEmpty) ...[
              if (suggestionList.isNotEmpty ||
                  formControllerWebId.text.isNotEmpty) ...[
                // 20250729 jm: Wrap ListView() in fixed SizeBox() to avoid render problems in AlertDialog()
                boxedSuggestionList(context, suggestionList),
              ] else ...[
                boxedSuggestionList(context, webIdList),
              ],
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            final receiverWebId = formControllerWebId.text.trim();

            // User has entered WebId text that satisfies error checks
            if (receiverWebId.isNotEmpty && _helpText == null) {
              // Check WebId exists

              if (await checkResourceStatus(receiverWebId) ==
                  ResourceStatus.exist) {
                // Save provided WebId
                widget.onSubmitFunction(receiverWebId);
                // Close enter WebId dialog
                if (!context.mounted) return;
                Navigator.of(context).pop();
              } else {
                if (!context.mounted) return;
                // Request WebId that exists
                // await alert(context, 'Please enter a valid WebID');
                await alert(
                  context,
                  'This WebID does not exist. Please enter the correct WebID',
                );
              }
            }

            // // 20250720 jm Old webID checks:
            // // Check the web ID field is not empty and it is a true link
            // if (receiverWebId.isNotEmpty &&
            //     Uri.parse(receiverWebId.replaceAll('#me', '')).isAbsolute &&
            //     await checkResourceStatus(receiverWebId) ==
            //         ResourceStatus.exist) {
            //   widget.onSubmitFunction(receiverWebId);
            //   if (!context.mounted) return;
            //   Navigator.of(context).pop();
            // } else {
            //   if (!context.mounted) return;
            //   await alert(context, 'Please enter a valid WebID');
            // }
          },
          child: const Text('Ok'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  SizedBox boxedSuggestionList(BuildContext context, List<String> idList) {
    return SizedBox(
      width: double.maxFinite,
      height: WebIdLayout.dropdownHeight,
      child: ListView.builder(
        padding: WebIdLayout.listPadding,
        itemCount: idList.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: WebIdLayout.dropdownElevation,
            child: ListTile(
              title: Text(idList[index]),
              focusColor: SecurityColors.primary,
              hoverColor: DropdownColors.accent,
              splashColor: DropdownColors.primary,
              onTap: () => setState(() {
                // User has started entering text
                _textEntered = true;
                formControllerWebId.text = idList[index];
              }),
            ),
          );
        },
      ),
      // ),
    );
  }
}

/// A dialog for adding an individual webId.
///
/// Parameters:
/// - [context] - The build context.
/// - [onSubmitFunction] is the function to be called on submit
///
Future<dynamic> indWebIdInputDialog(
  BuildContext context,
  Function onSubmitFunction,
  Map<String, dynamic> dataFilesMap,
) {
  return showDialog(
    context: context,
    builder: (context) => IndWebIdInputScreen(
      onSubmitFunction: onSubmitFunction,
      dataFilesMap: dataFilesMap,
    ),
  );
}
