/// Initial setup page constants.
///
// Time-stamp: <Tuesday 2024-04-02 21:36:29 +1100 Graham Williams>
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
/// Authors: Anushka Vidanage

library;

import 'package:flutter/material.dart';

/// Color variables used in initial setup screen.

const lightGreen = Color.fromARGB(255, 120, 219, 137);

/// Color variables used in initial setup screen.

const darkBlue = Color.fromARGB(255, 7, 87, 153);

/// Color variables used in initial setup screen.

// const kTitleTextColor = Color(0xFF30384D);

/// Padding value for initial setup screen.

// const double kDefaultPadding = 20.0;

/// Text string variables used for the welcome message.

const initialStructureWelcome = 'Welcome to the Solid Pod Setup Wizard!';

/// Text string variables as the title of the message box.

const initialStructureTitle = 'Solid Pod';

/// Text string variables used for informing the user about the creatiion of
/// different resources.

const initialStructureMsg = 'We notice that you have either created'
    ' a new Solid Pod or your Pod has some missing files/folders'
    ' (called resources).'
    ' We will now setup the required resources to fully support'
    ' the app functionalities.';

/// The string key of input form for the input of security key

const securityKeyStr = 'SecurityKey';

/// Text string variables used for informing the user about the input of
/// security key for encryption.

const requiredSecurityKeyMsg =
    'A security key (or key for short) is used to make your data private'
    ' (using encryption) when it is stored in your Solid Pod.'
    ' This could be the password you use to login to your'
    ' Solid Pod (not recommended) or a different one (highly recommended).'
    ' You will need to remember this key to access your data -'
    ' a lost key means your data will also be lost.'
    ' Please provide a security key and confirm it below. Thanks.';

/// Text string variables used for informing the user about the creation of
/// public/private key pair for secure data sharing.

const publicKeyMsg =
    'We will also create a random public/private key pair for secure data'
    ' sharing with other Solid Pods.';
