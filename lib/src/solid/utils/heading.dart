import 'package:flutter/material.dart';

/// Sub heading build function
Row buildHeading(String headingStr, double fontSize,
    [Color? headingColor, double? padding]) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: padding == null ? EdgeInsets.zero : EdgeInsets.all(padding),
        child: Text(
          headingStr,
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: headingColor ?? Colors.black),
        ),
      ),
    ],
  );
}
