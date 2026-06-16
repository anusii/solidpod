/// Functions for the Community Solid Server (CSS) account management JSON API.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:http/http.dart' as http;

import 'package:solidpod/src/solid/utils/exceptions.dart';

/// Headers sent with GET requests to the CSS account API.
///
/// Note: `Content-Type` must NOT be sent on GET requests — CSS attempts to
/// parse the (empty) body as JSON when the header is present and fails with
/// an "Unexpected end of JSON input" internal server error.

const _getHeaders = <String, String>{
  'Accept': 'application/json',
};

/// Headers sent with POST requests (carrying a JSON body) to the CSS
/// account API.

const _postHeaders = <String, String>{
  'Accept': 'application/json',
  'Content-Type': 'application/json',
};

/// Changes the account password on a Community Solid Server (CSS v7+).
///
/// The CSS account management JSON API (served at `<serverUrl>/.account/`) is
/// independent of the app's OIDC session, so the user's account [email] and
/// current password ([oldPassword]) are required to authenticate; existing
/// DPoP/OIDC tokens cannot be used.
///
/// The flow follows the CSS documentation
/// (https://communitysolidserver.github.io/CommunitySolidServer/7.x/usage/account/json-api/):
/// 1. `GET <serverUrl>/.account/` to discover the API `controls`.
/// 2. `POST controls.password.login` with the email and current password to
///    obtain an account authorization token.
/// 3. `GET <serverUrl>/.account/` again with the account token — the
///    `controls` object is now extended with the account-scoped URLs.
/// 4. `GET controls.password.create` to list the account's password logins
///    and find the resource URL for [email].
/// 5. `POST` that resource URL with the old and new passwords.
///
/// [serverUrl] is the base URL of the Solid server,
/// e.g. `https://pods.solidcommunity.au`.
///
/// Throws [CssAccountApiNotSupportedException] when the server does not
/// expose the CSS account API (e.g. NSS, ESS, or CSS older than v7).
/// Throws [CssWrongCredentialsException] when the email or current password
/// is incorrect.
/// Throws a generic [Exception] on other unexpected HTTP or network errors.

Future<void> changeCssAccountPassword({
  required String serverUrl,
  required String email,
  required String oldPassword,
  required String newPassword,
}) async {
  // Step 1: Discover the account API controls.

  final accountIndexUrl =
      '${serverUrl.endsWith('/') ? serverUrl : '$serverUrl/'}.account/';

  http.Response indexResponse;
  try {
    indexResponse = await http.get(
      Uri.parse(accountIndexUrl),
      headers: _getHeaders,
    );
  } on Object catch (e) {
    debugPrint('changeCssAccountPassword() failed to reach $accountIndexUrl:'
        ' $e');
    throw CssAccountApiNotSupportedException(
      'Could not reach the account API at $accountIndexUrl',
    );
  }

  if (indexResponse.statusCode != 200) {
    throw CssAccountApiNotSupportedException(
      'The server does not expose the CSS account API'
      ' (HTTP ${indexResponse.statusCode} for $accountIndexUrl)',
    );
  }

  // The unauthenticated index only exposes the controls available to
  // logged-out users (login, forgot, reset). The account-scoped controls
  // (e.g. `password.create`) only appear when the index is fetched with an
  // account token, so at this point only the login URL is extracted.

  final String? loginUrl;
  try {
    final indexBody = jsonDecode(indexResponse.body) as Map<String, dynamic>;
    final controls = indexBody['controls'] as Map<String, dynamic>?;
    final passwordControls = controls?['password'] as Map<String, dynamic>?;
    loginUrl = passwordControls?['login'] as String?;
  } on Object catch (e) {
    debugPrint('changeCssAccountPassword() failed to parse controls: $e');
    throw CssAccountApiNotSupportedException(
      'Unexpected response from the account API at $accountIndexUrl',
    );
  }

  if (loginUrl == null) {
    throw CssAccountApiNotSupportedException(
      'The server\'s account API does not provide password controls'
      ' (CSS v7+ is required)',
    );
  }

  // Step 2: Log in to the account API with the email and current password to
  // obtain an account authorization token.

  final loginResponse = await http.post(
    Uri.parse(loginUrl),
    headers: _postHeaders,
    body: jsonEncode({'email': email, 'password': oldPassword}),
  );

  if (loginResponse.statusCode == 401 || loginResponse.statusCode == 400) {
    throw CssWrongCredentialsException(
      'The email or current password is incorrect',
    );
  }
  if (loginResponse.statusCode != 200) {
    throw Exception(
      'Account API login failed (HTTP ${loginResponse.statusCode}):'
      ' ${loginResponse.body}',
    );
  }

  final loginBody = jsonDecode(loginResponse.body) as Map<String, dynamic>;
  final accountToken = loginBody['authorization'] as String?;
  if (accountToken == null) {
    throw Exception(
      'Account API login did not return an authorization token',
    );
  }

  final authGetHeaders = <String, String>{
    ..._getHeaders,
    'Authorization': 'CSS-Account-Token $accountToken',
  };

  final authPostHeaders = <String, String>{
    ..._postHeaders,
    'Authorization': 'CSS-Account-Token $accountToken',
  };

  // Step 3: Re-fetch the account API index with the account token. The
  // controls object is now extended with the account-scoped URLs, including
  // `controls.password.create` which lists the password logins.

  final authIndexResponse = await http.get(
    Uri.parse(accountIndexUrl),
    headers: authGetHeaders,
  );

  if (authIndexResponse.statusCode != 200) {
    throw Exception(
      'Failed to fetch the authenticated account API index'
      ' (HTTP ${authIndexResponse.statusCode}): ${authIndexResponse.body}',
    );
  }

  final String? passwordLoginsUrl;
  try {
    final authIndexBody =
        jsonDecode(authIndexResponse.body) as Map<String, dynamic>;
    final authControls = authIndexBody['controls'] as Map<String, dynamic>?;
    final authPasswordControls =
        authControls?['password'] as Map<String, dynamic>?;
    passwordLoginsUrl = authPasswordControls?['create'] as String?;
  } on Object catch (e) {
    debugPrint(
      'changeCssAccountPassword() failed to parse authenticated controls: $e',
    );
    throw CssAccountApiNotSupportedException(
      'Unexpected response from the account API at $accountIndexUrl',
    );
  }

  if (passwordLoginsUrl == null) {
    throw CssAccountApiNotSupportedException(
      'The server\'s account API does not provide password login controls'
      ' (CSS v7+ is required)',
    );
  }

  // Step 4: List the password logins of the account and find the resource
  // URL corresponding to the given email. An account may have multiple
  // email/password logins, so always match by email rather than taking the
  // first entry.

  final loginsResponse = await http.get(
    Uri.parse(passwordLoginsUrl),
    headers: authGetHeaders,
  );

  if (loginsResponse.statusCode != 200) {
    throw Exception(
      'Failed to list password logins'
      ' (HTTP ${loginsResponse.statusCode}): ${loginsResponse.body}',
    );
  }

  final loginsBody = jsonDecode(loginsResponse.body) as Map<String, dynamic>;
  final passwordLogins =
      loginsBody['passwordLogins'] as Map<String, dynamic>? ?? {};

  String? passwordResourceUrl;
  for (final entry in passwordLogins.entries) {
    if (entry.key.toLowerCase() == email.toLowerCase()) {
      passwordResourceUrl = entry.value as String;
      break;
    }
  }

  if (passwordResourceUrl == null) {
    throw Exception(
      'No password login found for "$email" on this account',
    );
  }

  // Step 5: Update the password.

  final updateResponse = await http.post(
    Uri.parse(passwordResourceUrl),
    headers: authPostHeaders,
    body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
  );

  // CSS re-verifies the old password at this step and returns 400/401 when
  // it does not match.

  if (updateResponse.statusCode == 401 || updateResponse.statusCode == 400) {
    throw CssWrongCredentialsException(
      'The current password is incorrect',
    );
  }
  if (updateResponse.statusCode < 200 || updateResponse.statusCode >= 300) {
    throw Exception(
      'Failed to change the password'
      ' (HTTP ${updateResponse.statusCode}): ${updateResponse.body}',
    );
  }
}

/// Creates a new account on a Community Solid Server (CSS v7+).
///
/// The CSS account management JSON API (served at `<serverUrl>/.account/`) is
/// independent of the OIDC authentication flow, so no existing session is
/// required — this function is intended to be called before the user has
/// logged in.
///
/// The flow follows the CSS documentation
/// (https://communitysolidserver.github.io/CommunitySolidServer/7.x/usage/account/json-api/):
/// 1. `GET <serverUrl>/.account/` to discover the API `controls`, specifically
///    `controls.account.create`.
/// 2. `POST controls.account.create` with an empty JSON body to create the
///    bare account and obtain an account authorization token.
/// 3. `GET <serverUrl>/.account/` again with the account token — the
///    `controls` object is now extended with the account-scoped URLs.
/// 4. `POST controls.password.create` with the [email] and [password] to
///    register the email/password login method on the new account.
/// 5. (Optional) If [podName] is supplied, `POST controls.account.pod` with
///    `{"name": podName}` to provision a Pod under the new account. The Pod
///    URL returned by the server is returned from this function.
///
/// [serverUrl] is the base URL of the Solid server,
/// e.g. `https://pods.solidcommunity.au`.
///
/// [podName] is the desired Pod name (the URL path segment). If `null`, no
/// Pod is created and the function returns `null`.
///
/// Returns the Pod URL (e.g. `https://pods.solidcommunity.au/alice/`) when a
/// Pod is created, or `null` when [podName] is omitted.
///
/// Throws [CssAccountApiNotSupportedException] when the server does not
/// expose the CSS account API (e.g. NSS, ESS, or CSS older than v7).
/// Throws [CssEmailAlreadyRegisteredException] when the email is already
/// registered on the server.
/// Throws a generic [Exception] on other unexpected HTTP or network errors.

Future<String?> createCssAccount({
  required String serverUrl,
  required String email,
  required String password,
  String? podName,
}) async {
  // Step 1: Discover the account API controls.

  final accountIndexUrl =
      '${serverUrl.endsWith('/') ? serverUrl : '$serverUrl/'}.account/';

  http.Response indexResponse;
  try {
    indexResponse = await http.get(
      Uri.parse(accountIndexUrl),
      headers: _getHeaders,
    );
  } on Object catch (e) {
    debugPrint('createCssAccount() failed to reach $accountIndexUrl: $e');
    throw CssAccountApiNotSupportedException(
      'Could not reach the account API at $accountIndexUrl',
    );
  }

  if (indexResponse.statusCode != 200) {
    throw CssAccountApiNotSupportedException(
      'The server does not expose the CSS account API'
      ' (HTTP ${indexResponse.statusCode} for $accountIndexUrl)',
    );
  }

  final String? accountCreateUrl;
  try {
    final indexBody = jsonDecode(indexResponse.body) as Map<String, dynamic>;
    final controls = indexBody['controls'] as Map<String, dynamic>?;
    final accountControls = controls?['account'] as Map<String, dynamic>?;
    accountCreateUrl = accountControls?['create'] as String?;
  } on Object catch (e) {
    debugPrint('createCssAccount() failed to parse controls: $e');
    throw CssAccountApiNotSupportedException(
      'Unexpected response from the account API at $accountIndexUrl',
    );
  }

  if (accountCreateUrl == null) {
    throw CssAccountApiNotSupportedException(
      'The server\'s account API does not support account creation'
      ' (CSS v7+ is required)',
    );
  }

  // Step 2: Create the bare account. An empty JSON object body is sent; CSS
  // accepts this as an "empty POST request".

  final createResponse = await http.post(
    Uri.parse(accountCreateUrl),
    headers: _postHeaders,
    body: jsonEncode(<String, dynamic>{}),
  );

  if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
    throw Exception(
      'Account creation failed'
      ' (HTTP ${createResponse.statusCode}): ${createResponse.body}',
    );
  }

  final createBody = jsonDecode(createResponse.body) as Map<String, dynamic>;
  final accountToken = createBody['authorization'] as String?;
  if (accountToken == null) {
    throw Exception(
      'Account creation did not return an authorization token',
    );
  }

  final authGetHeaders = <String, String>{
    ..._getHeaders,
    'Authorization': 'CSS-Account-Token $accountToken',
  };

  final authPostHeaders = <String, String>{
    ..._postHeaders,
    'Authorization': 'CSS-Account-Token $accountToken',
  };

  // Step 3: Re-fetch the account API index with the account token. The
  // controls object is now extended with the account-scoped URLs, including
  // `controls.password.create` which is needed to register the login.

  final authIndexResponse = await http.get(
    Uri.parse(accountIndexUrl),
    headers: authGetHeaders,
  );

  if (authIndexResponse.statusCode != 200) {
    throw Exception(
      'Failed to fetch the authenticated account API index'
      ' (HTTP ${authIndexResponse.statusCode}): ${authIndexResponse.body}',
    );
  }

  final String? passwordCreateUrl;
  final String? podCreateUrl;
  try {
    final authIndexBody =
        jsonDecode(authIndexResponse.body) as Map<String, dynamic>;
    final authControls = authIndexBody['controls'] as Map<String, dynamic>?;
    final authPasswordControls =
        authControls?['password'] as Map<String, dynamic>?;
    final authAccountControls =
        authControls?['account'] as Map<String, dynamic>?;
    passwordCreateUrl = authPasswordControls?['create'] as String?;
    podCreateUrl = authAccountControls?['pod'] as String?;
  } on Object catch (e) {
    debugPrint(
      'createCssAccount() failed to parse authenticated controls: $e',
    );
    throw CssAccountApiNotSupportedException(
      'Unexpected response from the account API at $accountIndexUrl',
    );
  }

  if (passwordCreateUrl == null) {
    throw CssAccountApiNotSupportedException(
      'The server\'s account API does not provide password login controls'
      ' (CSS v7+ is required)',
    );
  }

  // Step 4: Register the email/password login method on the new account.

  final passwordResponse = await http.post(
    Uri.parse(passwordCreateUrl),
    headers: authPostHeaders,
    body: jsonEncode({'email': email, 'password': password}),
  );

  // CSS returns 400 or 409 when the email is already registered.

  if (passwordResponse.statusCode == 400 ||
      passwordResponse.statusCode == 409) {
    throw CssEmailAlreadyRegisteredException(
      'An account with email "$email" is already registered on $serverUrl',
    );
  }
  if (passwordResponse.statusCode < 200 || passwordResponse.statusCode >= 300) {
    throw Exception(
      'Failed to register email/password login'
      ' (HTTP ${passwordResponse.statusCode}): ${passwordResponse.body}',
    );
  }

  // Step 5 (optional): Create a Pod under the new account.

  if (podName == null || podName.isEmpty) return null;

  if (podCreateUrl == null) {
    throw Exception(
      'The server does not support Pod creation via the account API',
    );
  }

  final podResponse = await http.post(
    Uri.parse(podCreateUrl),
    headers: authPostHeaders,
    body: jsonEncode({'name': podName}),
  );

  if (podResponse.statusCode < 200 || podResponse.statusCode >= 300) {
    throw Exception(
      'Failed to create Pod "$podName"'
      ' (HTTP ${podResponse.statusCode}): ${podResponse.body}',
    );
  }

  final podBody = jsonDecode(podResponse.body) as Map<String, dynamic>;
  return podBody['url'] as String?;
}
