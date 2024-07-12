/// Permission related functions with  restful APIs.
///
// Time-stamp: <Friday 2024-07-03 14:41:20 +1100 Anushka Vidanage>
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
/// Authors: Anushka Vidanage

// ignore_for_file: comment_references

library;

import 'package:encrypt/encrypt.dart';
import 'package:intl/intl.dart';
import 'package:rdflib/rdflib.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/permission.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Sets the permission for a specific resource.
///
/// This method sends a request to the REST API to
/// set the permission for a resource.
/// It returns a Future that resolves to a String
/// representing the result of the operation.
Future<String> setPermissionAcl(String resourceUrl, RecipientType recipientType,
    List<dynamic> recipientWebIdList, List<dynamic> permissionList,
    [String? groupName, bool fileFlag = true]) async {
  // Read acl content
  final aclContent = await readAcl(resourceUrl);

  // Extract permission details to a map
  final permMap = extractAclPerm(aclContent);

  final ownerWebId = await AuthDataManager.getWebId();

  // Updated individual permission map
  final updatedIndPermMap = <String, Set<AccessMode>>{};

  // Updated group permission map
  final updatedGroupPermMap = <String, Set<AccessMode>>{};

  // Public permission set
  var publicPermSet = <AccessMode>{};

  // Authenticated users permission set
  var authUserPermSet = <AccessMode>{};

  // Go through the exisiting permissions and get those assigned to relevant
  // permission maps
  for (final receiverId in permMap.keys) {
    // Do not change owner permissions. Owner of the file should always have
    // Read, Write, Control permissions to the file
    if (receiverId == ownerWebId || receiverId == 'card#me') {
      continue;
    }

    final agentType = permMap[receiverId][agentStr];
    final permList = permMap[receiverId][permStr] as List;

    if (agentType == agentClassPred) {
      if (URIRef(receiverId as String) == publicAgent) {
        for (final permStr in permList) {
          publicPermSet.add(getAccessMode(permStr as String));
        }
      } else if (URIRef(receiverId) == authenticatedAgent) {
        for (final permStr in permList) {
          authUserPermSet.add(getAccessMode(permStr as String));
        }
      }
    } else {
      final permSet = <AccessMode>{};
      for (final permStr in permList) {
        permSet.add(getAccessMode(permStr as String));
      }
      if (agentType == agentGroupPred) {
        updatedGroupPermMap[receiverId as String] = permSet;
      } else {
        updatedIndPermMap[receiverId as String] = permSet;
      }
    }
  }

  // Add new permissions to the relevant group
  // create new permission set
  final newPermSet = <AccessMode>{};
  for (final permStr in permissionList) {
    newPermSet.add(getAccessMode(permStr as String));
  }

  // if the permission recipient is public
  if (recipientType == RecipientType.public) {
    publicPermSet = newPermSet;
  }

  // if the permission recipient is authenticated users
  if (recipientType == RecipientType.authUser) {
    authUserPermSet = newPermSet;
  }

  // if the permission recipient is a single WebID
  if (recipientType == RecipientType.individual) {
    updatedIndPermMap[recipientWebIdList.first as String] = newPermSet;
  }

  // if the permission recipient is a group of WebIDs
  if (recipientType == RecipientType.group) {
    final groupFileName = '${groupName!.replaceAll(' ', '-')}.ttl';
    updatedGroupPermMap[groupFileName] = newPermSet;

    // In the case of group of WebIDs, we also need to create a ttl file
    // to store all the WebIDs in that group

    // Get the file path
    final groupFilePath = [await getDataDirPath(), groupFileName].join('/');

    // Get the url of the file
    final groupFileUrl = await getFileUrl(groupFilePath);

    final groupFileContent = await genGroupWebIdTTLStr(recipientWebIdList);

    await createResource(
      groupFileUrl,
      content: groupFileContent,
      replaceIfExist: true,
    );
  }

  final aclFullContentStr = await genAclTurtle(resourceUrl,
      fileFlag: fileFlag,
      ownerAccess: {AccessMode.read, AccessMode.write, AccessMode.control},
      publicAccess: publicPermSet,
      authUserAccess: authUserPermSet,
      thirdPartyAccess: updatedIndPermMap,
      groupAccess: updatedGroupPermMap);

  final updateRes = await updateAclFileContent(resourceUrl, aclFullContentStr);

  return updateRes;
}

/// Create a shared file on recepient's POD.
/// Copy encrypted shared key, shared file path, and acess list to this file
Future<void> copySharedKey(String receiverWebId, String resUniqueId,
    String encSharedKey, String encSharedPath, String encSharedAccess) async {
  /// Get shared key file url.
  final sharedKeyFilePath = await getSharedKeyFilePath();
  final receiverSharedKeyFileUrl =
      receiverWebId.replaceAll(profCard, sharedKeyFilePath);

  /// Create file if not exists
  if (await checkResourceStatus(receiverSharedKeyFileUrl, fileFlag: false) ==
      ResourceStatus.notExist) {
    final keyFileBody =
        '@prefix $selfPrefix <#>.\n@prefix $foafPrefix <$httpFoaf>.\n@prefix $termsPrefix <$httpDcTerms>.\n@prefix $resIdPrefix <$appsResId>.\n@prefix $dataPrefix <$appsData>.\n${selfPrefix}me\n    a $foafPrefix$profileDoc;\n    $termsPrefix$titlePred "Shared Encryption Keys".\n$resIdPrefix$resUniqueId\n    $dataPrefix$pathPred "$encSharedPath";\n    $dataPrefix$accessListPred "$encSharedAccess";\n    $dataPrefix$sharedKeyPred "$encSharedKey".';

    /// Update the ttl file with the shared info
    await createResource(
      receiverSharedKeyFileUrl,
      content: keyFileBody,
    );
  } else {
    /// Update the file

    /// First check if the file already contain the same value
    final keyFileContent = await fetchPrvFile(receiverSharedKeyFileUrl);
    final keyFileDataMap = getEncFileContent(keyFileContent);

    /// Define query parameters
    const prefix1 = '$resIdPrefix <$appsResId>';
    const prefix2 = '$dataPrefix <$appsData>';

    final subject = '$resIdPrefix$resUniqueId';
    final predObjPath = '$dataPrefix$pathPred "$encSharedPath";';
    final predObjAcc = '$dataPrefix$accessListPred "$encSharedAccess";';
    final predObjKey = '$dataPrefix$sharedKeyPred "$encSharedKey".';

    /// Check if the resource is previously added or not
    if (keyFileDataMap.containsKey(resUniqueId)) {
      final existKey = keyFileDataMap[resUniqueId][sharedKeyPred];
      final existPath = keyFileDataMap[resUniqueId][pathPred];
      final existAcc = keyFileDataMap[resUniqueId][accessListPred];

      /// If file does not contain the same encrypted value then delete and update
      /// the file
      /// NOTE: Public key encryption generates different hashes different time for same plaintext value
      /// Therefore this always ends up deleting the previous and adding a new hash
      if (existKey != encSharedKey ||
          existPath != encSharedPath ||
          existAcc != encSharedAccess) {
        final predObjPathPrev = '$dataPrefix$pathPred "$existPath";';
        final predObjAccPrev = '$dataPrefix$accessListPred "$existAcc";';
        final predObjKeyPrev = '$dataPrefix$sharedKeyPred "$existKey".';

        // Generate update sparql query
        final updateQuery =
            'PREFIX $prefix1 PREFIX $prefix2 DELETE DATA {$subject $predObjPathPrev $predObjAccPrev $predObjKeyPrev}; INSERT DATA {$subject $predObjPath $predObjAcc $predObjKey};';

        // Update the file using the update query
        await updateFileByQuery(receiverSharedKeyFileUrl, updateQuery);
      }
    } else {
      /// Generate insert only sparql query
      final insertQuery =
          'PREFIX $prefix1 PREFIX $prefix2 INSERT DATA {$subject $predObjPath $predObjAcc $predObjKey};';

      // Update the file using the insert query
      await updateFileByQuery(receiverSharedKeyFileUrl, insertQuery);
    }
  }
}

/// Copy shared individual key, either publicly or for all authenticated users
Future<void> copySharedKeyUserClass(Key indKey, String resourceUrl,
    List<dynamic> permissionList, RecipientType recipientType) async {
  // File contents variables
  var userClassIndKeyFileUrl = '';
  var aclContentStr = '';

  if (recipientType == RecipientType.public) {
    // Get the url of the file
    userClassIndKeyFileUrl = await getFileUrl(await getPubIndKeyPath());

    // Create ACL content for the file
    aclContentStr = await genAclTurtle(userClassIndKeyFileUrl,
        ownerAccess: {AccessMode.read, AccessMode.write, AccessMode.control},
        publicAccess: {AccessMode.read});
  } else if (recipientType == RecipientType.authUser) {
    // Get the url of the file
    userClassIndKeyFileUrl = await getFileUrl(await getAuthUserIndKeyPath());

    // Create ACL content for the file
    aclContentStr = await genAclTurtle(userClassIndKeyFileUrl,
        ownerAccess: {AccessMode.read, AccessMode.write, AccessMode.control},
        authUserAccess: {AccessMode.read});
  }

  // Check if individual key file exists. If not create a file
  if (await checkResourceStatus(userClassIndKeyFileUrl, fileFlag: false) ==
      ResourceStatus.notExist) {
    // If file does not exist create a ttl file
    final userClassIndKeyFileContent = await genUserClassIndKeyTTLStr([
      resourceUrl,
      indKey.base64,
    ]);

    await createResource(
      userClassIndKeyFileUrl,
      content: userClassIndKeyFileContent,
    );

    // Also create a corresponding acl file
    await createResource(
      '$userClassIndKeyFileUrl.acl',
      content: aclContentStr,
      replaceIfExist: true,
    );
  } else {
    // Update the existing file using a sparql query
    final prefix = '${solidTermsNS.prefix}: <$appsTerms>';
    final insertQuery =
        'PREFIX $prefix INSERT DATA {<$resourceUrl> ${solidTermsNS.prefix}:sessionKey "${indKey.base64}"};';

    // Update the file using the insert query
    await updateFileByQuery(userClassIndKeyFileUrl, insertQuery);
  }
}

/// Remove permission from ALC file by running a Sparql DELETE query
Future<String> removePermissionAcl(
    String resourceName, String resourceUrl, String removerWebId) async {
  // Read acl content
  final aclContent = await readAcl(resourceUrl);

  // A map to store new acl content
  final updatedAclContentMap = {};

  // Go through the current acl content remove the [removerWebId]
  // from the content
  for (final accessStr in aclContent.keys) {
    final webIdList = aclContent[accessStr][agentPred] as List;

    if (webIdList.contains(removerWebId)) {
      webIdList.remove(removerWebId);
    }

    if (webIdList.isNotEmpty) {
      updatedAclContentMap[accessStr] = aclContent[accessStr];
    }
  }

  final aclFullContentStr = createAclConectStr(updatedAclContentMap);

  final updateRes = await updateAclFileContent(resourceUrl, aclFullContentStr);

  return updateRes;
}

/// Delete shared key on recepient's POD.
Future<void> removeSharedKey(String removerWebId, String resUniqueId) async {
  // Get shared key file url.
  final sharedKeyFilePath = await getSharedKeyFilePath();
  final receiverSharedKeyFileUrl =
      removerWebId.replaceAll(profCard, sharedKeyFilePath);

  // Check if the shared key file exists
  if (await checkResourceStatus(receiverSharedKeyFileUrl, fileFlag: false) ==
      ResourceStatus.exist) {
    // Update the file

    // Check if the file contains the shared key values for the given resource
    final keyFileContent = await fetchPrvFile(receiverSharedKeyFileUrl);
    final keyFileDataMap = getEncFileContent(keyFileContent);

    if (keyFileDataMap.containsKey(resUniqueId)) {
      // Define query parameters
      const prefix1 = '$resIdPrefix <$appsResId>';
      const prefix2 = '$dataPrefix <$appsData>';
      final subject = '$resIdPrefix$resUniqueId';

      // Get existing values
      final existKey = keyFileDataMap[resUniqueId][sharedKeyPred];
      final existPath = keyFileDataMap[resUniqueId][pathPred];
      final existAcc = keyFileDataMap[resUniqueId][accessListPred];

      // Define predicates and objects
      final predObjPath = '$dataPrefix$pathPred "$existPath";';
      final predObjAcc = '$dataPrefix$accessListPred "$existAcc";';
      final predObjKey = '$dataPrefix$sharedKeyPred "$existKey".';

      // Generate delete sparql query
      final deleteQuery =
          'PREFIX $prefix1 PREFIX $prefix2 DELETE DATA {$subject $predObjPath $predObjAcc $predObjKey};';

      // Update the file using the update query
      await updateFileByQuery(receiverSharedKeyFileUrl, deleteQuery);
    }
  }
}

/// From a given ACL content map create the ACL body string
///
/// Returns the acl body content as a single string value
String createAclConectStr(Map<dynamic, dynamic> aclContentMap) {
  // Generate ACL file content string from the permissions

  var aclPrefixStr =
      '''@prefix $selfPrefix <#>.\n@prefix $aclPrefix <$acl>.\n@prefix $foafPrefix <$foaf>.\n''';
  var aclBodyStr = '';

  // increment variable for webId prefixes
  var i = 0;

  // Go through the new acl content and create relevant prefix Strings and body entry Strings
  for (final accessStr in aclContentMap.keys) {
    final webIdList = aclContentMap[accessStr][agentPred] as List;
    final resourceName = aclContentMap[accessStr][accessToPred].first;
    final accessList = aclContentMap[accessStr][modePred] as List;

    final agentList = [];
    final accessModeList = [];

    for (final webId in webIdList) {
      final webIdPrefix = '@prefix c$i: <${webId.replaceAll('me', '')}>.';
      agentList.add('c$i:me');

      aclPrefixStr += '$webIdPrefix\n';
      i += 1;
    }

    for (final accessMode in accessList) {
      accessModeList.add('$aclPrefix$accessMode');
    }

    final agentStr = agentList.join(', ');
    final accessModeStr = accessModeList.join(', ');

    aclBodyStr +=
        ':$accessStr\n    a $aclPrefix$aclAuth;\n    $aclPrefix$accessToPred <$resourceName>;\n    $aclPrefix$agentPred $agentStr;\n    $aclPrefix$modePred $accessModeStr.\n';
  }

  // Combine prefixes and body entries into a single String
  final aclFullContentStr = '$aclPrefixStr\n$aclBodyStr';

  return aclFullContentStr;
}

/// Create a log entry for permission
/// A log entry consists of 7 values
///   - dateTimeStr: Permission granted/revoked date and time
///   - resourceUrl: URL of the resource that is being shared/un-shared
///   - ownerWebId: WebID of the resource owner
///   - permissionType: Type of permission (grant/revoke)
///   - granterWebId: WebID of the person who is giving/revoking permission
///   - recepientWebId: WebID of the person who is reveiving permission
///   - permissionList: List of access types (Read, Write, Control, Append)
///
/// Returns the log entry ID and the log entry string
List<dynamic> createPermLogEntry(
  List<dynamic> permissionList,
  String resourceUrl,
  String ownerWebId,
  String permissionType,
  String granterWebId,
  String recepientWebId,
) {
  final permissionListStr = permissionList.join(',');
  final dateTimeStr = DateFormat('yyyyMMddTHHmmss').format(DateTime.now());
  final logEntryId = DateFormat('yyyyMMddTHHmmssSSS').format(DateTime.now());
  final logEntryStr =
      '$dateTimeStr;$resourceUrl;$ownerWebId;$permissionType;$granterWebId;$recepientWebId;${permissionListStr.toLowerCase()}';

  return [logEntryId, logEntryStr];
}

/// Add permission log line to the log file
Future<void> addPermLogLine(
  String logFileUrl,
  String logEntryId,
  String logEntryStr,
) async {
  // Generate insert sparql query for log entry
  const prefix1 = '$logIdPrefix <$appsLogId>';
  const prefix2 = '$dataPrefix <$appsData>';
  final insertQuery =
      'PREFIX $prefix1 PREFIX $prefix2 INSERT DATA {$logIdPrefix$logEntryId ${dataPrefix}log "<$logEntryStr>"};';

  // Update the file using the insert query
  await updateFileByQuery(logFileUrl, insertQuery);
}
