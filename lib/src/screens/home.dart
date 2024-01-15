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

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

/// Defines a constant color `darkBlue` using ARGB values.

const darkBlue = Color.fromARGB(255, 7, 87, 153);

/// Widget represents the home screen of the application.
///
/// It requires [webId] and [authData] to be passed to it during initialization.
/// These parameters are used for authentication and data retrieval.

class Home extends StatefulWidget {

  const Home({required this.webId, required this.authData, super.key});
  final String webId;
  final Map authData;

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
    String dateStr =
        DateFormat('dd MMMM yyyy').format(DateTime.now()).toString();

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
          // Container(
          //     padding: const EdgeInsets.all(10),
          //     child: SplittedMarkdownFormField(
          //       controller: _textController,
          //       markdownSyntax: '## Headline',
          //       decoration: const InputDecoration(
          //         hintText: 'Editable text',
          //       ),
          //       emojiConvert: true,
          //     )),
          // const SizedBox(
          //   height: 20,
          // ),
          // Container(
          //   padding: const EdgeInsets.only(left: 20, right: 20),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     children: [
          //       ElevatedButton(
          //         onPressed: () async {
          //           if (formKey.currentState?.saveAndValidate() ?? false) {
          //             // Loading animation
          //             showAnimationDialog(
          //               context,
          //               17,
          //               'Saving the note!',
          //               false,
          //             );

          //             Map formData = formKey.currentState?.value as Map;
          //             String noteText = _textController!.text;
          //             // Note title need to be spaceless as we are using that name
          //             // to create a .acl file. And the acl file url cannot have spaces
          //             // String noteTitle =
          //             //     formData['noteTitle'].split(' ').join('_');

          //             String noteTitle =
          //                 formData['noteTitle'].replaceAll('\n', '');

          //             // By default all notes will be encrypted before storing in
          //             // a POD

          //             // Get the master key
          //             String masterKey = await secureStorage.read(
          //                   key: widget.webId,
          //                 ) ??
          //                 '';

          //             // Hash plaintext master key to get hashed master key
          //             String encKey = sha256
          //                 .convert(utf8.encode(masterKey))
          //                 .toString()
          //                 .substring(0, 32);

          //             // Get date and time
          //             String dateTimeStr = DateFormat('yyyyMMddTHHmmss')
          //                 .format(DateTime.now())
          //                 .toString();

          //             // Create a random session key
          //             final indKey = encrypt.Key.fromSecureRandom(32);

          //             // Encrypt markdown text using random session key
          //             final dataEncryptIv = encrypt.IV.fromLength(16);
          //             final dataEncrypter = encrypt.Encrypter(
          //                 encrypt.AES(indKey, mode: encrypt.AESMode.cbc));
          //             final dataEncryptVal =
          //                 dataEncrypter.encrypt(noteText, iv: dataEncryptIv);
          //             String dataEncryptValStr =
          //                 dataEncryptVal.base64.toString();

          //             // Encrypt random key using the master key
          //             final keyEncrypt = encrypt.Key.fromUtf8(encKey);
          //             final keyEncryptIv = encrypt.IV.fromLength(16);
          //             final keyEncryptEncrypter1 = encrypt.Encrypter(
          //                 encrypt.AES(keyEncrypt, mode: encrypt.AESMode.cbc));
          //             final keyEncryptVal = keyEncryptEncrypter1
          //                 .encrypt(indKey.base64, iv: keyEncryptIv);
          //             String keyEncryptValStr = keyEncryptVal.base64.toString();

          //             // Create encrypted data ttl file body
          //             String encNoteFileBody = genEncryptedNoteFileBody(
          //                 dateTimeStr,
          //                 noteTitle,
          //                 dataEncryptValStr,
          //                 dataEncryptIv.base64);

          //             // print(keyEncryptValStr);
          //             // print('');
          //             // print(encNoteFileBody);

          //             // Create note file name
          //             // String noteFileName =
          //             //     '$noteFileNamePrefix$noteTitle-$dateTimeStr.ttl';
          //             String noteFileName =
          //                 '$noteFileNamePrefix$dateTimeStr.ttl';
          //             String noteAclFileName = '$noteFileName.acl';

          //             // Create ACL file body for the note file
          //             String noteFileAclBody =
          //                 genPrvFileAclBody(noteAclFileName, widget.webId);

          //             // Create ttl file to store encrypted note data on the POD
          //             String createNoteFileRes = await createItem(
          //                 true,
          //                 noteFileName,
          //                 encNoteFileBody,
          //                 widget.webId,
          //                 widget.authData,
          //                 fileLoc: '$myNotesDirLoc/',
          //                 fileType: fileType[noteFileName.split('.').last],
          //                 aclFlag: false);

          //             if (createNoteFileRes == 'ok') {
          //               // Create acl file to store acl file data on the POD
          //               String createAclFileRes = await createItem(
          //                   true,
          //                   noteAclFileName,
          //                   noteFileAclBody,
          //                   widget.webId,
          //                   widget.authData,
          //                   fileLoc: '$myNotesDirLoc/',
          //                   fileType: fileType[noteAclFileName.split('.').last],
          //                   aclFlag: true);

          //               if (createAclFileRes == 'ok') {
          //                 // Store the encrypted session key on the POD
          //                 String updateIndKeyFileRes = await updateIndKeyFile(
          //                   widget.webId,
          //                   widget.authData,
          //                   noteFileName,
          //                   keyEncryptValStr,
          //                   '$myNotesDirLoc/$noteFileName',
          //                   keyEncryptIv.base64,
          //                 );

          //                 if (updateIndKeyFileRes == 'ok') {
          //                   // ignore: use_build_context_synchronously
          //                   Navigator.pop(context);
          //                 } else {
          //                   // ignore: use_build_context_synchronously
          //                   Navigator.pop(context);
          //                   // ignore: use_build_context_synchronously
          //                   showErrDialog(context,
          //                       'Failed to update the individual key. Try again!');
          //                 }
          //               } else {
          //                 // ignore: use_build_context_synchronously
          //                 Navigator.pop(context);
          //                 // ignore: use_build_context_synchronously
          //                 showErrDialog(context,
          //                     'Failed to create the ACL resoruce. Try again!');
          //               }
          //             } else {
          //               // ignore: use_build_context_synchronously
          //               Navigator.pop(context);
          //               // ignore: use_build_context_synchronously
          //               showErrDialog(context,
          //                   'Failed to store the note file in your POD. Try again!');
          //             }
          //           } else {
          //             showErrDialog(context,
          //                 'Note name validation failed! Try using a different name.');
          //           }

          //           // Redirect to the home page
          //         },
          //         style: ElevatedButton.styleFrom(
          //           foregroundColor: darkBlue,
          //           backgroundColor: lightBlue, // foreground
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: 40,
          //           ),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(20),
          //           ),
          //         ),
          //         child: const Text(
          //           'SAVE NOTE',
          //           style: TextStyle(color: Colors.white),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(
          //   height: 10,
          // ),
        ],
      ),
    );
  }
}
