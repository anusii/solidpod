/// A widget to obtain a Solid token to access the user's POD.
///
// Time-stamp: <Thursday 2024-01-04 10:42:58 +1100 Graham Williams>
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
/// Authors: Graham Williams, Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:solid/src/login/solid_authenticate.dart';
import 'package:solid/src/widgets/popup_warning.dart';
import 'package:solid/src/widgets/show_animation_dialog.dart';

// The default package version string as the version of the app.

// TODO 20231229 gjw GET THE ACTUAL VERSION FROM pubspec.yaml. IDEALLY THIS IS
// THE APP'S VERSION NOT THE SOLID PACKAGE'S
// VERSION. https://github.com/anusii/solid/issues/18

const _defaultVersion = 'Version 0.0.0';

// Screen size support funtions to identify narrow and very narrow screens. The
// width dictates whether the Login panel is laid out on the right with the app
// image on the left, or is on top of the app image.

const int narrowScreenLimit = 1175;
const int veryNarrowScreenLimit = 750;

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

bool isNarrowScreen(BuildContext context) =>
    screenWidth(context) < narrowScreenLimit;

bool isVeryNarrowScreen(BuildContext context) =>
    screenWidth(context) < veryNarrowScreenLimit;

/// A widget to login to a Solid server for a user's token to access their POD.
///
/// The login screen will be the initial screen of the app when access to the
/// user's POD is required for any of the functionality of the app requires
/// access to the user's POD.

class SolidLogin extends StatelessWidget {
  const SolidLogin({
    // Include the literals here so that they are exposed through the docs,
    // except for version which is TO BE calculated.

    required this.child,
    this.image =
        const AssetImage('assets/images/default_image.jpg', package: 'solid'),
    this.logo =
        const AssetImage('assets/images/default_logo.png', package: 'solid'),
    this.panelBG = const Color(0xFFF2F4FC),
    this.title = 'LOG IN TO YOUR POD',
    this.webID = 'https://pods.solidcommunity.au',
    this.link = 'https://solidproject.org',
    this.getpodFG = Colors.purple,
    this.getpodBG = Colors.orange,
    this.loginFG = Colors.white,
    this.loginBG = Colors.teal,
    this.version = _defaultVersion,
    super.key,
  });

  /// The app's welcome image used as the left panel or the background.
  ///
  /// For a desktop dimensions the image is displayed as the left panel on the
  /// login screen.  For mobile dimensions (narrow screen) the image forms the
  /// background behind the Login panel.

  final AssetImage image;

  /// The app's logo as displayed at the top of the login panel.

  final AssetImage logo;

  /// The Login panel's background colour. The default background colour is a
  /// very light grey as a sublte background.

  final Color panelBG;

  /// The login text indicating what we are loging in to.

  final String title;

  /// The URI of the user's webID used to identify the Solid server to
  /// authenticate against.

  final String webID;

  /// The URL used as the value of the Visit link.

  final String link;

  /// The foreground colour of the GET POD button.

  final Color getpodFG;

  /// The background colour of the GET POD button.

  final Color getpodBG;

  /// The foreground colour of the LOGIN button.

  final Color loginFG;

  /// The background colour of the LOGIN button.

  final Color loginBG;

  /// The default version string can be overidden.

  final String version;

  /// The widget to hand over to once authentication is complete.

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The login box's default image Widget for the left/background panel
    // depending on screen width.

    final loginBoxDecor = BoxDecoration(
      image: DecorationImage(
        image: image,
        fit: BoxFit.cover,
      ),
    );

    // Text controller for the URI of the solid server to which an authenticate
    // request is sent. Its default value is the [webID] which has a default
    // value or else overridden by the call to the widget.

    final webIdController = TextEditingController()..text = webID;

    // The GET A POD button that when pressed will launch a browser to the
    // releveant link from where a user can register for a POD on the Solid
    // server. The default location is relative to the [webID], and is currently
    // a fixed path but needs to be obtained from the server meta data, as was
    // done in solid_auth through [getIssuer].

    const buttonLetterSpacing = 2.0;
    const buttonFontSize = 15.0;
    const buttonFontWeight = FontWeight.bold;
    const buttonPadding = EdgeInsets.all(20);
    final buttonBorderRadius = BorderRadius.circular(10);

    final getPodButton = TextButton(
      style: TextButton.styleFrom(
        padding: buttonPadding,
        backgroundColor: getpodBG,
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
      ),

      // TODO 20231229 gjw NEED TO USE AN APPROACH TO GET THE RIGHT SOLID SERVER
      // REGISTRATION URL WHICH HAS CHANGED OVER SERVERS. PERHAPS IT IS NEEDED
      // TO BE OBTAINED FROM THE SERVER META DATA? CHECK WITH ANUSHKA. MIGRATE
      // getIssuer() FROM solid-auth PERHAPS WITH lauchIssuerReg() IF THERE IS A
      // REQUIREMENT FOR THAT TOO? https://github.com/anusii/solid/issues/25.

      onPressed: () =>
          launchUrl(Uri.parse('$webID/.account/login/password/register/')),

      child: Text(
        'GET A POD',
        style: TextStyle(
          color: getpodFG,
          letterSpacing: buttonLetterSpacing,
          fontSize: buttonFontSize,
          fontWeight: buttonFontWeight,
        ),
      ),
    );

    // A LOGIN button that when pressed will proceed to attempt to connect to
    // the URI through a browser to allow the user to authenticate
    // themselves. On return from the authentication, if successful, the class
    // provided child widget is instantiated.

    final loginButton = TextButton(
      style: TextButton.styleFrom(
        padding: buttonPadding,
        backgroundColor: loginBG,
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
      ),
      onPressed: () async {
        // Authenticate against the Solid server.

        // Method to show busy animation requiring BuildContext.
        //
        // This approach of creating a local method will address the `flutter
        // analyze` issue `use_build_context_synchronously`, identifying the use
        // of a BuildContext across asynchronous gaps, without referencing the
        // BuildContext after the async gap.

        void showBusyAnimation() {
          showAnimationDialog(
            context,
            7,
            'Logging in...',
            false,
          );
        }

        showBusyAnimation();

        // Perform the actual authentication by contacting the server at
        // [WebID].

        final authResult = await solidAuthenticate(webID, context);

        // Method to navigate to the child widget, requiring BuildContext.

        void navigateToApp() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => child),
          );
        }

        // Method to show auth failed popup, requiring BuildContext.

        void showAuthFailedPopup() {
          popupWarning(context, 'Authentication has failed!');
        }

        // Check that the authentication succeeded, and if so navigate to the
        // app itself. If it failed then notify the user and stay on the
        // SolidLogin page.

        if (authResult != null) {
          navigateToApp();
        } else {
          showAuthFailedPopup();
        }
      },
      child: Text(
        'LOGIN',
        style: TextStyle(
          color: loginFG,
          letterSpacing: buttonLetterSpacing,
          fontSize: buttonFontSize,
          fontWeight: buttonFontWeight,
          // TODO 20240104 gjw WHY THE CHOICE OF THIS SPECIFIC FONT? THIS WILL
          // OVERRIDE ANY THEMES AND SO COULD CAUSE THE BUTTON TO LOOK RATHER
          // DIFFERENT TO EVERYTHING ELSE WITHOUT A USER BEING ABLE TO FIX IT?
          // fontFamily: 'Poppins',
        ),
      ),
    );

    // An Information link that is displayed within the Login panel.

    Widget linkTo(String link) => GestureDetector(
          onTap: () => launchUrl(Uri.parse(link)),
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Visit '),
                SelectableText(
                  link,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: screenWidth(context) > 400 ? 15 : 13,
                      color: Colors.blue,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
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
          version,
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
            image: logo,
            width: 200,
          ),
          const SizedBox(
            height: 0.0,
          ),
          const Divider(height: 15, thickness: 2),
          const SizedBox(
            height: 50.0,
          ),
          Text(title,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: getPodButton,
              ),
              const SizedBox(
                width: 15.0,
              ),
              Expanded(
                child: loginButton,
              ),
            ],
          ),
          // Leave a little space before the link.
          const SizedBox(
            height: 20.0,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: linkTo(link),
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
        (isVeryNarrowScreen(context) || !isNarrowScreen(context)) ? 0.05 : 0.25;

    // Create the actual login panel around the deocrated login panel.

    final loginPanel = Container(
      margin: EdgeInsets.symmetric(
          horizontal: loginPanelInset * screenWidth(context)),
      child: SingleChildScrollView(
        child: Card(
          elevation: 5,
          color: panelBG,
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
              isNarrowScreen(context) ? loginBoxDecor : const BoxDecoration(),
          child: Row(
            children: [
              isNarrowScreen(context)
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
