/// SolidPod library to support privacy first data store on Solid Servers
///
// Time-stamp: <Monday 2025-08-11 09:38:44 +1000 Graham Williams>
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
/// Authors: Graham Williams, Anushka Vidanage, Ashley Tang

library;

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:solidpod/src/screens/initial_setup/initial_setup_screen.dart';
import 'package:solidpod/src/solid/api/rest_api.dart' show initialStructureTest;
import 'package:solidpod/src/solid/authenticate.dart';
import 'package:solidpod/src/solid/utils/login_helper.dart';
import 'package:solidpod/src/solid/utils/misc.dart'
    show
        generateDefaultFiles,
        generateDefaultFolders,
        getAppNameVersion,
        setAppDirName,
        checkLoggedIn;
import 'package:solidpod/src/solid/utils/push_replacement.dart';
import 'package:solidpod/src/widgets/login_theme.dart';
import 'package:solidpod/src/widgets/pod_button.dart';
import 'package:solidpod/src/widgets/show_animation_dialog.dart';
import 'package:solidpod/src/widgets/snackbar_config.dart';

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
    this.appDirectory = '',
    this.image = const AssetImage(
      'assets/images/default_image.jpg',
      package: 'solidpod',
    ),
    this.logo = const AssetImage(
      'assets/images/default_logo.png',
      package: 'solidpod',
    ),
    this.title = 'Log in to your Solid Pod',
    this.webID = 'https://pods.solidcommunity.au',
    this.link = 'https://solidproject.org',
    this.continueButtonStyle = const ContinueButtonStyle(),
    this.infoButtonStyle = const InfoButtonStyle(),
    this.loginButtonStyle = const LoginButtonStyle(),
    this.registerButtonStyle = const RegisterButtonStyle(),
    this.changeKeyButtonStyle = const ChangeKeyButtonStyle(),
    this.themeConfig = const SolidLoginTheme(),
    this.snackbarConfig = const SnackbarConfig(),
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

  /// Directory name to consider when storing app data.

  final String appDirectory;

  /// Theme configuration for the login panel.

  final SolidLoginTheme themeConfig;

  /// Snackbar configuration for login notifications.

  final SnackbarConfig snackbarConfig;

  @override
  State<SolidLogin> createState() => _SolidLoginState();
}

class _SolidLoginState extends State<SolidLogin> {
  // This strings will hold the application version number and app name.
  // Initially, it's an empty string because the actual version number
  // will be obtained asynchronously from the app's package information.

  String appVersion = '';
  String appName = '';

  // Check whether the dialog was dismissed by the user.

  bool isDialogCanceled = false;

  /// Default folders will be generated after user logged in.

  List<String> defaultFolders = [];

  /// Default files will be generated after user logged in.

  Map<dynamic, dynamic> defaultFiles = {};

  // Track the current theme mode.
  // Always start with light mode regardless of system preference.

  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();

    // dc 20251022: please explain why calling an async without await.
    _initPackageInfo();
  }

  // Fetch the package information.

  Future<void> _initPackageInfo() async {
    // Check if widget is still mounted before starting any async operations.
    // This prevents unnecessary work if the widget has been disposed.

    if (!mounted) return;

    await setAppDirName(widget.appDirectory);
    final folders = await generateDefaultFolders();
    final files = await generateDefaultFiles();

    // Check if widget is still mounted after async operations and before setState.
    // This prevents "setState() called after dispose()" errors that can occur
    // if the widget was disposed while async operations were running.

    if (!mounted) return;

    setState(() {
      defaultFolders = folders;
      defaultFiles = files;
    });

    // Fetch the app information.

    final appInfo = await getAppNameVersion();

    // Check if widget is still mounted after final async operation and before setState.
    // This ensures we don't call setState on a disposed widget, which would throw
    // a FlutterError and potentially crash the app.

    if (!mounted) return;

    setState(() {
      appName = appInfo.name;
      appVersion = appInfo.version;
    });
  }

  // Function to update [_isDialogCanceled].

  void updateState() {
    if (mounted) {
      setState(() {
        isDialogCanceled = true;
      });
    }
  }

  // Helper method to create and show a snackbar with consistent theming.

  void _showSnackbar(String message, {Duration? duration}) {
    final currentTheme = isDarkMode
        ? widget.themeConfig.darkTheme
        : widget.themeConfig.lightTheme;

    final backgroundColor = widget.snackbarConfig.backgroundColor ??
        (isDarkMode
            ? currentTheme.backgroundColor.withValues(alpha: 0.9)
            : currentTheme.backgroundColor.withValues(alpha: 0.7));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: widget.snackbarConfig.textColor != Colors.black
                ? widget.snackbarConfig.textColor
                : currentTheme.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: duration ?? widget.snackbarConfig.duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            widget.snackbarConfig.borderRadius,
          ),
          side: BorderSide(color: currentTheme.dividerColor, width: 0.5),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: widget.snackbarConfig.actionTextColor != Colors.black
              ? widget.snackbarConfig.actionTextColor
              : currentTheme.titleColor,
          onPressed: () {},
        ),
      ),
    );
  }

  // Toggle between light and dark mode.

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the internal state for theme instead of system brightness.

    final currentTheme = isDarkMode
        ? widget.themeConfig.darkTheme
        : widget.themeConfig.lightTheme;

    // The login box's default image Widget for the left/background panel
    // depending on screen width.

    final loginBoxDecor = BoxDecoration(
      image: DecorationImage(image: widget.image, fit: BoxFit.cover),
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
        final podServer = webIdController.text.isNotEmpty
            ? webIdController.text
            : widget.webID;
        launchUrl(Uri.parse('$podServer/.account/login/password/register/'));
      },
    );

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

        isDialogCanceled = false;

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

        if (isDialogCanceled) return;

        // Get webId from the textfield or assign a default one.

        final podServer = webIdController.text.isNotEmpty
            ? webIdController.text
            : widget.webID;

        // Check if user is already logged in before attempting authentication.

        final wasAlreadyLoggedIn = await checkLoggedIn();

        if (!context.mounted) return;

        // Only show the browser login instructions if user is not already logged in.

        if (!wasAlreadyLoggedIn) {
          // Use a longer duration for this snackbar since it's replacing the login animation.
          const loginDuration = Duration(seconds: 30);
          _showSnackbar(
            'Please complete the login process in your browser...',
            duration: loginDuration,
          );

          // Show the animation after the snackbar.

          await Future.delayed(const Duration(milliseconds: 500));
          showBusyAnimation();
        }

        // Perform the actual authentication by contacting the server at
        // [WebID].

        if (!context.mounted) return;
        final authResult = await solidAuthenticate(podServer, context);

        // If authentication succeeded and the user was already logged in,
        // it means they are using a cached session.

        final isCachedSession =
            wasAlreadyLoggedIn && authResult != null && authResult.isNotEmpty;

        // Check that the authentication succeeded, and if so navigate to the
        // app itself. If it failed then notify the user and stay on the
        // SolidLogin page.

        if (authResult != null && authResult.isNotEmpty) {
          if (!context.mounted) return;

          // Close the animation dialog before proceeding.

          if (!wasAlreadyLoggedIn) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Dismiss the login process snackbar.

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // If using a cached session, show snackbar informing about it.

          if (isCachedSession) {
            _showSnackbar(
              'Logged in with your previously saved session.',
              duration: Duration(seconds: 2),
            );

            // Short delay to allow snackbar to be visible.

            await Future.delayed(const Duration(milliseconds: 300));
          }

          // Navigate to the appropriate screen based on structure test.

          final resCheckList = await initialStructureTest(
            defaultFolders,
            defaultFiles,
          );
          final allExists = resCheckList.first as bool;

          if (!context.mounted) return;

          if (!allExists) {
            await pushReplacement(
              context,
              InitialSetupScreen(
                resCheckList: resCheckList,
                originalLogin: widget,
                child: widget.child,
              ),
            );
            // await Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => InitialSetupScreen(
            //       resCheckList: resCheckList,
            //       originalLogin: widget,
            //       child: widget.child,
            //     ),
            //   ),
            // );
          } else {
            await pushReplacement(context, widget.child);
            // await Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => widget.child),
            // );
          }
        } else {
          // On moving to using navigateToLogin() the previously implemented
          // asynchronous showAuthFailedPopup() is lost due to the immediately
          // following Navigator. We probably don't need a popup and so the code
          // is much simpler and the user interaction is probably clear enough
          // for now that for some reason we remain on the Login screen. If
          // there are non-obvious scnerairos where we fail to authenticate and
          // revert to the login screen then we can capture and report them
          // later.

          if (!context.mounted) return;

          // Close the animation dialog before navigating back to login.
          if (!wasAlreadyLoggedIn) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Navigate back to the login screen after authentication failed.

          await pushReplacement(context, widget);
          // await Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => widget),
          // );
        }
      },
    );

    // A CONTINUE button that when pressed will proceed to operate without the
    // need of a Solid Pod and thus no requirement to authenticate. Proceed
    // directly onto the app (the child).

    final continueButton = PodButton(
      text: widget.continueButtonStyle.text,
      background: widget.continueButtonStyle.background,
      foreground: widget.continueButtonStyle.foreground,
      tooltip: widget.continueButtonStyle.tooltip,
      onPressed: () async => await pushReplacement(context, widget.child),
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => widget.child),
      // );
    );

    // An INFO button that when pressed will proceed to visit a link, often
    // further information or a README or user guide.

    final infoButton = PodButton(
      text: widget.infoButtonStyle.text,
      background: widget.infoButtonStyle.background,
      foreground: widget.infoButtonStyle.foreground,
      tooltip: widget.infoButtonStyle.tooltip,
      onPressed: () => launchUrl(Uri.parse(widget.link)),
    );

    // A version text that is displayed within the login panel. The text box
    // height is set to be just the height of the text, using [boxTextHeight],
    // so that the box can be pushed down closer to the bottom of the Login
    // panel, rather than the box taking up the available vertical space and so
    // centering the text within the box. We choose a grey for the text, using
    // [versionTextColor], as it is not to be a standout text in full black.

    const boxTextHeight = 20.0;
    // const versionTextColor = Colors.grey;

    // final Widget versionDisplay = SizedBox(
    //   height: boxTextHeight,
    //   child: Center(
    //     child: SelectableText(
    //       'Version $appVersion',
    //       style: const TextStyle(
    //         color: versionTextColor,
    //       ),
    //     ),
    //   ),
    // );

    // Build the login panel decorations from the component parts.

    final loginPanelContent = Container(
      height: 650,
      padding: const EdgeInsets.all(30),
      color: currentTheme.backgroundColor,
      child: Column(
        children: [
          Image(image: widget.logo, width: 200),
          const SizedBox(height: 0.0),
          Divider(height: 15, thickness: 2, color: currentTheme.dividerColor),
          const SizedBox(height: 50.0),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: currentTheme.titleColor,
            ),
          ),
          const SizedBox(height: 20.0),
          getSolidServerTooltip(webIdController, currentTheme),
          const SizedBox(height: 20.0),

          // Column of buttons

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: loginButton),
                  const SizedBox(width: 15.0),
                  Expanded(
                    child: widget.required ? registerButton : continueButton,
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              Row(
                children: [
                  if (!widget.required) Expanded(child: registerButton),
                  if (widget.required)
                    Expanded(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: infoButton,
                      ),
                    ),
                  const SizedBox(width: 15.0),
                  widget.required
                      ? const Spacer()
                      : Expanded(child: infoButton),
                ],
              ),
              const SizedBox(height: 15.0),
            ],
          ),

          const SizedBox(height: 20.0),

          // Expand to the bottom of the login panel.
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: boxTextHeight,
                child: Center(
                  child: SelectableText(
                    'Version $appVersion',
                    style: TextStyle(color: currentTheme.versionTextColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap the content in a Stack to add the theme toggle.

    final loginPanelDecor = Stack(
      children: [
        loginPanelContent,
        Positioned(
          top: 10,
          right: 10,
          child: getThemeToggleTooltip(isDarkMode, onPressed: _toggleTheme),
        ),
      ],
    );

    // The final login panel's offset depends on the screen size.

    // TODO 20231228 gjw SOMEONE PLEASE EXPLAIN THE RATIONALE BEHIND THE LOGIC
    // HERE FOR THE PANEL WIDTH.

    final loginPanelInset =
        (isVeryNarrowScreen(context) || !isNarrowScreen(context)) ? 0.05 : 0.25;

    // Create the actual login panel around the decorated login panel.

    final loginPanel = Container(
      margin: EdgeInsets.symmetric(
        horizontal: loginPanelInset * screenWidth(context),
      ),
      child: SingleChildScrollView(
        child: Card(
          elevation: 50,
          color: currentTheme.cardColor,
          shadowColor: currentTheme.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
                      child: Container(decoration: loginBoxDecor),
                    ),
              Expanded(flex: 5, child: loginPanel),
            ],
          ),
        ),
      ),
    );
  }
}
