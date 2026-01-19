/// A button for sharing a resource.
///
// Time-stamp: <Sunday 2026-01-19 10:37:02 +1100 Graham Williams>
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
/// Authors: Jess Moore, Anushka Vidanage

library;

import 'dart:core';

import 'package:solidpod/src/solid/utils/authdata_manager.dart';

/// Standardise retrieval of authoriser (ownerWebId or granterWebId)
/// for a resource in GrantPermissionUi
///
/// Parameters:
/// - [isExternalRes] - flag describing whether [fileName] being shared is a file.
/// - [webId] - use webId if provided, else fetch user webId.

Future<String> getAuthoriser({
  bool isExternalRes = false,
  String? webId,
}) async {
  assert(
    // Requires ownerWebId and granterWebId if resource
    // is an externally owned.
    isExternalRes == false || webId != null,
    'webId must be provided if isExternalRes == true',
  );
  return isExternalRes ? webId! : await AuthDataManager.getWebId() as String;
}
