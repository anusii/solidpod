/// POD connection/auth/upload/encrpytion service.
///
/// Copyright (C) 2023, Software Innovation Institute, ANU.
///
/// License: http://www.apache.org/licenses/LICENSE-2.0
///
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///
/// Authors: Kevin Wang
library;

import 'package:flutter/widgets.dart';

import 'package:solid_auth/solid_auth.dart';

class Constants {
  static const openid = 'openid';
  static const profile = 'profile';
  static const offlineAccess = 'offline_access';
}

class PodService {
  PodService();

  Future<String> getBaseUrl(String url) async {
    final uri = Uri.parse(url);

    // Rebuild the URL with only the scheme and the host.

    return Uri(scheme: uri.scheme, host: uri.host).toString();
  }

  Future<Map<dynamic, dynamic>> authenticatePOD(
    String webId,
    BuildContext context,
  ) async {
    final baseUrl = await getBaseUrl(webId);
    final issuerUri = await getIssuer(baseUrl);
    final scopes = <String>[
      Constants.openid,
      Constants.profile,
      Constants.offlineAccess,
    ];
    final authData = await authenticate(
      Uri.parse(issuerUri),
      scopes,
      context,
    );

    return authData;
  }
}
