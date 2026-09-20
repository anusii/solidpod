/// Choose keychain options that this macOS build is actually allowed to use.
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
/// Authors: Graham Williams
library;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_io/io.dart' show Platform;

import 'package:solidpod/src/solid/constants/common.dart' show secureStorage;

/// The key written and removed again by the probe below. Named so that anyone
/// finding it in a keychain knows what left it there.

const _probeKey = '_solidpod_keychain_probe';

/// Which macOS keychain each candidate reaches, for the log line.

const _candidateNames = ['legacy keychain', 'data protection keychain'];

/// The option sets to try, in the order preferred.
///
/// The first avoids the data protection keychain, which is only available to
/// an app holding a keychain access group — from the `keychain-access-groups`
/// entitlement, or the `com.apple.application-identifier` that an embedded
/// provisioning profile supplies. A Developer ID build has neither, and its
/// keychain calls fail with errSecMissingEntitlement (-34018), taking the
/// security key and the DPoP key with them. `kSecAttrAccessible` is dropped
/// along with it: that attribute is documented as available on macOS only
/// when the data protection keychain is in use, and it is the remaining
/// suspect for a -34018 that survives turning that keychain off.
///
/// The second is the plugin default, which is right for a sandboxed App Store
/// build: it ships a provisioning profile, so the data protection keychain is
/// available and its at-rest guarantees are worth having.

const _candidates = [
  MacOsOptions(accessibility: null, usesDataProtectionKeychain: false),
  MacOsOptions(),
];

var _probed = false;

/// Points [secureStorage] at keychain options this build can actually use.
///
/// Only macOS needs this: every other platform has one working configuration.
/// Each candidate is tried with a real write and delete, because the keychain
/// refuses at the point of use rather than on construction, and the first that
/// succeeds is installed for the life of the process. The chosen option set is
/// logged, so a failure in the field says which keychain was in play instead
/// of leaving it to be inferred.
///
/// Called before the first secret is stored. Leaves [secureStorage] untouched
/// when nothing works, so the error surfaces from the real call site as it
/// does today rather than being swallowed here.

Future<void> chooseSecureStorageOptions() async {
  if (_probed || kIsWeb || !Platform.isMacOS) return;

  _probed = true;

  for (var i = 0; i < _candidates.length; i++) {
    final candidate = FlutterSecureStorage(
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: _candidates[i],
      webOptions: const WebOptions(useSessionStorage: true),
    );

    try {
      await candidate.write(key: _probeKey, value: 'probe');
      await candidate.delete(key: _probeKey);

      secureStorage = candidate;

      debugPrint('solidpod: keychain using the ${_candidateNames[i]}');

      return;
    } on Object catch (e) {
      debugPrint('solidpod: ${_candidateNames[i]} unusable: $e');
    }
  }

  debugPrint(
    'solidpod: no usable macOS keychain, secrets will not persist. '
    'A Developer ID build needs an embedded provisioning profile to reach '
    'the data protection keychain.',
  );
}
