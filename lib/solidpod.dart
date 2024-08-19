/// Support for flutter apps accessing solid PODs.
///
// Time-stamp: <Monday 2024-04-22 15:19:23 +1000 Graham Williams>
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
/// Authors: Graham Williams, Anushka Vidanage

library solidpod;

// Solid server login UI class and its corresponding button style classes
export 'src/solid/login.dart'
    show
        SolidLogin,
        LoginButtonStyle,
        ContinueButtonStyle,
        RegisterButtonStyle,
        InfoButtonStyle;

// Solid server login popup class
export 'src/solid/popup_login.dart' show SolidPopupLogin;

// UI class to grant permission for a resource
export 'src/solid/grant_permission_ui.dart' show GrantPermissionUi;

// UI class to read permission given to the user webID by others
export 'src/solid/shared_resources_ui.dart' show SharedResourcesUi;

// Status class to represent different function outputs
export 'src/solid/solid_func_call_status.dart' show SolidFunctionCallStatus;

// Includes common functions that are useful such as,
// - Deleting an encrypted file
// - Check whether login tokens are expired and if they are ridirect to login
// - Check whether initialisation is required
export 'src/solid/common_func.dart';

// Includes the AppInfo class which stores app specific information
// such as name, version, canonical name, package name, build number.
export 'src/solid/utils/app_info.dart' show AppInfo;

// Includes the KeyManager class which stores all keys and their parameters
// such as Security key, Public key, Private key, and Individual keys.
export 'src/solid/utils/key_helper.dart' show KeyManager;

// Includes common functions that could be useful for an app such as
// get web id of the user, get path of a directory or file,
export 'src/solid/utils/misc.dart';

// Change security key popup widget
export 'src/widgets/change_key_dialog.dart' show changeKeyPopup;

// Read encrypted/non-encrypted files stored in a POD
export 'src/solid/read_pod.dart' show readPod;

// Write to encrypted/non-encrypted files in a POD
export 'src/solid/write_pod.dart' show writePod;

// Popup widget for logging out from a POD
export 'src/widgets/logout_dialog.dart' show logoutPopup;

// The function to grant permission to a resource
export 'src/solid/grant_permission.dart' show grantPermission;

// The function to read permissions given to a resource
export 'src/solid/read_permission.dart' show readPermission;

// The function to revoke permission from a given resource
export 'src/solid/revoke_permission.dart' show revokePermission;

// Functions to upload, download, and delete large file from a Solid server
export 'src/solid/utils/large_file_helper.dart'
    show sendLargeFile, getLargeFile, deleteLargeFile;

// Function to read permission given to the user webID by others
export 'src/solid/shared_resources.dart' show sharedResources;

// Function to get resources in a container
export 'src/solid/api/rest_api.dart' show getResourcesInContainer;

// Function to get the latest log enties
export 'src/solid/api/common_permission.dart' show getLatestLog;
