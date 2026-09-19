/// Common constants used across the package.
///
// Time-stamp: <Thursday 2025-10-23 20:42:26 +1100 Graham Williams>
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

// ignore_for_file: public_member_api_docs

library;

import 'package:flutter/services.dart' show PlatformException;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Length limit for long strings for a screen.

// const int longStrLength = 12;

/// Setup app data directory name
String appDirName = '';

/// String terms used for files created and used inside a POD.

const String encKeyFile = 'enc-keys.ttl';
const String pubKeyFile = 'public-key.ttl';
const String indKeyFile = 'ind-keys.ttl';
const String permLogFile = 'permissions-log.ttl';
const String sharedKeyFile = 'shared-keys.ttl';
const String pubIndKeyFile = 'public-ind-keys.ttl';
const String authUserIndKeyFile = 'auth-user-ind-keys.ttl';

const dataDir = 'data';
const sharingDir = 'sharing';
const sharedDir = 'shared';
const encDir = 'encryption';
const logsDir = 'logs';
const notificationDir = 'notifications';
const profileDir = 'profile';

/// Avatar resource. Stored as a turtle file so the same resource can hold
/// either an unencrypted base64-wrapped image (when the user opts to make
/// their profile public) or the encrypted form produced by `writePod()`
/// (the default for an app using encryption).

const String profilePictureFile = 'avatar.ttl';

/// Display name resource. Always stored as linked data so that other apps
/// and queries can interpret it via FOAF/VCard predicates.

const String displayNameFile = 'display-name.ttl';

/// String terms used as predicates in ttl files.

const String profCard = 'profile/card#me';
const String ivPred = 'iv';
const String titlePred = 'title';
const String prvKeyPred = 'prvKey';
const String pubKeyPred = 'pubKey';
const String encKeyPred = 'encKey'; // verification key of the master key
const String saltPred = 'salt'; // salt for the key-derivation function
const String keyVersionPred = 'keyVersion'; // key-derivation scheme version
const String pathPred = 'path';
const String accessListPred = 'accessList';
const String filePathListPred = 'filePathList';
const String authUserPred = 'authUserList';
const String sharedKeyPred = 'sharedKey';
const String sessionKeyPred = 'sessionKey';
const String encDataPred = 'encData';
const String inheritKeyPred = 'inheritKeyFrom';
const String typePred = 'type';
// const String accessToPred = 'accessTo';
const String agentPred = 'agent';
const String agentGroupPred = 'agentGroup';
const String modePred = 'mode';
const String agentClassPred = 'agentClass';
// const String createdDateTimePred = 'createdDateTime';
// const String modifiedDateTimePred = 'modifiedDateTime';
// const String noteTitlePred = 'noteTitle';
// const String encNoteContentPred = 'encNoteContent';
// const String noteFileNamePrefix = 'note-';

/// ACL file map strings
const String permStr = 'permissions';
const String agentStr = 'agentType';

/// String terms used as values in ttl files.

// const String aclAuth = 'Authorization';
// const String aclRead = 'Read';
// const String aclWrite = 'Write';
// const String aclAppend = 'Append';
// const String aclControl = 'Control';
// const String aclAgent = 'Agent';
// const String aclAuthAgent = 'AuthenticatedAgent';
// const String aclDefault = 'default';
const String profileDoc = 'PersonalProfileDocument';

// Resource metadata labels
const String contentLength = 'content-length';
const String contentType = 'content-type';
const String lastModified = 'last-modified';
const String lastAccessed = 'date';
const String eTag = 'etag';
const String acceptPatch = 'accept-patch';
const String wacAllow = 'wac-allow';

/// String link variables used in files generation process for defining ttl
/// file content.

const String acl = 'http://www.w3.org/ns/auth/acl#';
const String foaf = 'http://xmlns.com/foaf/0.1/';
// const String ldp = 'http://www.w3.org/ns/ldp#';
const String rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
// const String rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
const String terms = 'http://purl.org/dc/terms/';
const String vcard = 'http://www.w3.org/2006/vcard/ns#';
const String xsd = 'http://www.w3.org/2001/XMLSchema#';
const String pubAgent = 'http://xmlns.com/foaf/0.1/' 'Agent';
const String authAgent = 'http://www.w3.org/ns/auth/acl#'
    'AuthenticatedAgent'; // 'http://xmlns.com/foaf/0.1/' 'AuthenticatedAgent';
// const String solid = 'http://www.w3.org/ns/solid/terms#';

/// String terms used as prfixes in turtle and acl files
const String foafPrefix = 'foaf:';
// const String aclPrefix = 'acl:';
const String selfPrefix = ':';
const String termsPrefix = 'terms:';
// const String filePrefix = 'file:';
const String dataPrefix = 'data:';
const String resIdPrefix = 'resourceId:';
const String logIdPrefix = 'logId:';

/// String variables for creating files and directories on solid server

String fileTypeLink = '<http://www.w3.org/ns/ldp#Resource>; rel="type"';
String dirTypeLink = '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"';

/// String variables for encryption key files

const String encKeyFileTitle = 'Encryption keys';
const String indKeyFileTitle = 'Individual Encryption Keys';
const String pubKeyFileTitle = 'Public key';

/// String variable for log files

const String logFileTitle = 'Permissions Log';

/// String variable for WebIDs

const String whatIsWebID =
    'A WebID is an Internationalised Resource Identifier that identifies a POD owner.';
const String demoWebID =
    'https://pods.solidcommunity.au/john-doe/profile/card#me';

/// Initialize a constant instance of FlutterSecureStorage for secure data storage.
/// This instance provides encrypted storage to securely store key-value pairs
/// (the security key, and the DPoP private key + OIDC tokens via
/// [AuthDataManager]).
///
/// Platform notes (flutter_secure_storage v10):
/// - Android: the default already uses AES-GCM with RSA-OAEP key wrapping
///   (the old `encryptedSharedPreferences` flag is deprecated and ignored), so
///   no Android options are needed.
/// - iOS/macOS: pin the keychain accessibility to `first_unlock_this_device`.
///   This keeps items reachable for background token refresh (after the first
///   unlock following a reboot) while ensuring the device-bound secrets are
///   NOT migrated to a new device via encrypted backups / iCloud. Losing the
///   DPoP key on device migration simply forces a re-login, which is expected
///   since the OIDC client is registered dynamically per session anyway.
/// - macOS additionally turns `usesDataProtectionKeychain` off (the plugin
///   defaults it on). The data protection keychain is reachable only by a
///   process carrying a keychain access group, which Developer ID distribution
///   cannot supply: it embeds no provisioning profile, and
///   `keychain-access-groups` is a restricted entitlement without one. Worse,
///   the OS then fails asymmetrically. `SecItemAdd` returns
///   `errSecMissingEntitlement` (-34018), so the caller falls back to plaintext
///   `shared_preferences`, while `SecItemCopyMatching` returns
///   `errSecItemNotFound` (-25300), which reads as "never stored" and triggers
///   no fallback. Secrets are leaked to disk and then lost on read. The
///   file-based (login) keychain needs no entitlement and works sandboxed or
///   not; `accessibility` is a data protection attribute and is ignored there.
///
///   20260920 tonypioneer Diagnosed against the notarized todopod 1.0.46 DMG,
///   where it left the PKCE `code_verifier` unreadable and made every login
///   fail with `invalid_grant - PKCE verification failed`.
/// - Web: values are AES-GCM-encrypted (256-bit) via the browser's Web Crypto
///   API. The caveat is the encryption key: with the default options the AES
///   key is stored *unwrapped* in the same storage as the ciphertext, so any
///   same-origin script (e.g. via XSS) could recover both. To limit exposure
///   we set `useSessionStorage: true`, which places everything in
///   `sessionStorage` rather than `localStorage`. The store is then scoped to
///   the browsing session: it is per-tab, is not shared with other tabs, and
///   is cleared when the tab/window is closed — so the security key is not left
///   on disk across sessions. (Note `sessionStorage` does survive an in-tab
///   reload/refresh; only closing the tab clears it.)

FlutterSecureStorage secureStorage = const FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    usesDataProtectionKeychain: false,
  ),
  // Web only: use sessionStorage instead of localStorage so cached secrets
  // (security key, DPoP key, tokens) do not persist beyond the browsing
  // session. Ignored on native platforms.
  webOptions: WebOptions(useSessionStorage: true),
);

/// Removes [key] from the secure storage, tolerating the one keychain error
/// that does not mean the deletion failed.
///
/// `flutter_secure_storage`'s Darwin `delete()` runs `SecItemDelete` twice —
/// once with `kSecAttrSynchronizable` true, once false — so that an item
/// written by an earlier build is removed whichever way it was stored. An
/// iCloud-synchronizable query needs a keychain access group, which only an
/// embedded provisioning profile can supply, so in a Developer ID build the
/// synchronizable pass always fails with `errSecMissingEntitlement` (-34018).
/// The plugin then reports that status for the whole call unless the
/// non-synchronizable pass actually deleted something:
///
/// ```swift
/// let status = statusSync != errSecItemNotFound ? statusSync : statusNonSync
/// ```
///
/// -34018 therefore reaches us only when the real (non-synchronizable) item
/// was not there — the plugin returns success when it was found and removed.
/// Swallowing it is exactly equivalent to "nothing to delete", which is what
/// `delete()` promises for an absent key. An app that *can* reach the iCloud
/// keychain never produces the status at all, so nothing is hidden there.
///
/// 20260920 tonypioneer Left unhandled this aborted login in the notarized
/// todopod DMG: [writeToSecureStorage] deletes before every write, so
/// `markPodStructureInitialised()` threw straight out of the login flow.

Future<void> deleteFromSecureStorage(String key) async {
  try {
    await secureStorage.delete(key: key);
  } on PlatformException catch (e) {
    if (!_isMissingKeychainEntitlement(e)) rethrow;
  }
}

/// Whether [e] reports the iOS/macOS keychain "a required entitlement is not
/// present" error (`errSecMissingEntitlement`, OSStatus -34018).
///
/// The Darwin plugin puts the raw OSStatus in `details` and echoes the number
/// in `message`, so both are checked rather than the generic `code` string.

bool _isMissingKeychainEntitlement(PlatformException e) =>
    e.details == -34018 || (e.message?.contains('-34018') ?? false);

/// Enum of resource status

enum ResourceStatus {
  /// The resource exist
  exist,

  /// The resource does not exist
  notExist,

  /// Do not know if the resource exist (e.g. error occurred when checking the status)
  unknown,

  /// Resource access is forbidden
  forbidden,
}

/// Outcome of validating that a URL points to a real Solid WebID profile
/// document, as opposed to merely returning a 200 response. Plain existence
/// is insufficient because many ordinary websites happily return 200 HTML
/// for any unmatched path (SPA catch-alls, soft 404s, etc.), which would
/// otherwise be mistaken for a valid WebID.
enum WebIdStatus {
  /// The URL responds with 200/204 and an RDF content type, so it is very
  /// likely a genuine WebID profile document.
  valid,

  /// The URL responds with 200/204 but the body is not RDF (typically a
  /// `text/html` page from a regular website). The URL is reachable but is
  /// *not* a WebID profile.
  notProfile,

  /// The URL returned 404.
  notExist,

  /// Some other status code (e.g. 403, 5xx) — could not determine.
  unknown,
}

/// Types of the content of resources
enum ResourceContentType {
  /// Detect the MIME type automatically at runtime
  auto(''),

  /// TTL text file
  turtleText('text/turtle'),

  /// Plain text file
  plainText('text/plain'),

  /// Directory
  directory('application/octet-stream'),

  /// Binary data
  binary('application/octet-stream'),

  /// Any
  any('*/*');

  /// Constructor
  const ResourceContentType(this.value);

  /// String value of the access type
  final String value;
}

/// The mode in which a file is opened
enum FileOpenMode {
  /// Text mode
  text('text'),

  /// Binary mode
  binary('binary');

  /// Constructor
  const FileOpenMode(this.value);

  /// String value of the mode
  final String value;
}

/// Request headers that stop a GET being answered from a stale HTTP cache.
///
/// Solid servers commonly mark responses cacheable for a long period —
/// Community Solid Server sends `Cache-Control: max-age=86400` (24 hours) with
/// `Vary: Accept,Authorization,Origin`. On the web, `package:http` is backed by
/// the browser's `fetch`, which honours that, so a container listing or
/// resource read is answered from the browser cache rather than the POD for a
/// full day. Reads then return whatever was true when the cache entry was
/// written: newly created resources are invisible and deleted ones linger.
///
/// This is web-only in practice — `dart:io`'s `HttpClient`, used on every
/// native platform, implements no shared cache — which is why the symptom
/// appears only in Flutter web builds.
///
/// `no-cache` rather than `no-store`: the response may still be stored, but it
/// must be revalidated with the origin before reuse. Where the server supplies
/// a validator, answered with `304 Not Modified` rather than a full
/// re-download. Community Solid Server advertises `ETag` support via
/// `Access-Control-Expose-Headers`, but does not send a validator on every
/// response (a container listing observed in testing carried neither `ETag`
/// nor `Last-Modified`), so some reads will be full re-fetches. That is the
/// intended trade: correctness over a saved round trip.
///
/// `Pragma` is the HTTP/1.0 spelling, sent alongside for intermediaries that
/// predate `Cache-Control`.
const Map<String, String> noHttpCacheHeaders = <String, String>{
  'Cache-Control': 'no-cache',
  'Pragma': 'no-cache',
};
