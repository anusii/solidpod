/// Data model for record part of a log entry into permission log.
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
/// Authors: Jess Moore

library;

/// Data model for log record data in each log entry in the permission log
/// in a Pod
/// /// '$dateTimeStr;$resourceUrl;$ownerWebId;$permissionType;$granterWebId;$recipientWebId;${permissionListStr.toLowerCase()}'
///

class LogRecord {
  final String dateTimeStr; // Change to date format?
  final String resourceUrl;
  final String ownerWebId;
  final String permissionType;
  final String granterWebId;
  final String recipientWebId;
  final List<String> permissionList; // List or string
  final String? constraints;

  const LogRecord({
    required this.dateTimeStr,
    required this.resourceUrl,
    required this.ownerWebId,
    required this.permissionType,
    required this.granterWebId,
    required this.recipientWebId,
    required this.permissionList,
    this.constraints,
  });
}
