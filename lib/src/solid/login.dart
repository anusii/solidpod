/// A widget to obtain a Solid token to access the user's POD.
///
// Time-stamp: <Monday 2024-04-22 14:36:36 +1000 Graham Williams>
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
/// Authors: Graham Williams

// ignore_for_file: public_member_api_docs

library;

import 'package:flutter/material.dart';
import 'package:solidpod/src/solid/change_key.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:solidpod/src/solid/authenticate.dart';
import 'package:solidpod/src/widgets/show_animation_dialog.dart';
import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/utils.dart'
    show generateDefaultFolders, generateDefaultFiles;

// Screen size support functions to identify narrow and very narrow screens. The
// width dictates whether the Login panel is laid out on the right with the app
// image on the left, or is on top of the app image.

const int _narrowScreenLimit = 1175;
const int _veryNarrowScreenLimit = 750;
const Color defaultButtonBackground = Colors.white;
const Color defaultButtonForeground = Colors.black;
const String defaultLoginButtonText = 'LOGIN';
const String defaultRegisterButtonText = 'REGISTER';
const String defaultInfoButtonText = 'INFO';
const String defaultContinueButtonText = 'CONTINUE';
const String defaultChangeKeyButtonText = 'CHANGE KEY';
const String defaultLoginTooltip = 'Login to your Solid Pod';
const String defaultRegisterTooltip = 'Get a Solid Pod';
const String defaultInfoTooltip = 'Visit the Solid Project website';
const String defaultContinueTooltip =
    'Continue to the app without logging in to your Solid Pod';

double _screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

bool _isNarrowScreen(BuildContext context) =>
    _screenWidth(context) < _narrowScreenLimit;

bool _isVeryNarrowScreen(BuildContext context) =>
    _screenWidth(context) < _veryNarrowScreenLimit;

// Check whether the dialog was dismissed by the user.

bool _isDialogCanceled = false;

// TODO 20240324 gjw How to get the current elevated button background color
// from the theme that an app may have overriden from the default, so that we
// can refer to it here as the default if the user has not specified it so that
// the correct default BG colour is displayed, in line wit hthe app's use of a
// theme to override the solidpod defaults.

// Color? _backgroundColor = ElevatedButtonTheme.of(context).style.backgroundColor.resolve({MaterialState.pressed});

/// A widget to login to a Solid server for a user's token to access their POD.
///
/// The login screen will be the initial screen of the app when access to the
/// user's POD is required when the app requires access to the user's POD for
/// any of its functionality.

class SolidLogin extends StatefulWidget {
  /// Parameters for authenticating to the Solid server.

  const SolidLogin({
    // Include the literals here so that they are exposed through the docs.

    required this.child,
    this.required = true,
    this.image =
        const AssetImage('assets/images/default_image.jpg', package: 'solid'),
    this.logo =
        const AssetImage('assets/images/default_logo.png', package: 'solid'),
    this.title = 'LOG IN TO YOUR POD',
    this.loginText = 'LOGIN',
    this.continueText = 'CONTINUE',
    this.continueBG = Colors.white,
    this.registerText = 'GET A POD',
    this.infoText = 'INFO',
    this.webID = 'https://pods.solidcommunity.au',
    this.link = 'https://solidproject.org',
    this.continueButtonStyle = const ContinueButtonStyle(),
    this.infoButtonStyle = const InfoButtonStyle(),
    this.loginButtonStyle = const LoginButtonStyle(),
    this.registerButtonStyle = const RegisterButtonStyle(),
    this.changeKeyButtonStyle = const ChangeKeyButtonStyle(),
    // this.secureKeyObject = const SecureKey('', ''),
    super.key,
  });

  /// The app's welcome image used as the left panel or the background.
  ///
  /// For a desktop dimensions the image is displayed as the left panel on the
  /// login screen.  For mobile dimensions (narrow screen) the image forms the
  /// background behind the Login panel.

  final AssetImage image;

  /// The style of the REGISTER button.

  final RegisterButtonStyle registerButtonStyle;

  /// The style of the LOGIN button.

  final LoginButtonStyle loginButtonStyle;

  /// The style of the INFO button.

  final InfoButtonStyle infoButtonStyle;

  /// The style of the CONTINUE button.

  final ContinueButtonStyle continueButtonStyle;

  /// The style of the CHANGE KEY button.

  final ChangeKeyButtonStyle changeKeyButtonStyle;

  /// The app's logo as displayed at the top of the login panel.

  final AssetImage logo;

  /// The login text indicating what we are loging in to.

  final String title;

  /// The URI of the user's webID used to identify the Solid server to
  /// authenticate against.

  final String webID;

  /// The text to display on the LOGIN button.
  ///
  /// An app may override this if they prefer, for example, AUTHENTICATE.

  final String loginText;

  /// The text to display on the GET A POD button.
  ///
  /// An app may override this to be more suggestive. For example the app
  /// developer may prefere REGISTER.

  final String registerText;

  /// The text to display on the INFO button.
  ///
  /// An app may override this to be more suggestive. For example, it could be
  /// HELP or README.

  final String infoText;

  /// The text to display on the CONTINUE button.
  ///
  /// An app may override this to be more suggestive of what is being continued
  /// on to, such as SESSION for an app the manages sessions, or KEYS for an app
  /// that manages keys.

  final String continueText;

  /// The background colour for the CONTINUE button.

  final Color continueBG;

  /// The URL used as the value of the Visit link. Visit the link by clicking
  /// info button.

  final String link;

  /// The child widget after logging in.

  final Widget child;

  /// The default is to require a Solid Pod authentication.
  ///
  /// If the app provides functionality that does not or does not immediately
  /// require access to Pod data then set this to false and a CONTINUE button
  /// is available on the Login page.

  final bool required;

  // /// Secure key object
  // final SecureKey secureKeyObject;

  @override
  State<SolidLogin> createState() => _SolidLoginState();
}

class _SolidLoginState extends State<SolidLogin> {
  // This strings will hold the application version number and app name.
  // Initially, it's an empty string because the actual version number
  // will be obtained asynchronously from the app's package information.

  String appVersion = '';
  String appName = '';

  /// Default folders will be generated after user logged in.

  List<String> defaultFolders = [];

  /// Default files will be generated after user logged in.

  Map<dynamic, dynamic> defaultFiles = {};

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  // Fetch the package information.

  Future<void> _initPackageInfo() async {
    final folders = await generateDefaultFolders();
    final files = await generateDefaultFiles();

    setState(() {
      defaultFolders = folders;
      defaultFiles = files;
    });
  }

  // Function to update [_isDialogCanceled].

  void updateState() {
    setState(() {
      _isDialogCanceled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The login box's default image Widget for the left/background panel
    // depending on screen width.

    final loginBoxDecor = BoxDecoration(
      image: DecorationImage(
        image: widget.image,
        fit: BoxFit.cover,
      ),
    );

    // Text controller for the URI of the solid server to which an authenticate
    // request is sent.

    final webIdController = TextEditingController()..text = widget.webID;

    // The GET A POD button that when pressed will launch a browser to the
    // relevant link from where a user can register for a POD on the Solid
    // server. The default location is relative to the [webID], and is currently
    // a fixed path but needs to be obtained from the server meta data, as was
    // done in solid_auth through [getIssuer].

    final registerButton = PodButton(
      text: widget.registerButtonStyle.text,
      background: widget.registerButtonStyle.background,
      foreground: widget.registerButtonStyle.foreground,
      tooltip: widget.registerButtonStyle.tooltip,
      onPressed: () {
        launchUrl(
            Uri.parse('${widget.webID}/.account/login/password/register/'));
      },
    );

    final changeKeyButton = PodButton(
        text: widget.changeKeyButtonStyle.text,
        background: widget.changeKeyButtonStyle.background,
        foreground: widget.changeKeyButtonStyle.foreground,
        tooltip: widget.changeKeyButtonStyle.tooltip,
        onPressed: () async {
          showDialog(
            context: context,
            builder: (context) {
              return const ChangeKeyDialog();
            },
          );

          // // Reset the flag.

          // _isDialogCanceled = false;

          // // Method to show busy animation requiring BuildContext.
          // //
          // // This approach of creating a local method will avoid the `flutter
          // // analyze` issue `use_build_context_synchronously`, identifying the use
          // // of a BuildContext across asynchronous gaps, without referencing the
          // // BuildContext after the async gap.

          // void showBusyAnimation() {
          //   showAnimationDialog(
          //     context,
          //     2,
          //     'Loading...',
          //     false,
          //     updateState,
          //   );
          // }

          // showBusyAnimation();

          // if (_isDialogCanceled) return;

          // // Perform the actual authentication by contacting the server at
          // // [WebID].

          // final authResult = await solidAuthenticate(widget.webID, context);

          // // Navigates to the Initial Setup Screen using the provided authentication data.

          // Future<void> navInitialSetupScreen(Map<dynamic, dynamic> authData,
          //     List<dynamic> resCheckList) async {
          //   await Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => InitialSetupScreen(
          //               // authData: authData,
          //               // webId: widget.webID,
          //               // appName: appName,
          //               resCheckList: resCheckList,
          //               child: widget.child,
          //             )),
          //   );
          // }

          // // // Navigates to the Home Screen if the account exits.

          // // Future<void> navHomeScreen(Map<dynamic, dynamic> authData) async {
          // //   await Navigator.pushReplacement(
          // //     context,
          // //     MaterialPageRoute(builder: (context) => widget.child),
          // //   );
          // // }

          // // // Method to navigate to the child widget, requiring BuildContext, and
          // // // so avoiding the "don't use BuildContext across async gaps" warning.

          // // Future<void> navigateToApp(Map<dynamic, dynamic> authData) async {
          // //   final resCheckList = await initialStructureTest(
          // //       appName, defaultFolders, defaultFiles);
          // //   final allExists = resCheckList.first as bool;

          // //   if (!allExists) {
          // //     await navInitialSetupScreen(authData, resCheckList);
          // //   }

          // //   await navHomeScreen(authData);
          // // }

          // // Method to navigate back to the login widget, requiring BuildContext,
          // // and so avoiding the "don't use BuildContext across async gaps"
          // // warning.

          // void navigateToLogin() {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(builder: (context) => widget),
          //   );
          // }

          // // Check that the authentication succeeded, and if so navigate to the
          // // app itself. If it failed then notify the user and stay on the
          // // SolidLogin page.

          // if (authResult != null && authResult.isNotEmpty) {
          //   // await navigateToApp(authResult.first as Map);
          //   print("test");
          // } else {
          //   // On moving to using navigateToLogin() the previously implemented
          //   // asynchronous showAuthFailedPopup() is lost due to the immediately
          //   // following Navigator. We probably don't need a popup and so the code
          //   // is much simpler and the user interaction is probably clear enough
          //   // for now that for some reason we remain on the Login screen. If
          //   // there are non-obvious scneraiors where we fail to authenticate and
          //   // revert to thte login screen then we can capture and report them
          //   // later.

          //   navigateToLogin();
          // }
        });

    // A LOGIN button that when pressed will proceed to attempt to connect to
    // the URI through a browser to allow the user to authenticate
    // themselves. On return from the authentication, if successful, the class
    // provided child widget is instantiated.

    final loginButton = PodButton(
        text: widget.loginButtonStyle.text,
        background: widget.loginButtonStyle.background,
        foreground: widget.loginButtonStyle.foreground,
        tooltip: widget.loginButtonStyle.tooltip,
        onPressed: () async {
          // Reset the flag.

          _isDialogCanceled = false;

          // Method to show busy animation requiring BuildContext.
          //
          // This approach of creating a local method will avoid the `flutter
          // analyze` issue `use_build_context_synchronously`, identifying the use
          // of a BuildContext across asynchronous gaps, without referencing the
          // BuildContext after the async gap.

          void showBusyAnimation() {
            showAnimationDialog(
              context,
              7,
              'Logging in...',
              false,
              updateState,
            );
          }

          showBusyAnimation();

          if (_isDialogCanceled) return;

          // Perform the actual authentication by contacting the server at
          // [WebID].

          final authResult = await solidAuthenticate(widget.webID, context);

          // Navigates to the Initial Setup Screen using the provided authentication data.

          Future<void> navInitialSetupScreen(List<dynamic> resCheckList) async {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => InitialSetupScreen(
                        resCheckList: resCheckList,
                        child: widget.child,
                      )),
            );
          }

          // Navigates to the Home Screen if the account exits.

          Future<void> navHomeScreen() async {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => widget.child),
            );
          }

          // Method to navigate to the child widget, requiring BuildContext, and
          // so avoiding the "don't use BuildContext across async gaps" warning.

          Future<void> navigateToApp() async {
            final resCheckList =
                await initialStructureTest(defaultFolders, defaultFiles);
            final allExists = resCheckList.first as bool;

            if (!allExists) {
              await navInitialSetupScreen(resCheckList);
            }

            await navHomeScreen();
          }

          // Method to navigate back to the login widget, requiring BuildContext,
          // and so avoiding the "don't use BuildContext across async gaps"
          // warning.

          void navigateToLogin() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => widget),
            );
          }

          // Check that the authentication succeeded, and if so navigate to the
          // app itself. If it failed then notify the user and stay on the
          // SolidLogin page.

          if (authResult != null && authResult.isNotEmpty) {
            await navigateToApp();
          } else {
            // On moving to using navigateToLogin() the previously implemented
            // asynchronous showAuthFailedPopup() is lost due to the immediately
            // following Navigator. We probably don't need a popup and so the code
            // is much simpler and the user interaction is probably clear enough
            // for now that for some reason we remain on the Login screen. If
            // there are non-obvious scneraiors where we fail to authenticate and
            // revert to thte login screen then we can capture and report them
            // later.

            navigateToLogin();
          }
        });

    // A CONTINUE button that when pressed will proceed to operate without the
    // need of a Solid Pod and thus no requirement to authenticate. Proceed
    // directly onto the app (the child).

    final continueButton = PodButton(
      text: widget.continueButtonStyle.text,
      background: widget.continueButtonStyle.background,
      foreground: widget.continueButtonStyle.foreground,
      tooltip: widget.continueButtonStyle.tooltip,
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.child),
        );
      },
    );

    // A INFO button that when pressed will proceed to visit a link.

    final infoButton = PodButton(
      text: widget.infoButtonStyle.text,
      background: widget.infoButtonStyle.background,
      foreground: widget.infoButtonStyle.foreground,
      tooltip: widget.infoButtonStyle.tooltip,
      onPressed: () {
        launchUrl(Uri.parse(widget.link));
      },
    );

    // A version text that is displayed within the login panel. The text box
    // height is set to be just the height of the text, using [boxTextHeight],
    // so that the box can be pushed down closer to the bottom of the Login
    // panel, rather than the box taking up the available vertical space and so
    // centering the text within the box. We choose a grey for the text, using
    // [versionTextColor], as it is not to be a standout text in full black.

    const boxTextHeight = 20.0;
    const versionTextColor = Colors.grey;

    final Widget versionDisplay = SizedBox(
      height: boxTextHeight,
      child: Center(
        child: SelectableText(
          'Version $appVersion',
          style: const TextStyle(
            color: versionTextColor,
          ),
        ),
      ),
    );

    // Build the login panel decorations from the component parts.

    final loginPanelDecor = Container(
      height: 650,
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Image(
            image: widget.logo,
            width: 200,
          ),
          const SizedBox(
            height: 0.0,
          ),
          const Divider(height: 15, thickness: 2),
          const SizedBox(
            height: 50.0,
          ),
          Text(widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              )),
          const SizedBox(
            height: 20.0,
          ),
          TextFormField(
            controller: webIdController,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: loginButton,
                  ),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Expanded(
                    child: widget.required ? registerButton : continueButton,
                  ),
                ],
              ),
              const SizedBox(
                height: 15.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  widget.required
                      ? const Spacer()
                      : Expanded(
                          child: registerButton,
                        ),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Expanded(
                    child: infoButton,
                  ),
                ],
              ),
              const SizedBox(
                height: 15.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Expanded(
                    child: changeKeyButton,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            height: 20.0,
          ),

          // Expand to the bottom of the login panel.
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: versionDisplay,
            ),
          ),
        ],
      ),
    );

    // The final login panel's offset depends on the screen size.

    // TODO 20231228 gjw SOMEONE PLEASE EXPLAIN THE RATIONALE BEHIND THE LOGIC
    // HERE FOR THE PANEL WIDTH.

    final loginPanelInset =
        (_isVeryNarrowScreen(context) || !_isNarrowScreen(context))
            ? 0.05
            : 0.25;

    // Create the actual login panel around the deocrated login panel.

    final loginPanel = Container(
      margin: EdgeInsets.symmetric(
          horizontal: loginPanelInset * _screenWidth(context)),
      child: SingleChildScrollView(
        child: Card(
          elevation: 50,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: loginPanelDecor, //actualChildEventually,
        ),
      ),
    );

    // Bring the two top level components, [loginBoxDecor] and [loginPanel],
    // together to build the final [Scaffold] as the return [Widget] for
    // [solidLogin].

    return Scaffold(
      // TODO 20231228 gjw SOMEONE PLEASE EXPLAIN WHY USING A SafeArea
      // HERE. WHAT MOTIVATED ITS USE?

      body: SafeArea(
        child: DecoratedBox(
          // The image specified as [loginBoxDecor] is used as the background
          // for a narrow screen or else it is the left panel image as specified
          // shortly, and we create an empty BoxDecoration here in that case.

          decoration:
              _isNarrowScreen(context) ? loginBoxDecor : const BoxDecoration(),
          child: Row(
            children: [
              _isNarrowScreen(context)
                  ? Container()
                  : Expanded(
                      flex: 7,
                      child: Container(
                        decoration: loginBoxDecor,
                      ),
                    ),
              Expanded(
                flex: 5,
                child: loginPanel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PodButton extends StatelessWidget {
  const PodButton({
    required this.text,
    required this.background,
    required this.foreground,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
  final VoidCallback onPressed;

  // Define a common style for the text of the two buttons, GET POD and LOGIN.

  final buttonTextStyle = const TextStyle(
    fontSize: 12.0,
    letterSpacing: 2.0,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          // Increase vertical padding.

          padding: const EdgeInsets.symmetric(vertical: 12),
          // Ensure a minimum size of 48px in height as per guidelines.

          minimumSize: const Size(88, 48),
        ),
        child: Text(
          text,
          style: buttonTextStyle,
        ),
      ),
    );
  }
}

/// A data structure for the buttons used in the Solid Login widget.

class ContinueButtonStyle {
  const ContinueButtonStyle({
    this.text = defaultContinueButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultContinueTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class ChangeKeyButtonStyle {
  const ChangeKeyButtonStyle({
    this.text = defaultChangeKeyButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultContinueTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class LoginButtonStyle {
  const LoginButtonStyle({
    this.text = defaultLoginButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultLoginTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class RegisterButtonStyle {
  const RegisterButtonStyle({
    this.text = defaultRegisterButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultRegisterTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}

class InfoButtonStyle {
  const InfoButtonStyle({
    this.text = defaultInfoButtonText,
    this.background = defaultButtonBackground,
    this.foreground = defaultButtonForeground,
    this.tooltip = defaultInfoTooltip,
  });
  final String text;
  final Color background;
  final Color foreground;
  final String tooltip;
}
