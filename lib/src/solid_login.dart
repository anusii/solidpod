/// A widget to obtain a Solid token to access the user's POD.
///
// Time-stamp: <Thursday 2024-01-04 07:08:41 +1100 Graham Williams>
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
library;

import 'package:flutter/material.dart';
import 'package:solid/src/login/solid_authenticate.dart';
import 'package:solid/src/widgets/popup_warning.dart';
import 'package:solid/src/widgets/show_animation_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

// The following are the constant default values, mostly for the parameters for
// the SolidLogin class. These defaults can be overriden by a user to tune to
// their own liking and style.

/// The default image to be displayed as the left panel or else the background
/// on a narrow screen.

const _defaultImage = AssetImage(
  'assets/images/default_image.jpg',
  package: 'solid',
);

// The default logo to be displayed at the top of the login panel on the right
// of the screen or centered for narrow screens.

const _defaultLogo = AssetImage(
  //'assets/images/default_logo.png',
  'assets/images/default_logo.png',
  package: 'solid',
);

/// The default message to be displayed within the login panel.

const _defaultTitle = 'LOGIN WITH YOUR POD';

/// The Visit link for the app.

const _defaultLink = 'https://solidproject.org';

/// The default login panale card background colour.

const _defaultLoginPanelCardColour = Color(0xFFF2F4FC);

/// The default login button background colour.

const _defaultGetPodButtonBG = Colors.orange;

/// The default login button text colour.

const _defaultGetPodButtonFG = Color(0xFF50084D);

/// The default login button background colour.

const _defaultLoginButtonBG = Colors.teal;

// The default URI for the SOlid server that is suggested for the app.

const _defaultWebID = 'https://pods.solidcommunity.au';

// The package version string.

// TODO 20231229 gjw GET THE ACTUAL VERSION FROM pubspec.yaml. IDEALLY THIS IS
// THE APP'S VERSION NOT THE SOLID PACKAGE'S VERSION.

const _defaultVersion = 'Version 0.0.0';

// Screen size support funtions to identify narrow and very narrow screens.

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
    required this.child,
    this.image = _defaultImage,
    this.logo = _defaultLogo,
    this.title = _defaultTitle,
    this.webID = _defaultWebID,
    this.link = _defaultLink,
    this.getpodBG = _defaultGetPodButtonBG,
    this.loginBG = _defaultLoginButtonBG,
    this.version = _defaultVersion,
    super.key,
  });

  /// The app's welcome image used on the left or background.
  ///
  /// For a desktop dimensions the image is displayed to the left on the login
  /// screen, and for mobile dimensions it is the background

  final AssetImage image;

  /// The app's logo as displayed in the login panel.

  final AssetImage logo;

  /// The login title text indicating what we are loging in to.

  final String title;

  /// Override the default webID.

  final String webID;

  /// A URL as the value of the Visit link.

  final String link;

  /// The background colour of the GET POD button.

  final Color getpodBG;

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

    final getPodButton = TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: getpodBG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // TODO 20231229 gjw NEED TO USE AN APPROACH TO GET THE RIGHT SOLID SERVER
      // REGISTRATION URL WHICH HAS CHANGED OVER SERVERS. PERHAPS IT IS NEEDED
      // TO BE OBTAINED FROM THE SERVER META DATA? CHECK WITH ANUSHKA. MIGRATE
      // getIssuer() FROM solid-auth PERHAPS WITH lauchIssuerReg() IF THERE IS A
      // REQUIREMENT FOR THAT TOO?

      onPressed: () =>
          launchUrl(Uri.parse('$webID/.account/login/password/register/')),

      child: const Text(
        'GET A POD',
        style: TextStyle(
          color: _defaultGetPodButtonFG,
          letterSpacing: 2.0,
          fontSize: 15.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // A LOGIN button that when pressed will proceed to attempt to connect to
    // the URI through a browser to allow the user to authenticate
    // themselves. On return from the authentication, if successful, the class
    // provided child widget is instantiated.

    final loginButton = TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: loginBG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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

        final authResult = await solidAuthenticate(webID, context);

        // Method to navigate to a child widget requiring BuildContext.

        void navigateToApp() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => child),
          );
        }

        // Method to show show auth faileding popup requiring BuildContext.

        void showAuthFailedPopup() {
          popupWarning(context, 'Authentication has failed!');
        }

        if (authResult != null) {
          // Call the action that needs BuildContext
          navigateToApp();
        } else {
          // Call the action that needs BuildContext
          showAuthFailedPopup();
        }
      },
      child: const Text(
        'LOGIN',
        style: TextStyle(
          color: Colors.white,
          letterSpacing: 2.0,
          fontSize: 15.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );

    // An Information link that is conditionally displayed within the login
    // panel.

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

    // A version text that is conditionally displayed within the login panel.

    const smallTextContainerHeight = 20.0;
    const smallTextSize = 14.0;
    const stripTextColor = Color(0xFF757575);

    final Widget versionDisplay = Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      height: smallTextContainerHeight,
      child: Center(
        child: SelectableText(
          version,
          style: const TextStyle(
            color: stripTextColor,
            fontSize: smallTextSize,
          ),
        ),
      ),
    );

    // Build the login panel docrations from the comonent parts.

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
          // Leave alittle space before the link.
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
          color: _defaultLoginPanelCardColour,
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
