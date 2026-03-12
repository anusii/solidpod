<!-- markdownlint-disable MD041 MD033 -->

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub License](https://img.shields.io/github/license/anusii/solidpod)](https://raw.githubusercontent.com/anusii/solidpod/dev/LICENSE)
[![GitHub Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/solidpod/master/pubspec.yaml&query=$.version&label=version&logo=github)](https://github.com/anusii/solidpod/blob/dev/CHANGELOG.md)
[![Pub Version](https://img.shields.io/pub/v/solidpod?label=pub.dev&labelColor=333940&logo=flutter)](https://pub.dev/packages/solidpod)
[![GitHub Last Updated](https://img.shields.io/github/last-commit/anusii/solidpod?label=last%20updated)](https://github.com/anusii/solidpod/commits/dev/)
[![GitHub Commit Activity (main)](https://img.shields.io/github/commit-activity/w/anusii/solidpod/main)](https://github.com/anusii/solidpod/commits/dev/)
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

To know more about our work relatd to Solid Pods
visit <https://solidcommunity.au>

## Features

- [Authenticate](#authenticate-example) a user against a given Solid server.
- [Read](#read-pod-file-example) and [write](#write-to-pod-file-example) data files
in a POD.
- [Read, write and delete](#large-file-manager-example) large data files.

For UI components such as login screens, security key management,
permission granting/revoking, and shared resource views, see the
[solidui](https://pub.dev/packages/solidui) package.

[Solid](https://solidproject.org/) is an open standard for a server
providing Data Vaults  hosting personal online data stores
(Pods). Numerous providers of Solid Server
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
An example project that uses `solidpod` can be found
in the [example](https://github.com/anusii/solidui/tree/dev/example)
folder of the [SolidUI](https://github.com/anusii/solidui) repository.

<!-- TODO: List prerequisites and provide or pointer to information on how
to start using the package. -->

## Prerequisites

If the package is being used to build either a `macos` or `web` app,
the following changes are required in order to make the package fully
functional.

## Android

For a release be sure to update
`android/app/src/main/AndroidManifest.xml` to include within the
`queries` section of the `manifest`:

```xml
 <!-- If your app opens https URLs -->
 <intent>
          <action android:name="android.intent.action.VIEW" />
          <category android:name="android.intent.category.BROWSABLE" />
          <data android:scheme="https" />
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

Inside the app directory go to the directory `/web/`. Inside create a
file called `callback.html`. Add the following piece of code into that
file.

```html
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
```

## Usage

Following are the usage of main functionalities supported
by the package.

### Authenticate Example

A function to authenticate a user against a given Solid server
`https://pods.solidcommunity.au/`. Return a list containing
 authentication data.

```dart
final authData = await solidAuthenticate(
        'https://pods.solidcommunity.au/',
        context,
      );
```

### Read Pod File Example

Read data from the file `data/myfiles/my-data-file.ttl`.

```dart
final fileContent = await readPod(
        'data/myfiles/my-data-file.ttl',
      );
```

### Write to Pod File Example

Write data to the file `myfiles/my-data-file.ttl`.

```dart
// Turtle string to be written to the file
final turtleString =
  '@prefix somePrefix: <http://www.perceive.net/schemas/relationship/> .
<http://example.org/#green-goblin> somePrefix:enemyOf
<http://example.org/#spiderman> .';

await writePod(
 'myfiles/my-data-file.ttl',
 turtleString,
 encrypted: false // non-required parameter. By default set to true
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

await writePod(
 'parentDir/child-1.ttl',
 childDataString,
 createAcl: false,
 inheritKeyFrom: 'parentDir/',
);

await writePod(
 'parentDir/child-2.ttl',
 childDataString,
 createAcl: false,
 inheritKeyFrom: 'parentDir/',
);
```

The above will create a single `.acl` file for the directory
`parentDir` and use that as `.acl` file for both `child-1.ttl` and
`child-2.ttl` files. Also it will create a single key associated with
the directory `parentDir` and encrypt both files using that key.

### Large File Manager Example

To upload a large file in application `myapp`, use:

```dart
await writeLargeFile(
     // Name of the file in POD
     remoteFilePath: 'my-large-file.bin',
     // Path of the file where it is locally stored
     localFilePath: 'D:/my-large-file.bin',
)
```

The uploaded file will be stored in the `myapp/data` folder.

To download a large file use:

```dart
await readLargeFile(
     // Name of the file in POD
     remoteFilePath: 'my-large-file.bin',
     // Path of the file where it will be locally downloaded
     localFilePath: 'D:/my-large-file.bin',
)
```

To delete a large file use:

```dart
await deleteLargeFile(
     // Name of the file in POD
     remoteFilePath: 'my-large-file.bin',
)
```

## Ontology

A Solid Pod's internal storage structure consists of
[turtle](https://www.w3.org/TR/turtle/) files containing security
information about the pod's content (data files) and access.  The
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
repository](https://github.com/anusii/solidpod).  You can also file
issues at [GitHub Issues](https://github.com/anusii/solidpod/issues).
The authors of the package will respond to issues as best we can but.

<!-- markdownlint-disable MD036 -->
*Time-stamp: <Monday 2026-01-19 16:52:57 +1100 Graham Williams>*
<!-- markdownlint-enable MD036 -->

<!-- markdownlint-disable MD053 -->
[comment]: # (Local Variables:)
[comment]: # (time-stamp-line-limit: -8)
[comment]: # (End:)
<!-- markdownlint-enable MD053 -->
