/// Initial loaded screen set up page.
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
/// Authors: Zheyuan Xu, Anushka Vidanage

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:solid_auth/solid_auth.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_constants.dart';
import 'package:solidpod/src/screens/initial_setup/widgets/res_create_form_submission.dart';
import 'package:solidpod/src/solid/login.dart';
import 'package:solidpod/src/screens/initial_setup/widgets/enc_key_input_form.dart';
import 'package:solidpod/src/screens/initial_setup/widgets/initial_setup_welcome.dart';

/// A [StatefulWidget] that represents the initial setup screen for the desktop version of an application.
///
/// This widget is responsible for rendering the initial setup UI, which includes forms for user input and displaying
/// resources that will be created as part of the setup process.

class InitialSetupScreenBody extends StatefulWidget {
  /// Initialising the [StatefulWidget]

  const InitialSetupScreenBody({
    required this.resNeedToCreate,
    required this.authData,
    required this.webId,
    required this.appName,
    super.key,
  });

  /// Resources that need to be created inside user's POD.

  final Map<dynamic, dynamic> resNeedToCreate;

  /// Authentication data coming from the Solid server.

  final Map<dynamic, dynamic> authData;

  /// A URI that is uniquely assigned to the POD.

  final String webId;

  /// Name of the app.

  final String appName;

  @override
  State<InitialSetupScreenBody> createState() {
    return _InitialSetupScreenBodyState();
  }
}

class _InitialSetupScreenBodyState extends State<InitialSetupScreenBody> {
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();

    void onChangedVal(dynamic val) => debugPrint(val.toString());
    const showPassword = true;

    final resFoldersLink = (widget.resNeedToCreate['folders'] as List)
        .map((item) => item.toString())
        .toList();

    final resFilesLink = (widget.resNeedToCreate['files'] as List)
        .map((item) => item.toString())
        .toList();

    final resFileNamesLink = (widget.resNeedToCreate['fileNames'] as List)
        .map((item) => item.toString())
        .toList();

    return Column(
      children: [
        Expanded(
            child: SizedBox(
                height: 700,
                child: ListView(primary: false, children: [
                  Center(
                    child: initialSetupWelcome(context),
                  ),
                  Center(
                      child: SizedBox(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(80, 10, 80, 0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resources that will be created!',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Divider(
                                      color: Colors.grey,
                                    ),
                                    for (final String resLink
                                        in resFoldersLink) ...[
                                      ListTile(
                                        title: Text(resLink),
                                        leading: const Icon(Icons.folder),
                                      ),
                                    ],
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    for (final String resLink
                                        in resFilesLink) ...[
                                      ListTile(
                                        title: Text(resLink),
                                        leading: const Icon(Icons.file_copy),
                                      ),
                                    ],
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ])))),
                  Center(
                      child: SizedBox(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(80, 10, 80, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  encKeyInputForm(
                                      formKey, showPassword, onChangedVal),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: resCreateFormSubmission(
                                          formKey,
                                          context,
                                          resFileNamesLink,
                                          resFoldersLink,
                                          resFilesLink,
                                          widget.authData,
                                          widget.webId,
                                          widget.appName,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            formKey.currentState?.reset();
                                          },
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: darkBlue,
                                              backgroundColor:
                                                  darkBlue, // foreground
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 50),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          child: const Text(
                                            'RESET',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                ],
                              )))),
                ]))),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.black,
                    size: 24.0,
                  ),
                  label: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () async {
                    await logout(widget.authData['logoutUrl']);
                    // ignore: use_build_context_synchronously
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SolidLogin(
                          // Images generated using Bing Image Creator from Designer, powered by
                          // DALL-E3.

                          image: AssetImage('assets/images/keypod_image.jpg'),
                          logo: AssetImage('assets/images/keypod_logo.png'),
                          title: 'MANAGE YOUR SOLID KEY POD',
                          link: 'https://github.com/anusii/keypod',
                          child: Scaffold(body: Text('Key Pod Placeholder')),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
