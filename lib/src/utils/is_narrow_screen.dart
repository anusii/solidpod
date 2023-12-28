import 'package:flutter/material.dart';

const int narrowScreenLimit = 1175;

bool isNarrowScreen(BuildContext context) =>
    MediaQuery.of(context).size.width < narrowScreenLimit;
