# SolidPod Changelog

Recorded here are the high level changes for the SolidPod package.

Guide: Each version update is recorded here with a short user-oriented
description of the update. Updates in the 0.6.n series are heading
toward a 0.7 release. The `[version timestamp user]` string is
utilised by the flutter version_widget package.

Visit the package at [pub.dev](https://pub.dev/packages/solidpod).

## 0.9 Stabilise

+ Publish to pub.dev [0.8.0 20251117 gjwgit]

## 0.8 Updated API and migrate UI components to solidui

+ Review and refine package [0.7.23 20251105 cdawei]
+ Migrate login and key UI to solidui [0.7.22 20251102 tonypioneer]
+ Migrate GrantPermission UI to solidui [0.7.21 20251031 cdawei]
+ Support key inheritance [0.7.20 20251101 anushkavidanage]
+ Additional parameter for writePod [0.7.19 20251101 anushkavidanage]
+ Refactor to reduce file sizes [0.7.18 20251030 cdawei]
+ Remove circular dependency with solidui [0.7.17 20251029 tonypioneer]
+ Read shared resource with inheritance [0.7.16 20251027 anushkavidanage]
+ Migrate SolidLogin to solidui [0.7.15 20251027 tonypioneer]
+ Support single key encryption for a folder [0.7.14 20251027 anushkavidanage]
+ Bug fix readPermission [0.7.13 20251008 jesscmoore]
+ Support ACL with 403 return messages [0.7.12 20250926 jesscmoore]
+ AuthManager compatible solid-auth changes [0.7.11 20250924 anushkavidanage]
+ Shared key reading bug fix [0.7.10 20250916 anushkavidanage]
+ Bug fix in key manager [0.7.9 20250815 atangster]
+ Bug fix for default logo/splash images [0.7.8 20250813 anushkavidanage]
+ Improve solid login widget tooltips [0.7.7 20250811 gjw]
+ SHARE: Improve the webid entry experience [0.7.6 20250807 jesscmoore]
+ WEB: Bug fix for utf8 char [0.7.5 20250805 atangster]
+ API deleteDataFile() -> deleteDataFileDialog() [0.7.4 20250728 anushkavidanage]
+ API GrantPermissionUI recipientList -> recipientTypeList [0.7.3 20250725 jesscmoore]
+ Support user typing a WebID in SHARE [0.7.2 20250722 jesscmoore]
+ Add scrolling of the SHARE table [0.7.1 20250722 jesscmoore]
+ Unify readPod and writePod API [0.7.0 20250721 atangster]

## 0.7 Stability

+ Restore login animation [0.6.12 20250719 atangster]
+ Utilise MarkdownTooltip in place of Tooltip in LOGIN [0.6.11 20250718 gjw]
+ Add extra time for the already logged in snackbar [0.6.10 20250714 gjw]
+ Replace login animation with informative snackbar [0.6.9 20250711 atangster]
+ Add Access and Recipient options in `GrantPermissionUI()` [0.6.8 20250702 anushkavidanage]
+ Fix error when cancelling the authentication process [0.6.7 20250613]
+ POD initialisation back button goes back usefully [0.6.6 20250509 atangser]

## [0.6.5 20250430]

+ Bug fixes.
+ Support light/dark mode and GUI updates [atangster]
+ Updated security key prompt [atangster]
+ Fix incorrect filename suffix for unencrypted text files
+ Add APIs to stream data from / to solid server
+ Refactor internal function parseTTL
+ Require log into solid server if refreshing expired access token is failed
+ Update dependencies

## 0.6.4

+ Encrypt large files

## 0.6.3

+ Add POD initialised check

## 0.6.2

+ Update solid_auth to latest version

## 0.6.1

+ Add app directory name as an optional parameter to the `SolidLogin`
  function

## 0.6.0

+ Update Readme with prerequisites for `macos` and `web` [0.5.49]
+ Fix login animation issue [0.5.48]
+ Export function to read permission given by others [0.5.47]
+ Export get resources in a container function [0.5.46]
+ Update dependencies to the latest release [0.5.45]
+ Remove deprecated classes [0.5.44]
+ Remove deprecated functions [0.5.43]
+ Fix loading animation cancel button cut-off issue in Windows [0.5.42]
+ Get solid server URL from the textfield [0.5.41]
+ UI for display permissions given to the user WebID by others [0.5.40]
+ Support the upload, download and delete of large (binary) files [0.5.39]
+ Deploy an example/demo app [0.5.38 20240630]
+ Create ACL file in writePod() if not exist. [0.5.37]
+ Catch any non-null objects thrown in exception handling. [0.5.36]
+ Add read and grant permissions backend and UI. [0.5.35]
+ Deprecate APIs: `updateIndKeyFile` and `getFileContent`. [0.5.34]
+ Check and grant access permissions to data file. [0.5.33]
+ Validate input security keys when changing security key. [0.5.32]
+ Support the use of the same filename to store encrypted/unencrypted data. [0.5.31]
+ Input security key by pressing the enter key. [0.5.30]
+ Add/Delete corresponding individual keys when adding/deleting data files. [0.5.29]
+ Support the read/write of non-encrypted data file. [0.5.28].
+ Refactor POD initialisation code. [0.5.27]
+ Fix security key reloads bug, change button text colour. [0.5.26]
+ Add version number to login screen. [0.5.25]
+ Fix login animation won't disappear in some cases. [0.5.24]
+ Implement API for changing "security key". [0.5.23]
+ Update terminology: Use "security key" instead of "password". [0.5.22]
+ Check and initialise POD in SolidLoginPopup. [0.5.21]
+ Refactor code in rest_api.dart and utils.dart. [0.5.20]
+ Add a logout popup for user to logging out. [0.5.19]
+ Add a changekeyPopup widget to open a popup window for changing the key. [0.5.18]
+ Remove TTL string generation function which should be app specific [0.5.17]
+ Add writePod function and refactor (some part of) the code base [0.5.16]
+ Use the updated token refreshing API from solid-auth-0.1.17 [0.5.15]
+ On Initialise Pod page, added "Show Password" buttons [0.5.14]
+ Catch potential exception when getting tokens [0.5.13]
+ add ButtonStyle class(data structure) to make all buttons customisable [0.5.12]
+ Replace  keypod component with navigator pop. [0.5.11]
+ Replace hardcoded code after clicking the logout button. [0.5.10]
+ Update README for publication [0.5.9]
+ Swap the position of the buttons on the initialisePod() page. [0.5.8]
+ Redesign the initialisePod() page. [0.5.7]
+ Save and retrieve auth data into/from secure storage. [0.5.6]
+ Removed the reset button on initialisePod() page. [0.5.5]
+ Added a cancel button on initialisePod() page. [0.5.4]
+ Fine tune the initialisePod() page. [0.5.3]
+ Add continueBG parameter to SolidLogin. [0.5.2]
+ lib/solid.dart to lib/solidpod.dart [0.5.1]

## 0.5.0

+ Add solidloginPopup widget to open a popup window for
  authentication.

## 0.4.0

+ Rename to `solidpod` as the name `solid` already taken.
+ Add button titles to parameters for SolidLogin() [0.3.1]

## 0.3.0

+ Authentication implemented.
+ SolidLogin() initial version fully functional.

## 0.2.0

+ Initial implementation of SolidLogin widget with parameters.
+ Actual authentication yet to be implemented.
