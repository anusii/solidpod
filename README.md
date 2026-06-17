<!-- markdownlint-disable MD041 MD033 -->

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub License](https://img.shields.io/github/license/anusii/solidpod)](https://raw.githubusercontent.com/anusii/solidpod/dev/LICENSE)
[![GitHub Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/solidpod/master/pubspec.yaml&query=$.version&label=version&logo=github)](https://github.com/anusii/solidpod/blob/dev/CHANGELOG.md)
[![Pub Version](https://img.shields.io/pub/v/solidpod?label=pub.dev&labelColor=333940&logo=flutter)](https://pub.dev/packages/solidpod)
[![GitHub Last Updated](https://img.shields.io/github/last-commit/anusii/solidpod?label=last%20updated)](https://github.com/anusii/solidpod/commits/dev/)
[![GitHub Commit Activity (main)](https://img.shields.io/github/commit-activity/w/anusii/solidpod/dev)](https://github.com/anusii/solidpod/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/anusii/solidpod)](https://github.com/anusii/solidpod/issues)

# Solid Pod

A package to support access to your Data Vault hosted on a Solid
Server, implemented by the [ANU Software Innovation
Institute](https://sii.anu.edu.au) supporting the [Australian Solid
Community](https://solidcommunity.au).

Authors: [Anushka Vidanage](https://github.com/anushkavidanage),
[Graham Williams](https://github.com/gjwgit), [Jessica
Moore](https://github.com/jesscmoore), [Dawei
Chen](https://github.com/cdawei), [Kevin
Wang](https://github.com/junhaow1), [Zheyuan
Xu](https://github.com/zheyxu).

Free (as in Libre) and Open Source Software License:
[MIT](https://choosealicense.com/licenses/mit/)

See the [AU Solid Community](https://solidcommunity.au) page for apps
utilising the solidpod package.

## Introduction

[SolidPod](https://pub.dev/packages/solidpod) provides the core
business logic for Dart applications to manage personal online data
stores (PODs) hosted in a Data Vault on a [Solid
Server](https://solidproject.org). It supports authenticating users to
their PODs, reading and writing data, and managing access permissions
programmatically. The companion
[solidui](https://pub.dev/packages/solidui) package builds on top of
SolidPod to provide ready-made Flutter widgets for login screens,
permission management, and other user-facing features.

## What is Solid?

Solid (<https://solidproject.org/>) is an open standard for a server
to host personal online data stores (Pods). Numerous providers of
Solid Server hosting are emerging allowing users to host and migrate
their Pods on any such servers (or to run their own server).

To know more about our work related to Solid Pods
visit <https://solidcommunity.au>

## Features

- [Authenticate](#authenticate-example) a user against a given Solid server (
  WebID or issuer URI).
- [Silent session restore](#session-restore-example) on app startup — no browser
  required.
- [Read](#read-pod-file-example) and [write](#write-to-pod-file-example) data
  files in a POD.
- [Delete files and containers](#delete-a-file-from-the-pod) from a POD.
- [Read, write and delete](#large-file-manager-example) large data files.
- Grant and revoke access permissions between users.

For UI components such as login screens, security key management,
permission granting/revoking, and shared resource views, see the
[solidui](https://pub.dev/packages/solidui) package.

[hosts](https://solidproject.org/get_a_pod) support users host and
migrate their Pods. Anyone can also host their own [Community Solid
Server](https://communitysolidserver.github.io/CommunitySolidServer/latest/).
To know more about our work visit the ANU's [Software Innovation
Institute](https://sii.anu.edu.au) and the [Australian Solid
Community](https://solidcommunity.au).

## Getting started

To start using the package add `solidpod` as a dependency in
your `pubspec.yaml` file.

```yaml
dependencies:
  solidpod: ^<latest-version>
```

An example project that uses `solidpod` can be found in the
[example](https://github.com/anusii/solidpod/tree/dev/example) folder
of the [solidpod](https://github.com/anusii/solidpod) repository.

<!-- TODO: List prerequisites and provide or pointer to information on how
to start using the package. -->

## Create a new app from the template

`solidpod` ships with an app template — a ready-to-run Pod file browser,
complete with a navigation rail and a status bar, built on
[`solidui`](https://pub.dev/packages/solidui). It is the practical equivalent
of a `flutter create --template=solidpod`, which stock Flutter cannot offer
because the `--template` flag only accepts a fixed set of built-in types. We
provide a small generator instead.

From any checkout that depends on `solidpod`:

```bash
dart run solidpod:create my_pod_app
```

Or activate it once and use it anywhere:

```bash
flutter pub global activate solidpod
solidpod create my_pod_app
```

The generator runs `flutter create` to lay down the platform folders, overlays
the template (substituting your app name), and runs `flutter pub get`. Useful
options:

| Option                | Description                                              |
|-----------------------|----------------------------------------------------------|
| `--org <id>`          | Reverse-domain organisation id (default: `com.example`). |
| `--title <text>`      | Window title shown by the app.                           |
| `--description <text>`| `pubspec` description.                                    |
| `-o, --output <dir>`  | Output directory (default: the app name).                |
| `--no-flutter-create` | Render the template only; skip generating platform folders. |
| `--no-pub-get`        | Skip the final `flutter pub get`.                        |

The generated app starts at a `SolidLogin` screen and, once signed in, shows a
`SolidScaffold` with a home page, an app-files browser and a whole-POD browser.
After generating, update the Solid app registration (`clientId`,
`redirectUris`, `link`) in `lib/app.dart` and the constants in
`lib/constants/app.dart` for your own deployment.

## Prerequisites

If the package is being used to build either a `macos` or `web` app,
the following changes are required in order to make the package fully
functional.

## General

`solidpod` delegates authentication to
[`package:solid_auth`](https://pub.dev/packages/solid_auth), which is
built on the OpenID-certified
[`package:oidc`](https://pub.dev/packages/oidc) and implements the
Solid-OIDC protocol.

Authentication requires a client ID document, which is a publicly
hosted JSON-LD file that identifies your app to the Solid identity
provider. Pass its URL as the clientId parameter to
solidAuthenticate(). See the [Solid-OIDC client identifiers
spec](https://solid.github.io/solid-oidc/#clientids-document) for how
to create and host one. For an example client ID document refer to the
[client_profile.jsonld](https://anushkavidanage.github.io/solidpod/example/client-profile.jsonld).

## Android

As per [OIDC getting started
guide](https://bdaya-dev.github.io/oidc/oidc-getting-started/) update
the following.

Go to `android/app/build.gradle`, and add the following line under
`defaultConfig:`

```gradle
 defaultConfig {
    ...
    manifestPlaceholders += [
    'appAuthRedirectScheme': 'com.my.app'
    ]
}
```

Replace `com.my.app` with your `applicationId`. If you have a `build.gradle.kts`
file upgrade in the following way

```gradle
 defaultConfig {
    ...
    manifestPlaceholders.putAll(mapOf(
            "appAuthRedirectScheme" to "com.my.app"
        ))
}
```

Go to `android/app/src/main/AndroidManifest.xml`, and add the following under
`application` tag:

```xml

<application
        ...
        android:fullBackupContent="@xml/backup_rules"
        android:dataExtractionRules="@xml/data_extraction_rules"
        >
```

Also under `activity` tab change the following:

- Remove the line `android:taskAffinity=""`
- Change `android:launchMode="singleTop"` to `android:launchMode="singleTask"`

Now create the following file in `android\app\src\main\res\xml\backup_rules.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="sharedpref" path="FlutterSecureStorage"/>
</full-backup-content>
```

Also create the following file in
`android\app\src\main\res\xml\data_extraction_rules.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="sharedpref" path="FlutterSecureStorage"/>
    </cloud-backup>
</data-extraction-rules>
```

For a release be sure to update
`android/app/src/main/AndroidManifest.xml` to include within the
`queries` section of the `manifest`:

```xml
 <!-- If your app opens https URLs -->
<intent>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="https"/>
</intent>
```

### macos

Inside the app directory go to the directory `/macos/Runner/`. Inside
there are two files named `DebugProfile.entitlements` and
`Release.entitlements`. Add the following lines inside the `<dict>
</dict>` tag in both files.

```xml

<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.cs.allow-jit</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array/>
<key>com.apple.security.keychain</key>
<true/>
```

*Note: You may already have some of the above lines in those files. If
so fill the missing.*

### web

<!-- Inside the app directory go to the directory `/web/`. Inside create a
file called `callback.html`. Add the following piece of code into that
file. -->

In the same location where your client ID document is hosted, create
a file called `redirect.html`. Add the following piece of `html` code into
that file.

<!-- markdownlint-disable MD013 -->
```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>Flutter Oidc Redirect</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript">
        const stateNamespace = 'state';
        const stateResponseNamespace = 'response.state';
        const requestNamespace = 'request';

        const requestBroadcastChannel = 'oidc_flutter_web/request';
        const redirectBroadcastChannel = 'oidc_flutter_web/redirect';


        //if the OP isn't requesting logout, handle redirect.
        if (!handleFrontChannelLogout()) {
            handleRedirect();
        }

        function handleRedirect() {
            // For supported browsers: https://caniuse.com/broadcastchannel
            var bc = new BroadcastChannel(redirectBroadcastChannel);
            bc.postMessage(window.location.toString());
            bc.close();
            //The rest of this function handles same page redirects
            let dataSrc;
            dataSrc = new URLSearchParams(window.location.search);
            var state = dataSrc.get('state');
            if (!state) {
                if (window.location.hash) {
                    dataSrc = new URLSearchParams(
                            window.location.hash.substring(1)
                    );
                    state = dataSrc.get('state');
                }
            }
            if (!state) {
                return;
            }
            const stateDataRaw = getLocalStorage(stateNamespace, state);
            if (!stateDataRaw) {
                console.error('state not found, key: ' + state);
                return;
            }
            setLocalStorage(stateResponseNamespace, state, window.location.toString());
            //we call JSON.parse twice, since shared_preferences double encodes json strings for some reason.
            const parsedStateString = JSON.parse(stateDataRaw);
            if (!parsedStateString) {
                console.error('parsed state is null');
                return;
            }
            // Read the mode from the state.
            const webLaunchMode = parsedStateString.options?.webLaunchMode;
            if (!webLaunchMode) {
                console.error('webLaunchMode not found in parsed state.');
                return;
            }
            if (webLaunchMode != 'samePage') {
                return;
            }
            const original_uri = parsedStateString.original_uri;
            if (!original_uri) {
                console.warn("it's preferred that original_uri is used when webLaunchMode is samePage.");
                return;
            }
            window.location.assign(original_uri);
        }

        function handleFrontChannelLogout() {
            const queryParams = new URLSearchParams(window.location.search);
            if (queryParams.get('requestType') == 'front-channel-logout') {
                // For supported browsers: https://caniuse.com/broadcastchannel
                var bc = new BroadcastChannel(requestBroadcastChannel);
                bc.postMessage(window.location.toString());
                bc.close();
                // this puts a marker for the flutter app that the user wants to logout.
                //
                // in the flutter app, if this marker exists,
                // we don't auth the cached user in `UserManager.init()`, and we clear the cached data.
                setLocalStorage(requestNamespace, 'front-channel-logout', window.location.toString());
                return true;
            }
            return false;
        }

        function getLocalStorage(namespace, key) {
            const rawRes = localStorage.getItem('oidc.' + namespace + '.' + key);
            if (!rawRes) {
                return null;
            }
            return rawRes;
        }

        function setLocalStorage(namespace, key, value) {
            const keysEntryKey = 'oidc.keys.' + namespace;
            var keys = localStorage.getItem(keysEntryKey);
            if (!keys) {
                keys = "[]";
            }
            const parsedKeys = JSON.parse(keys);
            if (!(parsedKeys instanceof Array)) {
                console.error('parsedKeys is not an array.', parsedKeys);
            }
            parsedKeys.push(key);
            localStorage.setItem(keysEntryKey, JSON.stringify(parsedKeys));
            localStorage.setItem('oidc.' + namespace + '.' + key, value);
        }
    </script>
</head>

<body>
<h2>Authentication completed! Please close this page.</h2>
</body>

</html>
```
<!-- markdownlint-enable MD013 -->

<!-- ```html
<!DOCTYPE html>
<html>

<head>
    <script>
        const AUTH_DESTINATION_KEY = "openidconnect_auth_destination_url";
        const AUTH_RESPONSE_KEY = "openidconnect_auth_response_info";

        window.onload = function () {
        if (window.opener && window.opener !== window) {
          // Used when working as a popup.
          // Uses post message to respond to the parent window
          var parent = window.opener ?? window.parent;
          parent.postMessage(location.href, "*");
            } else { //Used for redirect loop functionality.
                //Get the original page destination
                const destination =
                  sessionStorage.getItem(AUTH_DESTINATION_KEY || "/");
                sessionStorage.removeItem(AUTH_DESTINATION_KEY);
                // Store current window location used to get
                // authentication information
                sessionStorage.setItem(AUTH_RESPONSE_KEY, window.location);

                //Redirect to where we're going so that we can restore state completely
                location.assign(destination);
            }
        }
    </script>
</head>

<body>
</body>

</html>
``` -->

## Usage

Following are the usage of main functionalities supported
by the package.

### Authenticate Example

Authenticates a user against a Solid server. The first argument can be
either the user's **WebID** (preferred) or a bare issuer URI. Returns
`[SolidAuthData, webId, profileTurtle]` on success, or `null` on failure.

```dart

final result = await
solidAuthenticate
('https://pods.solidcommunity.au/alice/profile/card#me
'
, // WebID or issuer URI
context,
clientId: 'https://your-domain/client-profile.jsonld',
redirectUris: [
'https://your-domain/redirect.html', // web
'com.example.app://redirect', // Android / iOS
'http://localhost:4400/redirect', // Windows / Linux / macOS
],
postLogoutRedirectUris: [ // optional, defaults to redirectUris selection
'https://your-domain/redirect.html',
'com.example.app://redirect',
'http://localhost:4400/redirect',
],
);

if (result != null) {
final authData = result[0] as SolidAuthData; // access token, id token, etc.
final webId = result[1] as String; // user's WebID
final profile = result[2] as String; // Turtle-encoded profile document
}
```

<!-- markdownlint-disable MD036 -->
**IMPORTANT**
<!-- markdownlint-enable MD036 -->

`redirectUris` and `postLogoutRedirectUris` take a list of URIs, one per
platform. At runtime `solidAuthenticate()` picks the entry that matches the
current platform. Every URI in the list must be registered in your client
ID document and match the correct format for each platform:

<!-- markdownlint-disable MD013 -->
| Platform              | URI format                          | Notes                                                                              |
|-----------------------|-------------------------------------|------------------------------------------------------------------------------------|
| Web                   | `https://your-domain/redirect.html` | Must be same origin as the app - `oidc` uses `BroadcastChannel` (same-origin only) |
| Android / iOS / macOS | `com.example.app://redirect`        | Custom URI scheme registered with the OS                                           |
| Windows / Linux       | `http://localhost:4400/redirect`    | **Fixed port required** - see below                                                |
<!-- markdownlint-enable MD013 -->

### Desktop: use a fixed port

`oidc_desktop` binds a loopback HTTP server to the port in the desktop
entry of `redirectUris`. If you use port `0`, the OS assigns a random port
that is never registered in the client document, causing the Solid server
to reject logout with `post_logout_redirect_uri not registered`.
Use a fixed port (e.g. `4400`) in both the app and the client document.

Both `redirect_uris` and `post_logout_redirect_uris` in the client ID
document must list every URI used across platforms:

```json
{
  "redirect_uris": [
    "https://your-domain/redirect.html",
    "http://localhost:4400/redirect"
  ],
  "post_logout_redirect_uris": [
    "https://your-domain/redirect.html",
    "http://localhost:4400/redirect"
  ]
}
```

### Session Restore Example

On app startup, call `tryRestoreSession()` to silently resume a previous
session without opening a browser. It returns
`[SolidAuthData, webId, profileTurtle]`
if a valid persisted session exists, or `null` if the user needs to log in.

```dart
// In initState() or app startup code — before showing the login UI.
final result = await

tryRestoreSession();if (
result != null) {
final authData = result[0] as SolidAuthData;
final webId = result[1] as String;
final profile = result[2] as String;
// Navigate directly to the authenticated screen.
} else {
// No valid session — show the login screen.
}
```

`tryRestoreSession()` never opens a browser. It silently refreshes expired
access tokens if a refresh token is available, and returns `null` if the
session cannot be restored (in which case the stored session is cleared
automatically so the next `solidAuthenticate()` starts clean).

### Read Pod File Example

Read data from the file `data/myfiles/my-data-file.ttl`.

```dart

final fileContent = await
readPod
('data/myfiles/my-data-file.ttl
'
,
);
```

### Write to Pod File Example

Write data to the file `myfiles/my-data-file.ttl`.

```dart
// Turtle string to be written to the file
final turtleString =
    '@prefix somePrefix: <http://www.perceive.net/schemas/relationship/> .
        < http: //example.org/#green-goblin> somePrefix:enemyOf
<
http: //example.org/#spiderman> .';

await writePod
('myfiles/my-data-file.ttl
'
,turtleString,
encrypted
:
false // non-required parameter. By default set to true
);
```

`writePod()` also supports using inherited encryption keys and
`.acl` files. For instance, consider the following use-case.

*Use-case*: Write two files `parentDir/child-1.ttl` and `parentDir/child-1.ttl`
into a single directory `parentDir`. Use a single `.acl` file for both
the files and use a single encryption key to encrypt both the files.

Above can be achieved using following lines of code.

```dart
// Turtle string to be written to the file
final childDataString = '<Sample TTL Data>';

await writePod
('parentDir/child-1.ttl
'
,childDataString,
createAcl: false,
inheritKeyFrom: 'parentDir/',
);

await writePod(
'parentDir/child-2.ttl',
childDataString,
createAcl: false,
inheritKeyFrom: 'parentDir/'
,
);
```

The above will create a single `.acl` file for the directory
`parentDir` and use that as `.acl` file for both `child-1.ttl` and
`child-2.ttl` files. Also it will create a single key associated with
the directory `parentDir` and encrypt both files using that key.

### Delete a File from the Pod

```dart
// Obtain the full URL for the file first.
final fileUrl = await
getFileUrl
('myfiles/my-data-file.ttl
'
);

// Delete the file, its ACL, and its encryption key (if any).
// Also revokes any permissions previously granted to other users.
await deleteFile
(
fileUrl
:
fileUrl
);
```

To delete an entire directory and all of its contents recursively:

```dart
await deleteContainer
('myapp/data
'
,
'
myfiles
'
);
```

### Large File Manager Example

To upload a large file in application `myapp`, use:

```dart
await writeLargeFile
(
// Name of the file in POD
remoteFilePath: 'my-large-file.bin',
// Path of the file where it is locally stored
localFilePath: 'D:/my-large-file.bin',
)
```

The uploaded file will be stored in the `myapp/data` folder.

To download a large file use:

```dart
await readLargeFile
(
// Name of the file in POD
remoteFilePath: 'my-large-file.bin',
// Path of the file where it will be locally downloaded
localFilePath: 'D:/my-large-file.bin',
)
```

To delete a large file use:

```dart
await deleteLargeFile
(
// Name of the file in POD
remoteFilePath
:
'
my-large-file.bin
'
,
)
```

## Ontology

A Solid Pod's internal storage structure consists of
[turtle](https://www.w3.org/TR/turtle/) files containing security
information about the pod's content (data files) and access. The
internal structure is based on the solidpod
[ontology](onto/solid_app_ontology_schema.png), which captures
essential concepts about the app's security information, data files,
encryption, shared resources, and access control lists.

![Ontolgy](https://github.com/anusii/solidpod/blob/dev/onto/solid_app_ontology_schema.png)

## Additional information

<!-- TODO: More about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can
expect from the package authors, and more. -->

The source code can be accessed via the [GitHub
repository](https://github.com/anusii/solidpod). You can also file
issues at [GitHub Issues](https://github.com/anusii/solidpod/issues).
The authors of the package will respond to issues as best we can but.

<!-- markdownlint-disable MD036 -->
*Time-stamp: <Wednesday 2026-06-03 16:48:48 +1000 Graham Williams>*
<!-- markdownlint-enable MD036 -->

<!-- markdownlint-disable MD053 -->

[comment]: # (Local Variables:)

[comment]: # (time-stamp-line-limit: -8)

[comment]: # (End:)
<!-- markdownlint-enable MD053 -->
