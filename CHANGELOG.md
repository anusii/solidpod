# SolidPod Package Changelog

Recorded here are the high level changes for the SolidPod package.

Instructions: Add the updates beyond, for example, 0.5.0 under the 0.6
heading, adding to the top of the list, and recording minor version
numbers.

## 0.6 Future Release

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

## 0.5

+ Add solidloginPopup widget to open a popup window for
  authentication.

## 0.4
  
+ Rename to `solidpod` as the name `solid` already taken.
+ Add button titles to parameters for SolidLogin() [0.3.1]

## 0.3

+ Authentication implemented.
+ SolidLogin() initial version fully functional.

## 0.2

+ Initial implementation of SolidLogin widget with parameters.
+ Actual authentication yet to be implemented.
