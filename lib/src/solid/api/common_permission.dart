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

/// A class to represent permission log literals
enum PermissionLogLiteral {
  /// Log datetime
  logtime('logtime'),

  /// Url of the resource being shared
  resource('resource'),

  /// Resource owner webID
  owner('owner'),

  /// Granter webID
  granter('granter'),

  /// Recepient webID
  recepient('recepient'),

  /// Permission type
  type('type'),

  /// Set of permissions received
  permissions('permissions');

  /// Generative enum constructor
  const PermissionLogLiteral(this._value);

  /// String label of data type
  final String _value;

  /// Return the string value of data type
  String get label => _value;
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

/// Get latest log entries
Map<dynamic, dynamic> getLatestLog(Map<dynamic, dynamic> logDataMap,
    [String? userWebId]) {
  final uniqueLogMap = <dynamic, dynamic>{};

  // Loop through logs and get the latest for each resource
  for (final dataKey in logDataMap.keys) {
    if ((dataKey as String).contains(appsLogId)) {
      final logEntry = logDataMap[dataKey]['${appsData}log'].first;
      final logEntryList = logEntry.split(';');

      final ownerWebId = logEntryList[2];

      if (userWebId != null) {
        if (ownerWebId == userWebId) {
          continue;
        }
      }

      final resoruceUrl = logEntryList[1];
      var replaceExist = false;

      if (uniqueLogMap.containsKey(resoruceUrl)) {
        final prevDateTime =
            uniqueLogMap[resoruceUrl][PermissionLogLiteral.logtime];
        if ([0, 1].contains(DateTime.parse(logEntryList.first as String)
            .compareTo(DateTime.parse(prevDateTime as String)))) {
          replaceExist = true;
        }
      } else {
        replaceExist = true;
      }

      if (replaceExist) {
        uniqueLogMap[resoruceUrl] = {
          PermissionLogLiteral.logtime: logEntryList.first,
          PermissionLogLiteral.resource: resoruceUrl,
          PermissionLogLiteral.owner: logEntryList[2],
          PermissionLogLiteral.granter: logEntryList[4],
          PermissionLogLiteral.recepient: logEntryList[5],
          PermissionLogLiteral.type: logEntryList[3],
          PermissionLogLiteral.permissions: logEntryList[6]
        };
      }
    }
  }

  return uniqueLogMap;
}

/// Filter log entries by file name
Map<dynamic, dynamic> filterLogByFilename(
    Map<dynamic, dynamic> logMap, String fileName) {
  final filteredLogMap = {};
  for (final fileUrl in logMap.keys) {
    if ((fileUrl as String).contains(fileName)) {
      filteredLogMap[fileUrl] = logMap[fileUrl];
    }
  }
  return filteredLogMap;
}

/// Filter log entries by file name
Map<dynamic, dynamic> filterLogByWebId(
    Map<dynamic, dynamic> logMap, String webId) {
  final filteredLogMap = {};
  for (final logEntry in logMap.entries) {
    if (logEntry.value[PermissionLogLiteral.owner] == webId) {
      filteredLogMap[logEntry.key] = logEntry.value;
    }
  }
  return filteredLogMap;
}
