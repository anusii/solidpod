/// Settings page with several tabs.
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
/// Authors: Zheyuan Xu, Kevin Wang
// ignore_for_file: prefer_final_locals

library;

import 'package:flutter/material.dart';
import 'package:solidpod/src/solid/constants.dart';

const double sideMenuScreenSize = 250.0;
const warningRed = Colors.red;
const confirmGreen = Colors.green;
const anuLightGold = Color(0xFFDBBA78);

// ignore: must_be_immutable
class SettingScreen extends StatefulWidget {
  final String? email;

  final Map authData;
  final String webId;
  bool? validEncKey;
  SettingScreen({
    Key? key,
    this.email,
    required this.authData,
    required this.webId,
    this.validEncKey,
  }) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _keyController = TextEditingController();
  bool _obscureText = true;
  //FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    Map authData = widget.authData;
    String webId = widget.webId;
    // String logoutUrl = authData['logoutUrl'];

    return Scaffold(
      key: _scaffoldKey,
      // drawer: ConstrainedBox(
      //   constraints: BoxConstraints(maxWidth: sideMenuScreenSize),
      //   child: SideMenu(
      //     authData: authData,
      //     webId: webId,
      //     pageName: 'setting',
      //   ),
      // ),
      // endDrawer: ConstrainedBox(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Responsive.isDesktop(context)
              //     ? Container()
              //     : Header(
              //         authData: authData,
              //         mainDrawer: _scaffoldKey,
              //         logoutUrl: logoutUrl,
              //         backButton: false,
              //         webId: webId,
              //       ),
              // Responsive.isDesktop(context) ? Container() : Divider(thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20.0),
                      Text(
                        "Encryption Key",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      widget.validEncKey == null
                          ? Text(
                              'Please enter encryption key to encrypt your data.',
                              style: TextStyle(
                                color: warningRed,
                              ),
                            )
                          : widget.validEncKey!
                              ? Text(
                                  'Your encryption key is valid.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: confirmGreen,
                                  ),
                                )
                              : Text(
                                  'Your encryption key is invalid.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: warningRed,
                                  ),
                                ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                obscureText: _obscureText,
                                controller: _keyController,
                                decoration: InputDecoration(
                                  hintText: widget.validEncKey == null
                                      ? 'Please enter encryption key'
                                      : 'Update encryption key',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      // Based on passwordVisible state choose the icon
                                      _obscureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                    onPressed: () {
                                      _toggle();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: anuLightGold,
                              ),
                              onPressed: () async {
                                if (_keyController.text.isEmpty) {
                                  return;
                                } else {
                                  bool isKeyExist =
                                      await secureStorage.containsKey(
                                    key: widget.webId,
                                  );

                                  // Since write() method does not automatically overwrite an existing value.
                                  // To overwrite an existing value, call delete() first.

                                  if (isKeyExist) {
                                    await secureStorage.delete(
                                      key: widget.webId,
                                    );
                                  }

                                  await secureStorage.write(
                                    key: widget.webId,
                                    value: _keyController.text,
                                  );

                                  String secureKey =
                                      await secureStorage.read(key: webId) ??
                                          '';

                                  // verifyEncKey(secureKey, authData)
                                  //     .then((value) {
                                  //   setState(() {
                                  //     widget.validEncKey = value;
                                  //   });
                                  // }

                                  // );
                                }
                              },
                              child: Text('Submit'),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                obscureText: _obscureText,
                                controller: _keyController,
                                decoration: InputDecoration(
                                  hintText: widget.validEncKey == null
                                      ? 'New encryption key'
                                      : 'Update encryption key',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      // Based on passwordVisible state choose the icon
                                      _obscureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                    onPressed: () {
                                      _toggle();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: ElevatedButton(
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: anuLightGold,
                          //     ),
                          //     onPressed: () async {
                          //       if (_keyController.text.isEmpty) {
                          //         return;
                          //       } else {
                          //         bool isKeyExist =
                          //             await secureStorage.containsKey(
                          //           key: widget.webId,
                          //         );

                          //         // Since write() method does not automatically overwrite an existing value.
                          //         // To overwrite an existing value, call delete() first.

                          //         if (isKeyExist) {
                          //           await secureStorage.delete(
                          //             key: widget.webId,
                          //           );
                          //         }

                          //         await secureStorage.write(
                          //           key: widget.webId,
                          //           value: _keyController.text,
                          //         );

                          //         String secureKey =
                          //             await secureStorage.read(key: webId) ??
                          //                 '';

                          //         // verifyEncKey(secureKey, authData)
                          //         //     .then((value) {
                          //         //   setState(() {
                          //         //     widget.validEncKey = value;
                          //         //   });
                          //         // }

                          //         // );
                          //       }
                          //     },
                          //     child: Text('Submit'),
                          //   ),
                          // ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                obscureText: _obscureText,
                                controller: _keyController,
                                decoration: InputDecoration(
                                  hintText: widget.validEncKey == null
                                      ? 'Repeat new  encryption key'
                                      : 'Update encryption key',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      // Based on passwordVisible state choose the icon
                                      _obscureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                    onPressed: () {
                                      _toggle();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: ElevatedButton(
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: anuLightGold,
                          //     ),
                          //     onPressed: () async {
                          //       if (_keyController.text.isEmpty) {
                          //         return;
                          //       } else {
                          //         bool isKeyExist =
                          //             await secureStorage.containsKey(
                          //           key: widget.webId,
                          //         );

                          //         // Since write() method does not automatically overwrite an existing value.
                          //         // To overwrite an existing value, call delete() first.

                          //         if (isKeyExist) {
                          //           await secureStorage.delete(
                          //             key: widget.webId,
                          //           );
                          //         }

                          //         await secureStorage.write(
                          //           key: widget.webId,
                          //           value: _keyController.text,
                          //         );

                          //         String secureKey =
                          //             await secureStorage.read(key: webId) ??
                          //                 '';

                          //         // verifyEncKey(secureKey, authData)
                          //         //     .then((value) {
                          //         //   setState(() {
                          //         //     widget.validEncKey = value;
                          //         //   });
                          //         // }

                          //         // );
                          //       }
                          //     },
                          //     child: Text('Submit'),
                          //   ),
                          // ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: anuLightGold,
                            ),
                            onPressed: () {
                              // Hive.box(MEDICAL_DATA_HIVE_BOX)
                              //     .clear()
                              //     .then((value) async {
                              //   String secureKey = await secureStorage.read(
                              //         key: webId,
                              //       ) ??
                              //       '';

                              //   // bool keyValid = await verifyEncKey(
                              //   //   secureKey,
                              //   //   authData,
                              //   // );
                              //   // Navigator.pushReplacement(
                              //   //   context,
                              //   //   MaterialPageRoute(
                              //   //     builder: (context) => MainScreen(
                              //   //       authData: authData,
                              //   //       webId: webId,
                              //   //       page: 'setting',
                              //   //       selectSurveyIndex: 0,
                              //   //       validEncKey: keyValid,
                              //   //     ),
                              //   //   ),
                              //   // );
                              // }
                              // );
                            },
                            child: Text(
                              'Clear',
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
