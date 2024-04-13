<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

**UNDER DEVELOPMENT**

This package is currently under development and some API may
change. The SolidLogin() and SolidLoginPopup() are used in a number
of apps now and are more stable.

# Solid Pods

Visit https://soidcommunity.au

Solid is an open standard for a server hosting personal online data
stores (Pods). Numerous providers of Solid Server hosting are emerging
allowing users to host and migrate their Pods on any such 
servers (or to run their own server. 

This package supports high level access for apps to
authenticate users and then to access the user's data from their
Pods through Flutter Widgets. 

## Features

+ Standard widget [SolidLogin] to support authentication against a Solid server:

Default style:

<div align="center">
	<img
	src="https://github.com/anusii/solidpod/blob/dev/images/solid_login.png"
	alt="Solid Login" width="400">
</div>

Optional version and visit link:

<div align="center">
	<img
	src="https://github.com/anusii/solidpod/blob/dev/images/podnotes_login.png"
	alt="Solid Login" width="400">
</div>

Changing the image, logo, login text, colour scheme:

<div align="center">
	<img
	src="https://github.com/anusii/solidpod/blob/dev/images/tomy_login.png"
	alt="KeyPod Login" width="400">
</div>

Change the image, logo, login text, button style, colour scheme:

<div align="center">
	<img
	src="https://github.com/anusii/solidpod/blob/dev/images/keypod_login.png"
	alt="KeyPod Login" width="400">
</div>

Fine tune to suit the theme of the app:

<div align="center">
	<img
	src="https://github.com/anusii/solidpod/blob/dev/images/innerpod_login.png"
	alt="KeyPod Login" width="400">
</div>

## Getting started

TODO: List prerequisites and provide or pointer to information on how
to start using the package.

## Usage

A simple login screen is provided by the package to take care of the
details for authenticating a user against a Solid server. If your
own home widget is call `MyHome()` then simply wrap this within  the
`SolidLogin()` widget:

of the 
```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pod',
      home: const SolidLogin(
        child: Scaffold(body: MyHome()),
      ),
    );
  }
```

## Additional information

TODO: More about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can
expect from the package authors, and more.
