/// Utilities for identifying printable file types.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Tony Chen

library;

/// File extensions that are supported for printing.

const Set<String> printableExtensions = {
  '.md',
  '.txt',
  '.json',
  '.yaml',
  '.yml',
  '.log',
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.pdf',
};

/// Text-based extensions that should be rendered as formatted text.

const Set<String> textPrintableExtensions = {
  '.md',
  '.txt',
  '.json',
  '.yaml',
  '.yml',
  '.log',
};

/// Image-based extensions.

const Set<String> imagePrintableExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
};

/// Returns the effective file extension after stripping the `.enc.ttl` suffix
/// used by solidpod for encrypted files.

String getEffectiveExtension(String fileName) {
  final clean = fileName.replaceAll('.enc.ttl', '');
  final dotIndex = clean.lastIndexOf('.');
  if (dotIndex == -1) return '';

  return clean.substring(dotIndex).toLowerCase();
}

/// Whether [fileName] has a printable file extension.

bool isPrintableFile(String fileName) {
  return printableExtensions.contains(getEffectiveExtension(fileName));
}

/// Whether [fileName] is a text-based printable file.

bool isTextPrintableFile(String fileName) {
  return textPrintableExtensions.contains(getEffectiveExtension(fileName));
}

/// Whether [fileName] is an image-based printable file.

bool isImagePrintableFile(String fileName) {
  return imagePrintableExtensions.contains(getEffectiveExtension(fileName));
}

/// Whether [fileName] is a PDF file.

bool isPdfFile(String fileName) {
  return getEffectiveExtension(fileName) == '.pdf';
}
