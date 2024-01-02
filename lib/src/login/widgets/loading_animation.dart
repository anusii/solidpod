/// A method to show animation page in the process of loading.
///
// Time-stamp: <Tuesday 2024-01-02 13:19:25 +1100 Zheyuan Xu>
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
import 'package:loading_indicator/loading_indicator.dart';
import 'package:solid/src/constants/login.dart';

Future<void> showAnimationDialog(
  BuildContext context,
  int animationIndex,
  String alertMsg,
  bool showPathBackground,
) {
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(50),
        child: Center(
          // child: SpinKitThreeBounce(
          //   color: anuCopper,
          //   size: 100.0,
          //   //controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)),
          // ),
          child: SizedBox(
            width: 150,
            height: 250,
            child: Column(
              children: [
                LoadingIndicator(
                  indicatorType: Indicator.values[animationIndex],
                  colors: defaultPodColors,
                  strokeWidth: 4.0,
                  pathBackgroundColor: showPathBackground
                      ? const Color.fromARGB(59, 0, 0, 0)
                      : null,
                ),
                DefaultTextStyle(
                  style: (const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  )),
                  child: Text(
                    alertMsg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

