/// A dialog to input Group of WebIDs.
///
// Time-stamp: <Tuesday 2025-07-22 13:59:21 +1000 Graham Williams>
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
/// Authors: Anushka Vidanage, Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/ui.dart';
import 'package:solidpod/src/solid/utils/alert.dart';
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
    suggestionList =
        webIdList.where((e) => e.contains(value.toLowerCase())).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Dialog width: ${MediaQuery.of(context).size.width}');
    debugPrint('Dialog heigth: ${MediaQuery.of(context).size.height}');

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 50),
      title: const Text('WebID of the individual recipient'),
      content: SizedBox(
        height: MediaQuery.of(context).size.width * 0.6,
        width: MediaQuery.of(context).size.width * 0.8, // or double.maxFinite
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
            const SizedBox(height: 10),
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
            debugPrint('Submitted: receiverWebId for onSubmit checks');

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
    debugPrint('Suggestions width: ${MediaQuery.of(context).size.width}');
    debugPrint('Suggestions height: ${MediaQuery.of(context).size.height}');

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6, // or double.maxFinite
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        itemCount: idList.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
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

/// A dialog for adding an individual webId. Function call requires the
/// following inputs
/// [onSubmitFunction] is the function to be called on submit
///
Future<dynamic> indWebIdInputDialog(
  BuildContext context,
  Function onSubmitFunction,
  Map<String, dynamic> dataFilesMap,
) {
  return showDialog(
    context: context,
    builder: (context) {
      return IndWebIdInputScreen(
        onSubmitFunction: onSubmitFunction,
        dataFilesMap: dataFilesMap,
      );
    },
  );
}
