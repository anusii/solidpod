/// Initial loaded screen set up page.
///
// Time-stamp: <Friday 2024-02-02 09:08:08 +1100 Graham Williams>
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
/// Authors: Zheyuan Xu
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:solid_encrypt/solid_encrypt.dart';
import 'package:solidpod/src/solid/api/rest_api.dart';
import 'package:solidpod/src/solid/login.dart';
import 'package:solidpod/src/widgets/build_message_container.dart';
import 'package:solidpod/src/widgets/error_dialog.dart';
import 'package:solidpod/src/widgets/show_animation_dialog.dart';

/// Color variables used in initial setup screen.

const lightGreen = Color.fromARGB(255, 120, 219, 137);
const darkBlue = Color.fromARGB(255, 7, 87, 153);
const kTitleTextColor = Color(0xFF30384D);

/// Text string variables used in initial setup screen.

const initialStructureWelcome = 'Welcome to the POD setup wizard!';
const initialStructureTitle = 'Structure setup wizard!';
const initialStructureMsg =
    'You are being re-directed to this page because you have either created'
    ' a completely new POD and you will need to setup the initial resource'
    ' structure to start using the app OR we have detected some missing files'
    ' and/or folders in your POD that will prevent you from using some functionalities'
    ' of the app, and therefore need to be re-created.';
const requiredPwdMsg =
    'A password (also known as a master key) is use to make your data private'
    ' (using encryption) when it is stored in you Solid Pod.'
    ' This could be the same password you use to  login to your'
    ' Solid Pod (not recommended) or a different password (highly recommended).'
    ' Please enter your password and confirm it below.';
const publicKeyMsg =
    'We will also create a random public/private key pair for secure data'
    ' sharing with other PODs.';

/// String terms used in files generating process.

const String encKeyFile = 'enc-keys.ttl';
const String pubKeyFile = 'public-key.ttl';
const String profCard = 'profile/card#me';
const String ivPred = 'iv';
const String titlePred = 'title';
const String prvKeyPred = 'prvKey';
const String pubKeyPred = 'pubKey';
const String encKeyPred = 'encKey';
const String indKeyFile = 'ind-keys.ttl';
const String permLogFile = 'permissions-log.ttl';

/// String link variables used in files generating process.

const String appsTerms = 'https://solidcommunity.au/predicates/terms#';
const String terms = 'http://purl.org/dc/terms/';
const String acl = 'http://www.w3.org/ns/auth/acl#';
const String foaf = 'http://xmlns.com/foaf/0.1/';
const String appsFile = 'https://solidcommunity.au/predicates/file#';
const String appsLogId = 'https://solidcommunity.au/predicates/logid#';
const String solid = 'http://www.w3.org/ns/solid/terms#';

/// Numeric variables used in initial setup screen.

const int longStrLength = 12;
const double kDefaultPadding = 20.0;

/// Get the height of screen.

double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

/// Get the width of screen.

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

/// Initialize a constant instance of FlutterSecureStorage for secure data storage.
/// This instance provides encrypted storage to securely store key-value pairs.

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

/// Removes header and footer from a PEM-formatted public key string.
///
/// This function takes a public key string, typically in PEM format, and removes
/// the standard PEM headers and footers.

String dividePubKeyStr(String keyStr) {
  final itemList = keyStr.split('\n');
  itemList.remove('-----BEGIN RSA PUBLIC KEY-----');
  itemList.remove('-----END RSA PUBLIC KEY-----');
  itemList.remove('-----BEGIN PUBLIC KEY-----');
  itemList.remove('-----END PUBLIC KEY-----');

  final keyStrTrimmed = itemList.join();

  return keyStrTrimmed;
}

/// Generates an encryption key body string.
///
/// Constructs a TTL (Time To Live) file body string using the provided parameters.
/// This string is formatted with specific resource URL, private key, private key initialization vector,
/// and encrypted master key. These elements are organized in a predefined structured format.
///
/// The function primarily serves the purpose of assembling a structured text representation
/// of encryption keys and related data, which can be utilized in further cryptographic operations
/// or data transmission.

String genEncKeyBody(
  String encMasterKey,
  String prvKey,
  String prvKeyIvz,
  String resUrl,
) {
  // Create a ttl file body.

  final keyFileBody =
      '<$resUrl> <$terms$titlePred> "Encryption keys";\n    <$appsTerms$ivPred> "$prvKeyIvz";\n    <$appsTerms$encKeyPred> "$encMasterKey";\n    <$appsTerms$prvKeyPred> "$prvKey".';

  return keyFileBody;
}

/// Generates an ACL (Access Control List) log body for a specified web ID and permission file.
///
/// This function creates an ACL log body with specific prefixes and authorization settings.
/// It modifies the web ID by removing 'me' and constructs an ACL log with various permissions.
///
/// [webId] is the web identifier, which is altered within the function.
/// [permFileName] is the name of the file for which the ACL settings are being generated.
///
/// Returns a [String] containing the ACL log body.

String genLogAclBody(String webId, String permFileName) {
  final webIdStr = webId.replaceAll('me', '');
  final logAclFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix foaf: <$foaf>.\n@prefix c: <$webIdStr>.\n\n:owner\n    a acl:Authorization;\n    acl:accessTo <$permFileName>;\n    acl:agent c:me;\n    acl:mode acl:Control, acl:Read, acl:Write.\n\n:public\n    a acl:Authorization;\n    acl:accessTo <$permFileName>;\n    acl:agentClass foaf:Agent;\n    acl:mode acl:Append.';

  return logAclFileBody;
}

/// Generates a string representing the public file ACL (Access Control List) body.
///
/// This function creates an ACL body for a given file, setting up authorization
/// rules for both the owner and public access. It formats the ACL data using
/// specific prefixes and access rules. The owner is granted full control (read,
/// write, and control), while public access is limited to read and write permissions.
///
/// The generated ACL body uses a RDF (Resource Description Framework) format, specifying
/// the permissions using ACL ontology. This format is often used in web standards for
/// describing the rules about who can access a specific resource.

String genPubFileAclBody(String fileName) {
  // Create file body
  final resName = fileName.replaceAll('.acl', '');
  final pubFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix foaf: <$foaf>.\n@prefix c: <card#>.\n\n:owner\n    a acl:Authorization;\n    acl:accessTo <$resName>;\n    acl:agent c:me;\n    acl:mode acl:Control, acl:Read, acl:Write.\n\n:public\n    a acl:Authorization;\n    acl:accessTo <$resName>;\n    acl:agentClass foaf:Agent;\n    acl:mode acl:Read, acl:Write.';

  return pubFileBody;
}

/// Generates the body for a public directory ACL (Access Control List).
///
/// This function constructs a string representing the body of an ACL file.
/// The ACL (Access Control List) is defined using Web Access Control (WAC)
/// vocabulary, specifying authorization policies for a web resource.

String genPubDirAclBody() {
  // Create file body
  const pubFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix foaf: <$foaf>.\n@prefix shrd: <./>.\n@prefix c: </profile/card#>.\n\n:owner\n    a acl:Authorization;\n    acl:accessTo shrd:;\n    acl:agent c:me;\n    acl:mode acl:Control, acl:Read, acl:Write.\n\n:public\n    a acl:Authorization;\n    acl:accessTo shrd:;\n    acl:default shrd:;\n    acl:agentClass foaf:Agent;\n    acl:mode acl:Read, acl:Write.';

  return pubFileBody;
}

/// Generates the body of an individual encryption key file in Turtle (Terse RDF Triple Language) format.
///
/// This function constructs a string representing the body of an RDF file, which includes various
/// prefixed namespaces such as FOAF (Friend of a Friend) and custom application-specific terms.
/// The key file body includes a definition for a personal profile document with a title
/// "Individual Encryption Keys". The prefixes used ('foaf:', 'terms:', etc.) are placeholders
/// that should be replaced with actual URIs in a real-world application.

String genIndKeyFileBody() {
  const keyFileBody =
      '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix terms: <$terms>.\n@prefix file: <$appsFile>.\n@prefix appsTerms: <$appsTerms>.\n:me\n    a foaf:PersonalProfileDocument;\n    terms:title "Individual Encryption Keys".';

  return keyFileBody;
}

/// Generates a public key file body in string format.
///
/// This function creates a string that represents the body of a public key file.
/// It formats the resource URL and the public key string into a predefined template.
///
/// The template includes a resource URL and a public key string, formatted
/// with specific predicates and a title. The `<$terms$titlePred>` is used for the
/// title "Public key" and `<$appsTerms$pubKeyPred>` for the public key itself.

String genPubKeyFileBody(String resUrl, String pubKeyStr) {
  final keyFileBody =
      '<$resUrl> <$terms$titlePred> "Public key";\n    <$appsTerms$pubKeyPred> "$pubKeyStr";';

  return keyFileBody;
}

/// Generates a profile file body in a predefined format.
///
/// This function takes two maps, `profData` and `authData`, as inputs. The `profData`
/// map contains user profile information such as name and gender. The `authData` map
/// includes authentication information, specifically an access token.

String genProfFileBody(
    Map<dynamic, dynamic> profData, Map<dynamic, dynamic> authData) {
  final decodedToken = JwtDecoder.decode(authData['accessToken'] as String);
  final issuerUri = decodedToken['iss'] as String;

  final name = profData['name'];
  final gender = profData['gender'];

  final fileBody =
      '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix solid: <$solid>.\n@prefix vcard: <http://www.w3.org/2006/vcard/ns#>.\n@prefix pro: <./>.\n\npro:card a foaf:PersonalProfileDocument; foaf:maker :me; foaf:primaryTopic :me.\n\n:me\n    solid:oidcIssuer <$issuerUri>;\n    a foaf:Person;\n    vcard:fn "$name";\n    vcard:Gender "$gender";\n    foaf:name "$name".';

  return fileBody;
}

/// Generates the body of a log file in Turtle (Terse RDF Triple Language) format.
///
/// This function constructs a string representing RDF data with specific prefixes
/// and a structured layout. It defines a personal profile document with
/// predefined namespaces (foaf, terms, logid, appsTerms) and a title.
///
/// The resulting string is formatted for use in semantic web applications or
/// any context where RDF data is required.

String genLogFileBody() {
  const logFileBody =
      '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix terms: <$terms>.\n@prefix logid: <$appsLogId>.\n@prefix appsTerms: <$appsTerms>.\n:me\n    a foaf:PersonalProfileDocument;\n    terms:title "Permissions Log".';

  return logFileBody;
}

/// A constant map of file extensions to MIME types.
///
/// This map is used to associate common file extensions with their corresponding
/// MIME type strings. It includes types for 'acl' and 'ttl' as 'text/turtle',
/// and 'log' as 'text/plain'. This can be utilized for file type identification
/// or setting content types in network communications.

const Map<String, String> fileType = {
  'acl': 'text/turtle',
  'log': 'text/plain',
  'ttl': 'text/turtle',
};

/// Truncates the given [text] to a predefined maximum length.
///
/// If [text] exceeds the length defined by [longStrLength], it is truncated
/// and ends with an ellipsis '...'. If [text] is shorter than [longStrLength],
/// it is returned as is.

String truncateString(String text) {
  var result = '';
  result = text.length > longStrLength
      ? '${text.substring(0, longStrLength - 4)}...'
      : text;

  return result;
}

/// Updates the initial profile data on the server.
///
/// This function sends a PUT request to update the user's profile information. It constructs the profile URL from the provided `webId`, generates a DPoP token using the RSA key pair and public key in JWK format from `authData`, and then sends the request with the `profBody` as the payload.
///
/// The `authData` map must contain `rsaInfo` (which includes `rsa` key pair and `pubKeyJwk`) and an `accessToken`. The function modifies the `webId` URL to target the appropriate resource on the server.
///
/// Throws an Exception if the server does not return a 200 OK or 205 Reset Content response, indicating a failure in updating the profile.

Future<String> initialProfileUpdate(
  String profBody,
  Map<dynamic, dynamic> authData,
  String webId,
) async {
  // Get authentication info
  final rsaInfo = authData['rsaInfo'];
  final rsaKeyPair = rsaInfo['rsa'];
  final publicKeyJwk = rsaInfo['pubKeyJwk'];
  final accessToken = authData['accessToken'] as String;

  final profUrl = webId.replaceAll('#me', '');
  final dPopToken =
      genDpopToken(profUrl, rsaKeyPair as KeyPair, publicKeyJwk, 'PUT');

  // The PUT request will create the acl item in the server
  final updateResponse = await http.put(
    Uri.parse(profUrl),
    headers: <String, String>{
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': 'text/turtle',
      'Content-Length': profBody.length.toString(),
      'DPoP': dPopToken,
    },
    body: profBody,
  );

  if (updateResponse.statusCode == 200 || updateResponse.statusCode == 205) {
    // If the server did return a 205 Reset response,
    return 'ok';
  } else {
    // If the server did not return a 205 response,
    // then throw an exception.
    throw Exception('Failed to update resource! Try again in a while.');
  }
}

/// A [StatefulWidget] that represents the initial setup screen for the desktop version of an application.
///
/// This widget is responsible for rendering the initial setup UI, which includes forms for user input and displaying
/// resources that will be created as part of the setup process.

class InitialSetupDesktop extends StatefulWidget {
  const InitialSetupDesktop({
    required this.resNeedToCreate,
    required this.authData,
    required this.webId,
    super.key,
  });
  final Map<dynamic, dynamic> resNeedToCreate;
  final Map<dynamic, dynamic> authData;
  final String webId;

  @override
  State<InitialSetupDesktop> createState() {
    return _InitialSetupDesktopState();
  }
}

class _InitialSetupDesktopState extends State<InitialSetupDesktop> {
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();

    void onChangedVal(dynamic val) => debugPrint(val.toString());
    const showPassword = true;

    final resFoldersLink = (widget.resNeedToCreate['folders'] as List)
        .map((item) => item.toString())
        .toList();

    final resFilesLink = (widget.resNeedToCreate['files'] as List)
        .map((item) => item.toString())
        .toList();

    final resFileNamesLink = (widget.resNeedToCreate['fileNames'] as List)
        .map((item) => item.toString())
        .toList();

    return Column(
      children: [
        Expanded(
            child: SizedBox(
                height: 700,
                child: ListView(primary: false, children: [
                  Center(
                    child: SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: lightGreen,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.playlist_add,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              initialStructureWelcome,
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Center(
                              child: buildMsgBox(context, 'warning',
                                  initialStructureTitle, initialStructureMsg),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                      child: SizedBox(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(80, 10, 80, 0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resources that will be created!',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Divider(
                                      color: Colors.grey,
                                    ),
                                    for (final String resLink
                                        in resFoldersLink) ...[
                                      ListTile(
                                        title: Text(resLink),
                                        leading: const Icon(Icons.folder),
                                      ),
                                    ],
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    for (final String resLink
                                        in resFilesLink) ...[
                                      ListTile(
                                        title: Text(resLink),
                                        leading: const Icon(Icons.file_copy),
                                      ),
                                    ],
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ])))),
                  Center(
                      child: SizedBox(
                          //height: 500,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(80, 10, 80, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  FormBuilder(
                                    key: formKey,
                                    onChanged: () {
                                      formKey.currentState!.save();
                                      debugPrint(formKey.currentState!.value
                                          .toString());
                                    },
                                    autovalidateMode: AutovalidateMode.disabled,
                                    skipDisabled: true,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const Text(
                                          'Please provide a personal password (required for private storage)',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Divider(
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        const Text(
                                          requiredPwdMsg,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        FormBuilderTextField(
                                          name: 'password',
                                          obscureText: showPassword,
                                          autocorrect: false,
                                          decoration: const InputDecoration(
                                            labelText: 'PASSWORD',
                                            labelStyle: TextStyle(
                                              color: darkBlue,
                                              letterSpacing: 1.5,
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            //errorText: 'error',
                                          ),
                                          validator:
                                              FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                          ]),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        FormBuilderTextField(
                                          name: 'repassword',
                                          obscureText: showPassword,
                                          autocorrect: false,
                                          decoration: const InputDecoration(
                                            labelText: 'RETYPE PASSWORD',
                                            labelStyle: TextStyle(
                                              color: darkBlue,
                                              letterSpacing: 1.5,
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            //errorText: 'error',
                                          ),
                                          validator:
                                              FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                            (val) {
                                              if (val !=
                                                  formKey
                                                      .currentState!
                                                      .fields['password']
                                                      ?.value) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ]),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        const Text(
                                          publicKeyMsg,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        FormBuilderCheckbox(
                                          name: 'providepermission',
                                          initialValue: false,
                                          onChanged: onChangedVal,
                                          title: RichText(
                                            text: const TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      'I confirm the above resources to be created on my Solid Pod! ',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                          validator:
                                              FormBuilderValidators.equal(
                                            true,
                                            errorText:
                                                'You must provide permission to continue',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (formKey.currentState
                                                    ?.saveAndValidate() ??
                                                false) {
                                              // ignore: unawaited_futures
                                              showAnimationDialog(
                                                  context,
                                                  17,
                                                  'Creating resources!',
                                                  false,
                                                  null);
                                              final formData = formKey
                                                  .currentState?.value as Map;

                                              final passPlaintxt =
                                                  formData['password']
                                                      .toString();

                                              // variable to see whether we need to update
                                              // the key files. Because if one file is missing
                                              // we need to create asymmetric key pairs again

                                              // Verify encryption master key if it is already
                                              // in the file
                                              var keyVerifyFlag = true;

                                              // Enryption master key
                                              String? encMasterKeyVerify;
                                              String? encMasterKey;

                                              // Asymmetric key pair
                                              String? pubKey;
                                              String? pubKeyStr;
                                              String? prvKey;
                                              String? prvKeyHash;
                                              String? prvKeyIvz;

                                              // Create files and directories flag
                                              var createFileSuccess = true;
                                              var createDirSuccess = true;

                                              if (resFileNamesLink
                                                      .contains(encKeyFile) ||
                                                  resFileNamesLink
                                                      .contains(pubKeyFile)) {
                                                // Generate master key
                                                encMasterKey = sha256
                                                    .convert(utf8
                                                        .encode(passPlaintxt))
                                                    .toString()
                                                    .substring(0, 32);
                                                encMasterKeyVerify = sha224
                                                    .convert(utf8
                                                        .encode(passPlaintxt))
                                                    .toString()
                                                    .substring(0, 32);

                                                // Generate asymmetric key pair
                                                final rsaKeyPair =
                                                    await RSA.generate(2048);
                                                prvKey = rsaKeyPair.privateKey;
                                                pubKey = rsaKeyPair.publicKey;

                                                // Encrypt private key
                                                final key =
                                                    encrypt.Key.fromUtf8(
                                                        encMasterKey);
                                                final iv =
                                                    encrypt.IV.fromLength(16);
                                                final encrypter =
                                                    encrypt.Encrypter(encrypt
                                                        .AES(key,
                                                            mode: encrypt
                                                                .AESMode.cbc));
                                                final encryptVal = encrypter
                                                    .encrypt(prvKey, iv: iv);
                                                prvKeyHash = encryptVal.base64;
                                                prvKeyIvz = iv.base64;

                                                // Get public key without start and end bit
                                                pubKeyStr =
                                                    dividePubKeyStr(pubKey);

                                                if (!resFileNamesLink
                                                    .contains(encKeyFile)) {
                                                  final encryptClient =
                                                      EncryptClient(
                                                          widget.authData,
                                                          widget.webId);
                                                  keyVerifyFlag =
                                                      await encryptClient
                                                          .verifyEncKey(
                                                              passPlaintxt);
                                                }
                                              }

                                              if (!keyVerifyFlag) {
                                                // ignore: use_build_context_synchronously
                                                await showErrDialog(context,
                                                    'Wrong encode key. Please try again!');
                                              } else {
                                                for (final resLink
                                                    in resFoldersLink) {
                                                  final serverUrl = widget.webId
                                                      .replaceAll(profCard, '');
                                                  final resNameStr =
                                                      resLink.replaceAll(
                                                          serverUrl, '');
                                                  final resName = resNameStr
                                                      .split('/')
                                                      .last;

                                                  // Get resource path
                                                  final folderPath = resNameStr
                                                      .replaceAll(resName, '');

                                                  final createDirRes =
                                                      await createItem(
                                                          false,
                                                          resName,
                                                          '',
                                                          widget.webId,
                                                          widget.authData,
                                                          fileLoc: folderPath);

                                                  if (createDirRes != 'ok') {
                                                    createDirSuccess = false;
                                                  }
                                                }

                                                // Create files
                                                for (final resLink
                                                    in resFilesLink) {
                                                  // Get base url
                                                  final serverUrl = widget.webId
                                                      .replaceAll(profCard, '');

                                                  // Get resource path and name
                                                  final resNameStr =
                                                      resLink.replaceAll(
                                                          serverUrl, '');

                                                  // Get resource name
                                                  final resName = resNameStr
                                                      .split('/')
                                                      .last;

                                                  // Get resource path
                                                  final filePath = resNameStr
                                                      .replaceAll(resName, '');

                                                  var fileBody = '';

                                                  if (resName == encKeyFile) {
                                                    fileBody = genEncKeyBody(
                                                        encMasterKeyVerify!,
                                                        prvKeyHash!,
                                                        prvKeyIvz!,
                                                        resLink);
                                                  } else if ([
                                                    '$pubKeyFile.acl',
                                                    '$permLogFile.acl'
                                                  ].contains(resName)) {
                                                    if (resName ==
                                                        '$permLogFile.acl') {
                                                      fileBody = genLogAclBody(
                                                          widget.webId,
                                                          resName.replaceAll(
                                                              '.acl', ''));
                                                    } else {
                                                      fileBody =
                                                          genPubFileAclBody(
                                                              resName);
                                                    }
                                                  } else if (resName ==
                                                      '.acl') {
                                                    fileBody =
                                                        genPubDirAclBody();
                                                  } else if (resName ==
                                                      indKeyFile) {
                                                    fileBody =
                                                        genIndKeyFileBody();
                                                  } else if (resName ==
                                                      pubKeyFile) {
                                                    fileBody =
                                                        genPubKeyFileBody(
                                                            resLink,
                                                            pubKeyStr!);
                                                  } else if (resName ==
                                                      permLogFile) {
                                                    fileBody = genLogFileBody();
                                                  }

                                                  var aclFlag = false;
                                                  if (resName.split('.').last ==
                                                      'acl') {
                                                    aclFlag = true;
                                                  }

                                                  final createFileRes =
                                                      await createItem(
                                                          true,
                                                          resName,
                                                          fileBody,
                                                          widget.webId,
                                                          widget.authData,
                                                          fileLoc: filePath,
                                                          fileType: fileType[
                                                              resName
                                                                  .split('.')
                                                                  .last],
                                                          aclFlag: aclFlag);

                                                  if (createFileRes != 'ok') {
                                                    createFileSuccess = false;
                                                  }
                                                }
                                              }

                                              // Update the profile with new information.
                                              // av 20240201: We have removed the original name and gender data collection from the form.
                                              // Therefore the following commented code does not work.
                                              // final profBody = genProfFileBody(
                                              //     formData, widget.authData);

                                              // final updateRes =
                                              //     await initialProfileUpdate(
                                              //         profBody,
                                              //         widget.authData,
                                              //         widget.webId);

                                              if (createFileSuccess &&
                                                  createDirSuccess) {
                                                imageCache.clear();
                                                // Add name to the authData.

                                                //widget.authData['name'] =
                                                //    formData['name'];

                                                // Add encryption key to the local secure storage.

                                                final isKeyExist =
                                                    await secureStorage
                                                        .containsKey(
                                                  key: widget.webId,
                                                );

                                                print('i am here1');

                                                // Since write() method does not automatically overwrite an existing value.
                                                // To overwrite an existing value, call delete() first.

                                                if (isKeyExist) {
                                                  await secureStorage.delete(
                                                    key: widget.webId,
                                                  );
                                                }

                                                await secureStorage.write(
                                                  key: widget.webId,
                                                  value: passPlaintxt,
                                                );

                                                widget.authData['keyExist'] =
                                                    true;
                                              }
                                            } else {
                                              await showErrDialog(context,
                                                  'Form validation failed! Please check your inputs.');
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                              foregroundColor: darkBlue,
                                              backgroundColor:
                                                  darkBlue, // foreground
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 50),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          child: const Text(
                                            'SUBMIT',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            formKey.currentState?.reset();
                                          },
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: darkBlue,
                                              backgroundColor:
                                                  darkBlue, // foreground
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 50),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          child: const Text(
                                            'RESET',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                ],
                              )))),
                ]))),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.black,
                    size: 24.0,
                  ),
                  label: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () async {
                    await logout(widget.authData['logoutUrl']);
                    // ignore: use_build_context_synchronously
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SolidLogin(
                          // Images generated using Bing Image Creator from Designer, powered by
                          // DALL-E3.

                          image: AssetImage('assets/images/keypod_image.jpg'),
                          logo: AssetImage('assets/images/keypod_logo.png'),
                          title: 'MANAGE YOUR SOLID KEY POD',
                          link: 'https://github.com/anusii/keypod',
                          child: Scaffold(body: Text('Key Pod Placeholder')),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Creates a row widget displaying a piece of profile information.
  ///
  /// This function constructs a `Row` widget designed to display a single piece
  /// of information in a profile UI. It is primarily used for laying out text-based
  /// information such as names, titles, or other key details in the profile section.

  Row buildInfoRow(String profName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          profName,
          style: TextStyle(
            color: Colors.grey[800],
            letterSpacing: 2.0,
            fontSize: 17.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  /// Builds a row widget displaying a label and its corresponding value.
  ///
  /// This function creates a [Column] widget containing a [Row] with two text elements:
  /// one for the label and the other for the profile name. It's used to display
  /// information in a key-value pair format, where `labelName` is the key and
  /// `profName` is the value.

  Column buildLabelRow(
      String labelName, String profName, BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '$labelName: ',
              style: TextStyle(
                color: kTitleTextColor,
                letterSpacing: 2.0,
                fontSize: screenWidth(context) * 0.015,
                fontWeight: FontWeight.bold,
                //fontFamily: 'Poppins',
              ),
            ),
            profName.length > longStrLength
                ? Tooltip(
                    message: profName,
                    height: 30,
                    textStyle:
                        const TextStyle(fontSize: 15, color: Colors.white),
                    verticalOffset: kDefaultPadding / 2,
                    child: Text(
                      truncateString(profName),
                      style: TextStyle(
                        color: Colors.grey[800],
                        letterSpacing: 2.0,
                        fontSize: screenWidth(context) * 0.015,
                      ),
                    ),
                  )
                : Text(
                    profName,
                    style: TextStyle(
                        color: Colors.grey[800],
                        letterSpacing: 2.0,
                        fontSize: screenWidth(context) * 0.015),
                  ),
          ],
        ),
        SizedBox(
          height: screenHeight(context) * 0.005,
        )
      ],
    );
  }
}
