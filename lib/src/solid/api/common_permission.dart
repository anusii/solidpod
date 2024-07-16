/// Common Permission related functions.
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

library;

import 'package:intl/intl.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';

import 'package:solidpod/src/solid/constants/common.dart';
import 'package:solidpod/src/solid/constants/schema.dart';

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