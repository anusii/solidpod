/// Home page after user creating account.
///
// Time-stamp: <Friday 2024-01-12 09:42:28 +1100 Graham Williams>
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
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:markdown_editor_plus/widgets/splitted_markdown_form_field.dart';
import 'package:solid/src/screens/initial_setup_desktop.dart';
import 'package:solid/src/solid/api/rest_api.dart';
import 'package:solid/src/widgets/error_dialog.dart';
import 'package:solid/src/widgets/loading_screen.dart';
import 'package:solid/src/widgets/show_animation_dialog.dart';

/// Defines a constant color `darkBlue` using ARGB values.

const darkBlue = Color.fromARGB(255, 7, 87, 153);

String createdDateTimePred = 'createdDateTime';
String modifiedDateTimePred = 'modifiedDateTime';
String noteTitlePred = 'noteTitle';
String encNoteContentPred = 'encNoteContent';
String noteFileNamePrefix = 'note-';

/// Generates the body of an encrypted note file in Turtle (Terse RDF Triple Language) format.
///
/// This function constructs a string representing an RDF (Resource Description Framework)
/// data model.
/// The data model includes metadata such as creation and modification dates, title, and
/// encrypted content of the note.

String genEncryptedNoteFileBody(
  String dateTimeStr,
  String noteTitle,
  String encNoteContent,
  String encNoteIv,
) {
  final encNoteFileBody =
      '@prefix : <#>.\n@prefix foaf: <$foaf>.\n@prefix terms: <$terms>.\n@prefix appsTerms: <$appsTerms>.\n:me\n    a foaf:PersonalProfileDocument;\n    terms:title "Encrypted Note";\n    appsTerms:$createdDateTimePred "$dateTimeStr";\n    appsTerms:$modifiedDateTimePred "$dateTimeStr";\n    appsTerms:$ivPred "$encNoteIv";\n    appsTerms:$noteTitlePred "$noteTitle";\n    appsTerms:$encNoteContentPred "$encNoteContent".';

  return encNoteFileBody;
}

/// Generates a private file ACL (Access Control List) body.
///
/// This function constructs the ACL body for a specified file, allowing
/// controlled access to it. It uses the WebID of the user and the file name
/// to create ACL rules. These rules define who can access the file and the
/// level of access they have.

String genPrvFileAclBody(String fileName, String webId) {
  final webIdStr = webId.replaceAll('me', '');
  final resName = fileName.replaceAll('.acl', '');
  final prvFileBody =
      '@prefix : <#>.\n@prefix acl: <$acl>.\n@prefix p: <$webIdStr>.\n\n:ControlReadWrite\n    a acl:Authorization;\n    acl:accessTo <$resName>;\n    acl:agent p:me;\n    acl:mode acl:Control, acl:Read, acl:Write.';

  return prvFileBody;
}

/// Widget represents the home screen of the application.
///
/// It requires [webId] and [authData] to be passed to it during initialization.
/// These parameters are used for authentication and data retrieval.

class Home extends StatefulWidget {
  const Home(
      {required this.webId,
      required this.authData,
      required this.appName,
      super.key});
  final String webId;
  final String appName;
  final Map<dynamic, dynamic> authData;

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TextEditingController? _textController;
  final formKey = GlobalKey<FormBuilderState>();
  String sampleText = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    const myNotesDir = 'data';

    final myNotesDirLoc = '${widget.appName}/$myNotesDir';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: FormBuilder(
                key: formKey,
                onChanged: () {
                  formKey.currentState!.save();
                  debugPrint(formKey.currentState!.value.toString());
                },
                autovalidateMode: AutovalidateMode.disabled,
                skipDisabled: true,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: $dateStr',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    FormBuilderTextField(
                      name: 'noteTitle',
                      decoration: const InputDecoration(
                        labelText: 'Note Title',
                        labelStyle: TextStyle(
                          color: darkBlue,
                          letterSpacing: 1.5,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                        //errorText: 'error',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                  ],
                )),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
              padding: const EdgeInsets.all(10),
              child: SplittedMarkdownFormField(
                controller: _textController,
                markdownSyntax: '## Headline',
                decoration: const InputDecoration(
                  hintText: 'Editable text',
                ),
                emojiConvert: true,
              )),
          const SizedBox(
            height: 20,
          ),
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.saveAndValidate() ?? false) {
                      // Loading animation
                      showAnimationDialog(
                        context,
                        17,
                        'Saving the note!',
                        false,
                      );

                      final formData = formKey.currentState?.value as Map;
                      final noteText = _textController!.text;

                      // Note title need to be spaceless as we are using that name
                      // to create a .acl file. And the acl file url cannot have spaces.
                      

                      final noteTitle =
                          formData['noteTitle'].toString().replaceAll('\n', '');

                      // By default all notes will be encrypted before storing in
                      // a POD.

                      // Get the master key.

                      final masterKey = await secureStorage.read(
                            key: widget.webId,
                          ) ??
                          '';

                      // Hash plaintext master key to get hashed master key.

                      final encKey = sha256
                          .convert(utf8.encode(masterKey))
                          .toString()
                          .substring(0, 32);

                      // Get date and time.

                      final dateTimeStr =
                          DateFormat('yyyyMMddTHHmmss').format(DateTime.now());

                      // Create a random session key.

                      final indKey = encrypt.Key.fromSecureRandom(32);

                      // Encrypt markdown text using random session key.
                      
                      final dataEncryptIv = encrypt.IV.fromLength(16);
                      final dataEncrypter = encrypt.Encrypter(
                          encrypt.AES(indKey, mode: encrypt.AESMode.cbc));
                      final dataEncryptVal =
                          dataEncrypter.encrypt(noteText, iv: dataEncryptIv);
                      final dataEncryptValStr =
                          dataEncryptVal.base64.toString();

                      // Encrypt random key using the master key.

                      final keyEncrypt = encrypt.Key.fromUtf8(encKey);
                      final keyEncryptIv = encrypt.IV.fromLength(16);
                      final keyEncryptEncrypter1 = encrypt.Encrypter(
                          encrypt.AES(keyEncrypt, mode: encrypt.AESMode.cbc));
                      final keyEncryptVal = keyEncryptEncrypter1
                          .encrypt(indKey.base64, iv: keyEncryptIv);
                      final keyEncryptValStr = keyEncryptVal.base64;

                      // Create encrypted data ttl file body.

                      final encNoteFileBody = genEncryptedNoteFileBody(
                          dateTimeStr,
                          noteTitle,
                          dataEncryptValStr,
                          dataEncryptIv.base64);

                      // Create note file name
                      // String noteFileName =
                      //     '$noteFileNamePrefix$noteTitle-$dateTimeStr.ttl';

                      final noteFileName =
                          '$noteFileNamePrefix$dateTimeStr.ttl';
                      final noteAclFileName = '$noteFileName.acl';

                      // Create ACL file body for the note file.

                      final noteFileAclBody =
                          genPrvFileAclBody(noteAclFileName, widget.webId);

                      // Create ttl file to store encrypted note data on the POD.

                      final createNoteFileRes = await createItem(
                          true,
                          noteFileName,
                          encNoteFileBody,
                          widget.webId,
                          widget.authData,
                          fileLoc: '$myNotesDirLoc/',
                          fileType: fileType[noteFileName.split('.').last]);

                      if (createNoteFileRes == 'ok') {
                        // Create acl file to store acl file data on the POD.

                        final createAclFileRes = await createItem(
                            true,
                            noteAclFileName,
                            noteFileAclBody,
                            widget.webId,
                            widget.authData,
                            fileLoc: '$myNotesDirLoc/',
                            fileType: fileType[noteAclFileName.split('.').last],
                            aclFlag: true);

                        if (createAclFileRes == 'ok') {
                          // Store the encrypted session key on the POD.

                          final updateIndKeyFileRes = await updateIndKeyFile(
                              widget.webId,
                              widget.authData,
                              noteFileName,
                              keyEncryptValStr,
                              '$myNotesDirLoc/$noteFileName',
                              keyEncryptIv.base64,
                              widget.appName);

                          if (updateIndKeyFileRes == 'ok') {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          } else {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                            // ignore: use_build_context_synchronously
                            showErrDialog(context,
                                'Failed to update the individual key. Try again!');
                          }
                        } else {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          // ignore: use_build_context_synchronously
                          showErrDialog(context,
                              'Failed to create the ACL resoruce. Try again!');
                        }
                      } else {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                        // ignore: use_build_context_synchronously
                        showErrDialog(context,
                            'Failed to store the note file in your POD. Try again!');
                      }
                    } else {
                      showErrDialog(context,
                          'Note name validation failed! Try using a different name.');
                    }

                    // Redirect to the home page
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: darkBlue,
                    backgroundColor: lightBlue, // foreground
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'SAVE NOTE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
