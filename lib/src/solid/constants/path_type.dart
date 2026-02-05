/// Types of resource path in POD.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
//
// Authors: Dawei Chen

library;

enum PathType {
  /// path is relative to the `data` directory of app,
  /// i.e., the resource is in `podName/appDirectory/data/`.
  relativeToData,

  /// path is relative to the app directory,
  /// i.e., the resource is in `podName/appDirectory/`,
  /// e.g., encryption/ind-keys.ttl
  relativeToApp,

  /// path is relative to the specific POD,
  /// i.e., the resource is in `podName/`,
  /// e.g., profile.ttl
  relativeToPod,

  /// path is an absolute URL,
  /// e.g., https://pods.solidcommunity.au/podName/appDirectory/data/myfile.ttl
  absoluteUrl,
}
