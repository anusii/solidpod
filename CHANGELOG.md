# SolidPod Changelog

Recorded here are the high level changes for the SolidPod package.

Guide: Each version update is recorded here with a short user-oriented
description of the update. Updates in the 0.9.n series are heading
toward a 0.10 release. The `[version timestamp user]` string is
utilised by the flutter version_widget package.

Visit the package at [pub.dev](https://pub.dev/packages/solidpod).

## 1.0

+ Bump solid_auth token refresh fix [1.0.6 20260612 gjw]
+ Bug fix for expiring tokens [1.0.5 20260610 anushkavidanage]
+ Notification support [1.0.4 20260609 tonypioneer]
+ Redo public file decryption [1.0.3 20260609 tonypioneer]
+ Fix macOS authentication issue [1.0.2 20260605 tonypioneer]
+ Fix solid popup login [1.0.1 20260604 anushkavidanage]
+ Migration to certified OpenID [1.0.0 20260604 anushkavidanage]

## 0.13

+ Implement checking file encryption [0.12.10 20260527 tonypioneer]
+ Check missing resources [0.12.9 20260520 tonypioneer]
+ Support checking webID [0.12.8 20260520 tonypioneer]
+ Update Try Another WebID workflow [0.12.7 20260520 tonypioneer]
+ Bug fix to ttl rdf for special chars #628 [0.12.6 20260518 tonypioneer]
+ Upgrade solidauth and fix key file saving edge cases [0.12.5 20260427 jesscmoore]
+ Support user profile. [0.12.4 20260421 tonypioneer]
+ Key map + paths updates. Update file_picker. [0.12.3 20260420 jesscmoore]
+ Add silentLogout() [0.12.2 20260325 tonypioneer]
+ Fix logout issue [0.12.1 20260319 av]
+ Fix large file download issue [0.12.1 20260319 av]
+ Restore example app [0.12.1 20260319 tony]

## 0.12 Robust

+ Publish to pub.dev [0.12.0 20260316 gjw]
+ Example app migrated to solidui [0.11.3 20260313 tony]
+ Optimise pod initialisation check [0.11.2 20260219 tony]
+ Update support for SolidFile browser [0.11.1 20260219 tony]
+ Migrated most of remaining UI to solidui [0.11.0 20260213 tony]

## 0.11 Move most UI to solidui

+ Delete file by URL [0.10.5 20260206 dc]
+ Review and lint fixes [0.10.4 20260206 gjw]
+ Permission history updates [0.10.3 20260205 jesscmoore]
+ Corrects granterWebId for externally owned resources [0.10.2 20260205 jesscmoore]
+ Update dependency on solidui to 0.1.0 [0.10.1 20260203 gjw]
+ Migrate Security Key and Permission GUI to solidui [0.10.0 20260203 tonypioneer]

## 0.10 Complete UI migrations - SecurityKey and Permissions

+ Add fetch resource metadata function [0.9.20 20260131 anushkavid]
+ Refactor constants, security, and reactivity [0.9.19 20260131 miduo]
+ Update permission table to list [0.9.18 20260129 jesscmoore]
+ Fixes background of loadingScreen [0.9.17 20260128 jesscmoore]
+ Integrate webid dialogs into grant permission form [0.9.16 20260128 jesscmoore]
+ Optimise shared individual key loading and retrieval [0.9.15 20260128 cdawei]
+ Restored retrieve permissions button [0.9.14 20260125 jesscmoore]
+ Export ResourceNotExistException [0.9.13 20260123 tonypioneer]
+ Move grant permission form to dialog [0.9.12 20260119 jesscmoore]
+ Standardise action message colours [0.9.11 20260116 jesscmoore]
+ Fixed sharing to public/auth users bug [0.9.10 20260115 jesscmoore]
+ Fixed error when reading large file as single chunk [0.9.9 20260117 cdawei]
+ Support custom folder structure [0.9.8 20260114 anushkavid]
+ Restore individual recipient suggestions [0.9.7 20260113 jesscmoore]
+ Allow sharing externally owned files [0.9.6 20260110 jesscmoore]
+ Specify owner and granter webid when sharing files [0.9.5 20260112 jesscmoore]
+ Fixes individual recipient dialog background [0.9.4 20260113 jesscmoore]
+ Fix sharing page heading colours [0.9.3 20260113 jesscmoore]
+ Fixes key creation for encrypting files [0.9.2 20260112 dc]
+ Code cleanup: typos, context checks, remove context/child [0.9.1 20260112 jesscmoore]
+ Updated read/write to remove context and widget [0.9.0 20260108 dc]

## 0.9 Stabilise

+ Enable in-app shared file reload [0.8.7 20251211 anushkavid]
+ Updated dependencies [0.8.6 20251206 gjw]
+ Function to read large file as bytes [0.8.5 20251201 anushkavid]
+ Add PathType to readPod/WritePod [0.8.4 20251123 cdawei]
+ Cleanup and update [0.8.3 20251121 gjw]
+ Allow concurrent pod resource reading [0.8.2 20251117 jesscmoore]
+ Optimise read permission of file list [0.8.2 20251117 jesscmoore]
+ Revoke access on already deleted files [0.8.1 20251117 jesscmoore]
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
+ POD initialisation back button goes back usefully [0.6.6 20250509 atangster]

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
