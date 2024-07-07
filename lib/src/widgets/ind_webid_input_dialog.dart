// import 'package:flutter/material.dart';

// /// A dialog for adding an individual webId
//   void indWebIdDialog(BuildContext context, Function setStateFunc) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           insetPadding: const EdgeInsets.symmetric(horizontal: 50),
//           title: const Text('WebID of the recipient'),
//           content: Column(mainAxisSize: MainAxisSize.min, children: [
//             // Web ID text field
//             TextFormField(
//               controller: formControllerWebId,
//               decoration: const InputDecoration(
//                   hintText:
//                       'Eg: https://pods.solidcommunity.au/john-doe/profile/card#me'),
//             ),
//           ]),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () async {
//                 final receiverWebId = formControllerWebId.text.trim();

//                 // Check the web ID field is not empty and it is a true link
//                 if (receiverWebId.isNotEmpty &&
//                     Uri.parse(receiverWebId.replaceAll('#me', '')).isAbsolute &&
//                     await checkResourceStatus(receiverWebId) ==
//                         ResourceStatus.exist) {
//                   setState(() {
//                     selectedRecipient = 'individual';
//                     selectedRecipientDetails = receiverWebId;
//                     finalWebIdList = [receiverWebId];
//                   });
//                   Navigator.of(context).pop();
//                 } else {
//                   await _alert('Please enter a valid WebID');
//                 }
//               },
//               child: const Text('Ok'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }