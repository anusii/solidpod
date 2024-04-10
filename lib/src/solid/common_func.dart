/// Common functions used across the package.
///
// Time-stamp: <Friday 2024-02-16 10:59:10 +1100 Graham Williams>
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

import 'package:solidpod/src/solid/constants.dart';

/// Truncates the given [text] to a predefined maximum length.
///
/// If [text] exceeds the length defined by [longStrLength], it is truncated
/// and ends with an ellipsis '...'. If [text] is shorter than [longStrLength],
/// it is returned as is.
///

// comment out the following function as it is not used in the current version
// of the app, anushka might need to use to in the future so keeping it here.

// String truncateString(String text) {
//   var result = '';
//   result = text.length > longStrLength
//       ? '${text.substring(0, longStrLength - 4)}...'
//       : text;

//   return result;
// }

/// Write the given [key], [value] pair to the secure storage.
///
/// If [key] already exisits then delete that first and then
/// write again.

Future<void> writeToSecureStorage(String key, String value) async {
  final isKeyExist = await secureStorage.containsKey(
    key: key,
  );

  // Since write() method does not automatically overwrite an existing value.
  // To overwrite an existing value, call delete() first.

  if (isKeyExist) {
    await secureStorage.delete(
      key: key,
    );
  }

  await secureStorage.write(
    key: key,
    value: value,
  );
}

/// Convert the given [keyPair] object to a map.
///
/// Returns a map with publicKey and privateKey.

// comment out the following function as it is not used in the current version

// Map<String, dynamic> keyPairToMap(KeyPair keyPair) {
//   return {
//     'publicKey': keyPair.publicKey,
//     'privateKey': keyPair.privateKey,
//   };
// }

/// Convert the given [authDataStr] jason string to a map.
///
/// Returns a authentication data map with KeyPair object.

// comment out the following function as it is not used in the current version

// Map<dynamic, dynamic> convertAuthData(String authDataStr) {
//   final authData = jsonDecode(authDataStr);
//   final rsaInfo = authData['rsaInfo'];
//   final rsaKeyPair = KeyPair(rsaInfo['rsa']['publicKey'] as String,
//       rsaInfo['rsa']['privateKey'] as String);
//   rsaInfo['rsa'] = rsaKeyPair;
//   authData['rsaInfo'] = rsaInfo;

//   return authData as Map;
// }
