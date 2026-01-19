/// Support for flutter apps accessing solid PODs.
///
// Time-stamp: <Wednesday 2025-09-17 08:20:43 +1000 Graham Williams>
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
/// Authors: Graham Williams, Anushka Vidanage

library;

/// Organized constants structure to avoid name conflicts.
/// Use `SolidConstants.namespaces.foaf`, `SolidConstants.directories.data`, etc.
export 'src/solid/constants/solid_constants.dart';

// Legacy exports for backward compatibility (deprecated, use SolidConstants instead)
export 'src/solid/constants/common.dart' show foaf, terms, ResourceStatus;
export 'src/solid/constants/schema.dart' show appsTerms;
export 'src/solid/constants/path_type.dart' show PathType;

/// Solid authentication function

export 'src/solid/authenticate.dart' show solidAuthenticate;

/// UI class to grant permission for a resource

export 'src/solid/grant_permission_ui.dart';

/// UI class to read permission given to the user webID by others

export 'src/solid/shared_resources_ui.dart';

/// Status class to represent different function outputs

export 'src/solid/solid_func_call_status.dart' show SolidFunctionCallStatus;

/// Includes common functions that are useful such as,
/// - A dialog for deleting an encrypted file
/// - Check POD initialisation status

export 'src/solid/common_func.dart'
    show checkPodInitialization, deleteDataFileDialog;

/// Security UI constants including SecurityStrings, SecurityColors, etc.

export 'src/solid/constants/ui.dart'
    show SecurityStrings, SecurityColors, SecurityTextStyles, SecurityLayout;

/// Includes the AppInfo class which stores app specific information
/// such as name, version, canonical name, package name, build number.

export 'src/solid/utils/app_info.dart';

/// Includes the KeyManager class which stores all keys and their parameters
/// such as Security key, Public key, Private key, and Individual keys.
/// Also exports the function to set inherited key for a directory

export 'package:solidpod/src/solid/utils/key_inheritance.dart'
    show setInheritKeyDir;
export 'src/solid/utils/key_manager.dart' show KeyManager;
export 'src/solid/utils/key_helper.dart' show verifySecurityKey;

/// Turtle string to triple map and triple map to turtle string functions
/// Custom exception classes for better error handling.

export 'src/solid/utils/exceptions.dart'
    show
        AccessForbiddenException,
        AccessFailedException,
        NotLoggedInException,
        SecurityKeyNotAvailableException;

/// Includes common TTL conversion functions such as parseTTLMap.

export 'src/solid/utils/rdf.dart' show turtleToTripleMap, tripleMapToTurtle;

/// Includes common functions that could be useful for an app such as
/// - get web id of the user
/// - get path of a directory or file
/// - check whether user is logged in or not
/// - logout from POD
/// - set app directory name
/// - generate default folders and files

export 'src/solid/utils/misc.dart'
    show
        isUserLoggedIn,
        deleteExternalFile,
        deleteFile,
        deleteLogIn,
        getWebId,
        getDataDirPath,
        getAppNameVersion,
        getTokensForResource,
        getDateTime,
        getEncKeyPath,
        logoutPod,
        registerLogoutCacheCallback,
        setAppDirName,
        initPod;

/// Export auth state management
export 'src/solid/utils/authdata_manager.dart'
    show authStateNotifier, AuthDataManager;

/// Utility functions for generating resource URLs

export 'src/solid/utils/get_url_helper.dart'
    show filenameToResourceUrl, getFileUrl, getDirUrl;

/// Utility functions for generating resources at POD initialisation

export 'src/solid/utils/init_pod_gen_resources.dart'
    show generateDefaultFolders, generateCustomFolders, generateDefaultFiles;

/// Change security key popup widget

export 'src/widgets/change_key_dialog.dart';

/// Security key UI widget for prompting and displaying security key dialogs

export 'src/widgets/security_key_ui.dart';

/// Read encrypted/non-encrypted files stored in a POD

export 'src/solid/read_pod.dart';

/// Write to encrypted/non-encrypted files in a POD

export 'src/solid/write_pod.dart';

/// The function to grant permission to a resource

export 'src/solid/grant_permission.dart';

/// The function to read permissions given to a resource

export 'src/solid/read_permission.dart';

/// The function to revoke permission from a given resource

export 'src/solid/revoke_permission.dart';

/// Permission recipient type
export 'src/solid/constants/web_acl.dart' show RecipientType;

/// Functions to upload, download, and delete large file from a Solid server

export 'src/solid/utils/large_file_helper.dart'
    show readLargeFile, readLargeFileAsBytes, writeLargeFile, deleteLargeFile;

/// Function to read permission given to the user webID by others

export 'src/solid/shared_resources.dart';

/// Functions to
/// - check the status of a resource
/// - get resources in a container
/// - test initial structure
/// - update TTL file by SPARQL query

export 'src/solid/api/rest_api.dart'
    show
        checkResourceStatus,
        getResource,
        getResourcesInContainer,
        initialStructureTest,
        updateFileByQuery;

/// Function to get the latest log enties

export 'src/solid/api/common_permission.dart'
    show PermissionLogLiteral, getLatestLog;

/// Reads permissions of list of files in a user's POD

export 'src/solid/read_permission_file_list.dart';

/// Function to revoke permission to a deleted file

export 'src/solid/revoke_permission_to_deleted_file.dart'
    show revokePermissionToDelFile;

/// Read encrypted/non-encrypted files stored in an external POD

export 'src/solid/read_external_pod.dart';

/// Write to encrypted/non-encrypted files in an external POD

export 'src/solid/write_external_pod.dart';

/// 20250917 gjw Extras that were required for notepod. Not yet documented.
/// 20251103 jesscmoore In common.dart, only authUserPred is
/// used by notepod

export 'src/solid/constants/common.dart' show dataDir, profCard, authUserPred;

/// Function to get resources in a user's POD

export 'src/solid/get_resources.dart';

/// 20250917 gjw Extras that were required for the example app! Not yet
/// documented.
