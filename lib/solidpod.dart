/// Support for flutter apps accessing solid PODs.
///
// Time-stamp: <Monday 2024-04-22 15:19:23 +1000 Graham Williams>
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
/// Authors: Graham Williamss

library solidpod;

export 'src/solid/login.dart'
    show
        SolidLogin,
        LoginButtonStyle,
        ContinueButtonStyle,
        RegisterButtonStyle,
        InfoButtonStyle;
export 'src/solid/popup_login.dart' show SolidPopupLogin;

// TODO 20240417 gjw Can we please list or at least document what and why the
// following are exported, PLEASE. ReadPod() I understand, but what from
// rest_api?

export 'src/solid/api/rest_api.dart' show getFileContent;
export 'src/solid/common_func.dart';
export 'src/solid/utils/misc.dart';
export 'src/solid/utils/key_management.dart' show KeyManager;
export 'src/widgets/change_key_dialog.dart' show changeKeyPopup;
export 'src/solid/read_pod.dart' show readPod;
export 'src/solid/write_pod.dart' show writePod;
export 'src/widgets/logout_dialog.dart' show logoutPopup;
