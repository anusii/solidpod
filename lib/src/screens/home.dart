library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import 'package:solid/src/widgets/show_animation_dialog.dart';

const darkBlue = Color.fromARGB(255, 7, 87, 153);

class Home extends StatefulWidget {
  final String webId;
  final Map authData;

  const Home({super.key, required this.webId, required this.authData});

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
