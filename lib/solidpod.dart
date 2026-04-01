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

export 'src/solid/constants/common.dart'
    show foaf, terms, ResourceStatus, permStr, agentStr, whatIsWebID, demoWebID;
export 'src/solid/constants/schema.dart' show appsTerms;
export 'src/solid/constants/path_type.dart' show PathType;

/// Common RDF predicates for Linked Data operations.
/// Includes predicates for RDF, FOAF, ACL, VCard, Dublin Core Terms, and XSD.

export 'src/solid/constants/predicates.dart';

/// Solid authentication function

export 'src/solid/authenticate.dart' show solidAuthenticate;

/// Status class to represent different function outputs

export 'src/solid/solid_func_call_status.dart' show SolidFunctionCallStatus;

/// Includes common functions that are useful such as,
/// - A dialog for deleting an encrypted file
/// - Check POD initialisation status

export 'src/solid/common_func.dart'
    show checkPodInitialization, deleteDataFileDialog;

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
        ResourceNotExistException,
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
        createContainer,
        createDir,
        isPathInCurrentApp,
        validateContainerName,
        isUserLoggedIn,
        deleteLogIn,
        getWebId,
        getDataDirPath,
        getAppNameVersion,
        getTokensForResource,
        getDateTime,
        getEncKeyPath,
        isDir,
        logoutPod,
        registerLogoutCacheCallback,
        setAppDirName,
        silentLogout;

/// Helper for deleting files and containers from a Solid POD

export 'src/solid/utils/delete_helper.dart'
    show deleteContainer, deleteFile, deleteExternalFile, deleteItems;

/// Export auth state management
export 'src/solid/utils/authdata_manager.dart'
    show authStateNotifier, AuthDataManager;

/// Utility functions for generating resource URLs

export 'src/solid/utils/get_url_helper.dart'
    show filenameToResourceUrl, getFileUrl, getDirUrl;

/// Utility functions for generating resources at POD initialisation

export 'src/solid/utils/init_helper.dart'
    show
        clearPodStructureInitialised,
        generateDefaultFolders,
        generateCustomFolders,
        generateDefaultFiles,
        initPod,
        isPodStructureInitialised,
        markPodStructureInitialised;

/// Read encrypted/non-encrypted files stored in a POD

export 'src/solid/read_pod.dart';

/// Read metadata of a resource stored in a POD

export 'src/solid/read_res_metadata.dart';

/// Metadata model

export 'src/solid/utils/res_metadata.dart';

/// Write to encrypted/non-encrypted files in a POD

export 'src/solid/write_pod.dart';

/// The function to grant permission to a resource

export 'src/solid/grant_permission.dart';

/// The function to read permissions given to a resource

export 'src/solid/read_permission.dart';

/// The function to revoke permission from a given resource

export 'src/solid/revoke_permission.dart';

/// Permission types and access control utilities
export 'src/solid/constants/web_acl.dart'
    show
        RecipientType,
        AccessMode,
        getRecipientType,
        getAccessMode,
        publicAgent,
        authenticatedAgent;

/// Functions to upload, download, and delete large file from a Solid server

export 'src/solid/utils/large_file_helper.dart'
    show readLargeFile, readLargeFileAsBytes, writeLargeFile, deleteLargeFile;

/// Helper for downloading multiple files/directories as a zip archive

export 'src/solid/utils/download_helper.dart'
    show downloadItemsAsZip, cleanEncryptedFileName;

/// Data model for zip download operation results

export 'src/solid/models/zip_download_result.dart' show ZipDownloadResult;

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

/// Send notifications to another user's POD

export 'src/solid/send_notification.dart';

/// Data model for POD notifications

export 'src/solid/models/pod_notification.dart' show PodNotification;

/// 20250917 gjw Extras that were required for notepod. Not yet documented.
/// 20251103 jesscmoore In common.dart, only authUserPred is
/// used by notepod

export 'src/solid/constants/common.dart'
    show appDirName, dataDir, profCard, authUserPred, notificationDir;

/// Function to get resources in a user's POD

export 'src/solid/get_resources.dart';

/// Check if a resource exists and has an associated ACL file

export 'src/solid/chk_exists_and_has_acl.dart' show chkExistsAndHasAcl;

/// Retrieve the list of recipients that have access to files in a user's POD

export 'src/solid/get_recipient_list.dart'
    show getRecipientList, extractRecipWebIdList;

/// Read permission history of a resource

export 'src/solid/shared_resource_history.dart' show sharedResourcesHistory;

/// Standardise retrieval of authoriser (owner or granter) for a resource

export 'src/solid/utils/get_authoriser.dart' show getAuthoriser;

/// Data model for permission details

export 'src/solid/models/permission_details.dart' show PermissionDetails;

/// Data model for batch delete operation results

export 'src/solid/models/batch_delete_result.dart' show BatchDeleteResult;

/// Utilities for parsing permission data into the Permission model

export 'src/solid/utils/permission_helper.dart'
    show PermissionHelper, permMapToList;

/// Data model for log records (permission history entries)

export 'src/solid/models/log_record.dart' show LogRecord;

/// Data model for parsed permission entries

export 'src/solid/models/permission.dart' show Permission;
