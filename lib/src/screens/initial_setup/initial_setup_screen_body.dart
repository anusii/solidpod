/// Initial loaded screen set up page.
///
// Time-stamp: <Tuesday 2024-04-02 21:17:46 +1100 Graham Williams>
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

// ignore_for_file: use_build_context_synchronously, public_member_api_docs

library;

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:solid_auth/solid_auth.dart';

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
    required this.child,
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

  /// The child widget after logging in.

  final Widget child;

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

    final combinedLinks = resFoldersLink + resFilesLink;

    final String commonBaseUrl = extractCommonBaseUrl(combinedLinks);

    String baseUrl = commonBaseUrl + '/';

    final extractedParts = combinedLinks
        .map((url) {
          // Check if the URL starts with the base URL and has additional parts.

          if (url.startsWith(baseUrl) && url.length > baseUrl.length) {
            // Extract everything after the base URL without splitting into segments.

            return url.substring(baseUrl.length);
          }

          // Return null for URLs that don't match the criteria.

          return null;
        })
        // Remove nulls.

        .where((item) => item != null)

        // Remove duplicates.

        .toSet()

        // Convert to list.

        .toList();

    final resFileNamesLink = (widget.resNeedToCreate['fileNames'] as List)
        .map((item) => item.toString())
        .toList();

    return Column(
      children: [
        // Adding a Row for the back button and spacing.

        Row(
          children: [
            BackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

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
                                children: <Widget>[
                                  encKeyInputForm(
                                      formKey, showPassword, onChangedVal),
                                  Center(
                                    child: resCreateFormSubmission(
                                      formKey,
                                      context,
                                      resFileNamesLink,
                                      resFoldersLink,
                                      resFilesLink,
                                      widget.authData,
                                      widget.webId,
                                      widget.appName,
                                      widget.child,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                  Center(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ResourceCreationTextWidget(
                                            resLinks: combinedLinks,
                                          ),
                                          const Divider(
                                            color: Colors.grey,
                                          ),
                                          for (final String? resLink
                                              in extractedParts) ...[
                                            ListTile(
                                              title: Text(resLink!),
                                              leading: const Icon(Icons.folder),
                                            ),
                                          ],
                                          const SizedBox(
                                            height: 20,
                                          ),
                                        ]),
                                  )
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
                    color: Colors.grey,
                    size: 24.0,
                  ),
                  label: const Text(
                    'Logout from Pod',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, //black,
                    ),
                  ),
                  onPressed: () async {
                    await logout(widget.authData['logoutUrl']);
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SolidLogin(
                          // Images generated using Bing Image Creator from Designer, powered by
                          // DALL-E3.

                          image: AssetImage('assets/images/keypod_image.jpg'),
                          logo: AssetImage('assets/images/keypod_logo.png'),
                          title: 'MANAGE YOUR SOLID POD',
                          link: 'https://github.com/anusii/keypod',
                          child: Scaffold(body: Text('Key Pod Placeholder')),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors
                        .white, //lightBlue, // Set the background color to light blue
                  ),
                  // remove the popup warning.
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String extractCommonBaseUrl(List<String> urls) {
  if (urls.isEmpty) return '';

  final sampleUrl = urls.first;

  return sampleUrl;
}

class ResourceCreationTextWidget extends StatelessWidget {
  final List<String> resLinks;

  ResourceCreationTextWidget({required this.resLinks});

  String getResourceCreationMessage() {
    if (resLinks.isEmpty) return 'No resources specified';

    final baseUrl = resLinks.first.split('/').take(5).join('/');
    return 'Resources that will be created within \n $baseUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        getResourceCreationMessage(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 25,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
