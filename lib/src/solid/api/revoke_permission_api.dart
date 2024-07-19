/// Removing permission related functions with restful APIs.
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

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';
import 'package:solidpod/src/solid/constants/web_acl.dart';
import 'package:solidpod/src/solid/utils/authdata_manager.dart';
import 'package:solidpod/src/solid/utils/permission.dart';
import 'package:solidpod/src/solid/utils/misc.dart';

/// Remove permission from ALC file by running a Sparql DELETE query
Future<String> removePermissionAcl(String resourceName, String resourceUrl,
    String removerId, RecipientType recipientType,
    [bool fileFlag = true]) async {
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
  final publicPermSet = <AccessMode>{};

  // Authenticated users permission set
  final authUserPermSet = <AccessMode>{};

  // Go through the exisiting permissions, remove the relavant permission,
  // and get the remaining assigned to relevant permission maps
  for (final receiverId in permMap.keys) {
    // Do not change owner permissions. Owner of the file should always have
    // Read, Write, Control permissions to the file
    if (receiverId == ownerWebId || receiverId == 'card#me') {
      continue;
    }

    // If the receiver id matches remover id do not proceed
    if (removerId == receiverId) {
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

  // If RecipientType is group delete the file where the list of webIds are
  // stored
  if (recipientType == RecipientType.group) {
    // Get the file path
    final groupFilePath = [await getDataDirPath(), removerId].join('/');

    // Get the url of the file
    final groupFileUrl = await getFileUrl(groupFilePath);

    await deleteResource(groupFileUrl, ResourceContentType.turtleText);
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

/// Copy shared individual key, either publicly or for all authenticated users
Future<void> removeSharedKeyUserClass(
    String resourceUrl, RecipientType recipientType) async {
  // File contents variables
  var userClassIndKeyFileUrl = '';

  if (recipientType == RecipientType.public) {
    // Get the url of the file
    userClassIndKeyFileUrl = await getFileUrl(await getPubIndKeyPath());
  } else if (recipientType == RecipientType.authUser) {
    // Get the url of the file
    userClassIndKeyFileUrl = await getFileUrl(await getAuthUserIndKeyPath());
  }

  // Check if individual key file exists. If not create a file
  if (await checkResourceStatus(userClassIndKeyFileUrl, fileFlag: false) ==
      ResourceStatus.exist) {
    // Update the existing file using a sparql query
    final prefix = '${solidTermsNS.prefix}: <$appsTerms>';
    final deleteQuery =
        'PREFIX $prefix DELETE {<$resourceUrl> ${solidTermsNS.prefix}:encryptionKey ?o} WHERE {<$resourceUrl> ${solidTermsNS.prefix}:encryptionKey ?o};';

    // Update the file using the insert query
    await updateFileByQuery(userClassIndKeyFileUrl, deleteQuery);
  }
}
