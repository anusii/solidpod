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
/// Authors: Dawei Chen

library;

import 'dart:convert' show jsonEncode, jsonDecode;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:fast_rsa/fast_rsa.dart' show KeyPair;
import 'package:jwt_decoder/jwt_decoder.dart' show JwtDecoder;
import 'package:solid_auth/solid_auth.dart';
// ignore: implementation_imports
import 'package:solid_auth/src/openid/openid_client.dart'
    show Credential, TokenResponse;

import 'package:solidpod/src/solid/constants/common.dart' show secureStorage;
import 'package:solidpod/src/solid/utils/misc.dart' show writeToSecureStorage;

/// [AuthDataManager] is a class to manage auth data returned by
/// solid-auth authenticate, including:
/// - save auth data to secure storage
/// - load auth data from secure storage
/// - delete saved auth data from secure storage
/// - refresh access token if necessary

class AuthDataManager {
  /// The web ID
  static String? _webId;

  /// The URL for logging out
  static String? _logoutUrl;

  /// The RSA keypair and their JWK format.
  //
  // It seems [String] as the first between the angle brackets does not work
  static Map<dynamic, dynamic>? _rsaInfo;

  /// The authentication response
  static Credential? _authResponse;

  /// The string key for storing auth data in secure storage
  static const String _authDataSecureStorageKey = '_solid_auth_data';

  /// Save the auth data returned by solid-auth authenticate in secure storage
  //
  // It seems [String] as the first between the angle brackets does not work
  static Future<void> saveAuthData(Map<dynamic, dynamic> authData) async {
    const keys = [
      'client',
      'rsaInfo',
      'authResponse',
      'tokenResponse',
      'accessToken',
      'idToken',
      'refreshToken',
      'expiresIn',
      'logoutUrl',
    ];

    for (final key in keys) {
      assert(authData.containsKey(key));
    }

    try {
      // Try to get webid from accessToken first
      Map<String, dynamic> decodedToken = JwtDecoder.decode(authData['accessToken'] as String);
      _webId = decodedToken['webid'] as String?;

      // If not found in accessToken, try idToken
      if (_webId == null) {
        try {
          decodedToken = JwtDecoder.decode(authData['idToken'] as String);
          _webId = decodedToken['webid'] as String?;
        } catch (e) {
          debugPrint('AuthDataManager.saveAuthData() => Failed to decode idToken: $e');
        }
      }

      if (_webId == null || _webId!.isEmpty) {
        debugPrint('AuthDataManager.saveAuthData() => webid not found in accessToken or idToken');
        return;
      }
    } catch (e) {
      debugPrint('AuthDataManager.saveAuthData() => Failed to decode JWT tokens: $e');
      return;
    }

    _logoutUrl = authData['logoutUrl'] as String;
    _rsaInfo = authData['rsaInfo'] as Map<dynamic,
        dynamic>; // Note that use Map<String, dynamic> does not seem to work
    _authResponse = authData['authResponse'] as Credential;

    await writeToSecureStorage(
      _authDataSecureStorageKey,
      jsonEncode({
        'web_id': _webId,
        'logout_url': _logoutUrl,
        'rsa_info': jsonEncode({
          ..._rsaInfo!,
          // Overwrite the 'rsa' keypair in rsaInfo
          'rsa': {
            'public_key': _rsaInfo!['rsa'].publicKey as String,
            'private_key': _rsaInfo!['rsa'].privateKey as String,
          },
        }),
        'auth_response': _authResponse!.toJson(),
      }),
    );

    debugPrint('AuthDataManager => saveAuthData() done');
  }

  /// Retrieve (and reconstruct) auth data from secure storage
  //
  // It seems [String] as the first between the angle brackets does not work
  static Future<Map<dynamic, dynamic>?> loadAuthData() async {
    // First, check if any critical state is null - if so, we're not logged in
    if (_logoutUrl == null || _rsaInfo == null || _authResponse == null || _webId == null) {
      debugPrint('AuthDataManager => loadAuthData() detected null state, attempting reload from storage');
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => loadAuthData() failed - no auth data in storage');
        return null;
      }
    }

    // Double check after loading - if still null, definitely not logged in
    if (_logoutUrl == null || _rsaInfo == null || _authResponse == null || _webId == null) {
      debugPrint('AuthDataManager => loadAuthData() still has null state after reload');
      return null;
    }

    assert(_logoutUrl != null && _rsaInfo != null && _authResponse != null && _webId != null);
    try {
      final tokenResponse = await _getTokenResponse();
      if (tokenResponse == null) {
        throw Exception('Refreshing access token failed');
      }
      return {
        'client': _authResponse!.client,
        'rsaInfo': _rsaInfo,
        'authResponse': _authResponse,
        'tokenResponse': tokenResponse,
        'accessToken': tokenResponse.accessToken,
        'idToken': _authResponse!.idToken,
        'refreshToken': _authResponse!.refreshToken,
        'expiresIn': tokenResponse.expiresIn,
        'logoutUrl': _logoutUrl,
      };
    } on Object catch (e) {
      // Catch any object thrown (Dart programs can throw any non-null object)
      debugPrint('AuthDataManager => loadAuthData() failed: $e');
    }
    return null;
  }

  /// Remove/delete auth data from secure storage
  /// 
  /// This function safely removes authentication data from platform-specific
  /// secure storage. On Flutter Web, FlutterSecureStorage uses SharedPreferences
  /// under the hood, so this is safe and won't throw platform exceptions.
  /// 
  /// Always clears in-memory state variables regardless of storage removal success.
  static Future<bool> removeAuthData() async {
    try {
      // Step 1: Clear from secure storage (platform-specific)
      if (await secureStorage.containsKey(key: _authDataSecureStorageKey)) {
        try {
          await secureStorage.delete(key: _authDataSecureStorageKey);
          debugPrint('AuthDataManager => removeAuthData() removed from secure storage');
        } on Object catch (e) {
          debugPrint('AuthDataManager => removeAuthData() storage removal failed: $e');
          // Continue - memory clearing is still critical
        }
      }

      // Step 2: ALWAYS clear in-memory state (this is the most critical part)
      // Do this regardless of storage removal success
      _webId = null;
      _logoutUrl = null;
      _rsaInfo = null;
      _authResponse = null;
      debugPrint('AuthDataManager => removeAuthData() cleared in-memory state');

      return true;
    } on Object catch (e) {
      // Even if something goes wrong, attempt to null out memory state as fallback
      debugPrint('AuthDataManager => removeAuthData() unexpected error: $e');
      try {
        _webId = null;
        _logoutUrl = null;
        _rsaInfo = null;
        _authResponse = null;
        debugPrint('AuthDataManager => removeAuthData() fallback memory clear succeeded');
      } on Object catch (fallbackError) {
        debugPrint('AuthDataManager => removeAuthData() fallback also failed: $fallbackError');
      }
      return false;
    }
  }

  /// Returns the (refreshed) access token
  static Future<String?> getAccessToken() async {
    final tokenResponse = await _getTokenResponse();
    if (tokenResponse != null) {
      return tokenResponse.accessToken;
    } else {
      debugPrint('AuthDataManager => getAccessToken() failed');
    }
    return null;
  }

  /// Returns the (updated) token response
  static Future<TokenResponse?> _getTokenResponse() async {
    if (_authResponse == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => _getTokenResponse() failed');
        return null;
      }
    }
    assert(_authResponse != null);

    try {
      var tokenResponse = TokenResponse.fromJson(_authResponse!.response!);
      if (JwtDecoder.isExpired(tokenResponse.accessToken!)) {
        // debugPrint(
        //   'AuthDataManager => _getTokenResponse() refreshing expired token',
        // );
        assert(_rsaInfo != null);
        final rsaKeyPair = _rsaInfo!['rsa'] as KeyPair;
        final publicKeyJwk = _rsaInfo!['pubKeyJwk'];
        final tokenEndpoint =
            _authResponse!.client.issuer.metadata['token_endpoint'] as String;
        final dPopToken =
            genDpopToken(tokenEndpoint, rsaKeyPair, publicKeyJwk, 'POST');
        tokenResponse = await _authResponse!
            .getTokenResponse(forceRefresh: true, dPoPToken: dPopToken);
      }
      return tokenResponse;
    } on Object catch (e) {
      debugPrint('AuthDataManager => _getTokenResponse() failed: $e');
    }
    return null;
  }

  /// Returns the web ID
  static Future<String?> getWebId() async {
    if (_webId == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => getWebId() failed');
        return null;
      }
    }
    assert(_webId != null);
    return _webId;
  }

  /// Returns the logout URL
  static Future<String?> getLogoutUrl() async {
    if (_logoutUrl == null) {
      final loaded = await _loadData();
      if (!loaded) {
        debugPrint('AuthDataManager => getLogoutUrl() failed');
        return null;
      }
    }
    assert(_logoutUrl != null);
    return _logoutUrl;
  }

  /// Reconstruct the rsaInfo from JSON string
  static Map<dynamic, dynamic> _getRsaInfo(String rsaJson) {
    final rsaInfo_ = jsonDecode(rsaJson) as Map<String, dynamic>;
    final publicKey = rsaInfo_['rsa']['public_key'] as String;
    final privateKey = rsaInfo_['rsa']['private_key'] as String;

    return {...rsaInfo_, 'rsa': KeyPair(publicKey, privateKey)};
  }

  /// Retrieve auth data from secure storage
  static Future<bool> _loadData() async {
    final dataStr = await secureStorage.read(key: _authDataSecureStorageKey);

    if (dataStr != null) {
      try {
        final dataMap = jsonDecode(dataStr) as Map<String, dynamic>;
        _webId = dataMap['web_id'] as String;
        _logoutUrl = dataMap['logout_url'] as String;
        _rsaInfo = _getRsaInfo(dataMap['rsa_info'] as String);
        _authResponse =
            Credential.fromJson((dataMap['auth_response'] as Map).cast());

        return true;
      } on Object catch (e) {
        debugPrint('AuthDataManager => _loadData() failed: $e');
        return false;
      }
    }
    return false;
  }
}
