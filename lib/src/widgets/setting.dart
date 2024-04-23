/// Encrypt key enter page.
///
/// Copyright (C) 2023 Software Innovation Institute, Australian National University
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Zheyuan Xu, Graham Williams
library;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/src/solid/login.dart';
import 'package:solidpod/src/solid/responsive.dart';
import 'package:solidpod/src/solid/secure_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The height of the screen.
double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

/// Size used for version text in enc key input page.
const versionTextSize = 13.5;

/// The APP_VERSION of the app.
// ignore: non_constant_identifier_names
String APP_VERSION = '';

/// Border radius for buttons.
const double buttonBorderRadius = 5;

/// Color for Anu Brick Red.
const anuBrickRed = Color(0xFFD89E7A);

/// The standard size of buttons in bar charts for mobile.
const sizeMobileStandard = 20.0;

/// The standard size of the desktop.
const sizeDesktopStandard = 30.0;

/// The default padding for the page.
const kDefaultPadding = 20.0;

/// Color for Anu Light Gold.
const anuLightGold = Color(0xFFDBBA78);

/// Widget for entering encryption key.
class Settings extends ConsumerStatefulWidget {
  /// Constructs an `EncryptionKeyInput` widget.
  const Settings({
    required this.storage,
    required this.webId,
    required this.authData,
    required this.secureKeyObject,
    super.key,
  });

  /// The secure storage for storing the encryption key.
  final FlutterSecureStorage storage;

  /// The web ID associated with the encryption key.
  final String webId;

  /// The authentication data for the encryption key.
  // ignore: strict_raw_type
  final Map authData;

  /// The Secure key object
  final SecureKey secureKeyObject;

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  // The controller for the current encryption key text field.
  final TextEditingController currentKeyController = TextEditingController();

  /// The controller for the new encryption key text field.
  final TextEditingController newKeyController = TextEditingController();

  /// The controller for the repeat new encryption key text field.
  final TextEditingController repeatKeyController = TextEditingController();

  bool _obscureTextCurrent = true;
  bool _obscureTextNew = true;
  bool _obscureTextRepeat = true;

  void _toggleCurrent() {
    setState(() {
      _obscureTextCurrent = !_obscureTextCurrent;
    });
  }

  void _toggleNew() {
    setState(() {
      _obscureTextNew = !_obscureTextNew;
    });
  }

  void _toggleRepeat() {
    setState(() {
      _obscureTextRepeat = !_obscureTextRepeat;
    });
  }

  @override
  Widget build(BuildContext context) {
    // const titleStyle = TextStyle(
    //   fontSize: 25,
    //   fontWeight: FontWeight.w700,
    //   color: anuBrickRed,
    // );

    // final subtitleStyle = TextStyle(
    //   fontSize: Responsive.isSmallMobile(context)
    //       ? sizeMobileStandard
    //       : sizeDesktopStandard,
    //   fontWeight: FontWeight.w600,
    //   color: anuBrickRed, // Same here for consistent theming
    // );
    return Column(
      children: [
        // Adding a Row for the back button and spacing.

        Row(
          children: [
            BackButton(
              onPressed: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) =>
                //   SolidLogin()),
                // );
              },
            ),
          ],
        ),
        SizedBox(height: screenHeight(context) * 0.05),
        const Center(
          child: Text('App Settings'
              // , style: titleStyle
              ),
        ),
        SizedBox(height: screenHeight(context) * 0.05),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(children: [
            Text('Change Encryption Key'
                // , style: subtitleStyle
                ),
            // Your Row with the TextField for the current encryption key
            // Your Row with the TextField for the new encryption key
            // Your Row with the TextField for the repeat new encryption key
            // Your ElevatedButton for changing the key
          ]),
        ),
        const Spacer(),

        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      // Add this Material widget
                      child: TextField(
                        obscureText: _obscureTextCurrent,
                        controller: currentKeyController,
                        decoration: InputDecoration(
                          hintText: 'Your current encryption key',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureTextCurrent
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: _toggleCurrent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      // Add this Material widget
                      child: TextField(
                        obscureText: _obscureTextNew,
                        controller: newKeyController,
                        decoration: InputDecoration(
                          hintText: 'New encryption key',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureTextNew
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: _toggleNew,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      // Add this Material widget
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Repeat new encryption key',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureTextRepeat
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: _toggleRepeat,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: anuLightGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                  ),
                ),
                onPressed: () async {
                  //Navigator.of(context).pop();
                  if (currentKeyController.text.isEmpty ||
                      newKeyController.text.isEmpty ||
                      repeatKeyController.text.isEmpty) {
                    await _showErrDialog(context, 'ERROR!',
                        'Some fields are missing. Please enter all three values!');
                  } else {
                    // final currentKey = currentKeyController.text;
                    final newKey = newKeyController.text;
                    final repeatKey = repeatKeyController.text;

                    if (newKey != repeatKey) {
                      await _showErrDialog(
                          context, 'ERROR!', 'Your new keys do not match!');
                    } else {
                      // TODO kevin , fix this for backend issue

                      // // Verify if the current key is correct
                      // if (await verifyEncKey(currentKey, widget.authData)) {
                      //   showDialog(
                      //     context: context,
                      //     builder: (BuildContext ctx) {
                      //       return AlertDialog(
                      //         title: const Text(
                      //           'Please Confirm',
                      //         ),
                      //         content: RichText(
                      //           text: TextSpan(
                      //             style: TextStyle(
                      //               color: Colors.black,
                      //               fontSize: 14.0,
                      //             ),
                      //             children: <TextSpan>[
                      //               TextSpan(
                      //                   text:
                      //                       'Are you sure you want to change the encryption key?'),
                      //               TextSpan(
                      //                   style: TextStyle(color: Colors.red),
                      //                   text:
                      //                       '\n\nMake sure to remember the new key as we do not save that in your POD.'),
                      //             ],
                      //           ),
                      //         ),
                      //         actions: [
                      //           // The "Yes" button
                      //           TextButton(
                      //             onPressed: () async {
                      //               // Animation for updating the files
                      //               Navigator.of(context).pop();
                      //               showAnimationDialog(
                      //                 context,
                      //                 17,
                      //                 'Changing the encryption key!',
                      //                 false,
                      //               );

                      //               // Update the main encryption key file values
                      //               final keyFileUpdateRes =
                      //                   await updateEncKeyFile(
                      //                       currentKey,
                      //                       newKey,
                      //                       widget.authData,
                      //                       widget.webId);

                      //               // Update the individual key file values
                      //               final indKeyFileUpdateRes =
                      //                   await updateIndKeyFile(
                      //                       currentKey,
                      //                       newKey,
                      //                       widget.authData,
                      //                       widget.webId);

                      //               // If the key is verified then first write the new key to local storage
                      //               bool isKeyExist =
                      //                   await widget.storage.containsKey(
                      //                 key: widget.webId,
                      //               );

                      //               // Since write() method does not automatically overwrite an existing value.
                      //               // To overwrite an existing value, call delete() first.

                      //               if (isKeyExist) {
                      //                 await widget.storage.delete(
                      //                   key: widget.webId,
                      //                 );
                      //               }

                      //               await widget.storage.write(
                      //                 key: widget.webId,
                      //                 value: newKey,
                      //               );

                      //               await SECURE_STORAGE.write(
                      //                 key: widget.webId,
                      //                 value: newKey,
                      //               );

                      //               if (keyFileUpdateRes == 'ok' &&
                      //                   indKeyFileUpdateRes == 'ok') {
                      //                 Navigator.of(context).pop();
                      //                 await _showErrDialog(context, 'SUCCESS!',
                      //                     'Your key has been successfully updated!');
                      //                 Navigator.pushReplacement(
                      //                   context,
                      //                   MaterialPageRoute(
                      //                       builder: (context) => MainScreen(
                      //                             authData: widget.authData,
                      //                             webId: widget.webId,
                      //                             page: 'setting',
                      //                             selectSurveyIndex: 0,
                      //                             validEncKey: true,
                      //                             secureKeyObject:
                      //                                 widget.secureKeyObject,
                      //                           )),
                      //                 );
                      //               } else {
                      //                 Navigator.of(context).pop();
                      //                 await _showErrDialog(context, 'ERROR!',
                      //                     'Failed to update encryption key! Try again in a while!');
                      //               }
                      //             },
                      //             child: const Text('Confirm'),
                      //           ),
                      //           TextButton(
                      //             onPressed: () async {
                      //               // Close the dialog

                      //               Navigator.of(
                      //                 context,
                      //               ).pop();
                      //             },
                      //             child: const Text('Cancel'),
                      //           ),
                      //         ],
                      //       );
                      //     },
                      //   );
                      // } else {
                      //   await _showErrDialog(context, 'ERROR!',
                      //       'Current key verification failed. Try again!');
                      // }
                    }
                  }
                },
                child: const Text(
                  'Change key',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ]),
        ),

        // SizedBox(
        //   height: 10,
        // ),
        // Text("Your WebID",
        //     style: TextStyle(
        //         fontSize: sizeMobileStandard, fontWeight: FontWeight.w700)),
        // SizedBox(
        //   height: 10,
        // ),
        // Row(
        //   children: [
        //     Expanded(
        //       child: Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: SelectableText(widget.webId),
        //       ),
        //     ),
        //   ],
        // ),

        const Spacer(),

        // Only show version text in mobile version.

        !Responsive.isDesktop(context)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SelectableText(
                    APP_VERSION,
                    style: const TextStyle(
                      fontSize: versionTextSize,
                      color: Colors.black,
                    ),
                  ),
                ],
              )
            : Container(),

        // Avoid the APP_VERSION disappear at the bottom.

        SizedBox(
          height: screenHeight(context) * 0.12,
        )
      ],
    );
  }

  Future<void> _showErrDialog(
      BuildContext context, String msgTitle, String errMsg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return AlertDialog(
          title: Text(msgTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(errMsg),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
