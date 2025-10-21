import 'package:flutter/material.dart';

Future<void> pushReplacement(
    BuildContext context, Widget destinationWidget) async {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => destinationWidget,
    ),
    (Route<dynamic> route) =>
        false, // This predicate ensures all previous routes are removed
  );
}
