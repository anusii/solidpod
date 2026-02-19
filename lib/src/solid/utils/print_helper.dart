/// Utilities for printable file types and PDF generation.
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// File type constants and queries.

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

// Google Fonts CDN URLs.

/// Noto Sans Regular – used for page headers in printed documents.

const String notoSansFontUrl = 'https://fonts.gstatic.com/s/notosans/v36/'
    'o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99d41P6zHtY.ttf';

/// Font cache key for Noto Sans Regular.

const String notoSansFontName = 'NotoSans-Regular';

/// Noto Sans Mono Regular – used for body text in printed documents.

const String notoSansMonoFontUrl =
    'https://fonts.gstatic.com/s/notosansmono/v30/'
    'BngrUXNETWXI6LwhGYvaxZikqZqK6fBq6kPvUce2oAZcdthSBUsYck4-_FNJ49rXVEQQL8Y.ttf';

/// Font cache key for Noto Sans Mono Regular.

const String notoSansMonoFontName = 'NotoSansMono-Regular';

// Content helpers.

/// Tries to base64-decode [content]; falls back to raw UTF-8 bytes.

Uint8List decodeContentBytes(String content) {
  try {
    return base64Decode(content);
  } on FormatException {
    return Uint8List.fromList(utf8.encode(content));
  }
}

// PDF generation.

/// Parameters for [generateTextPdf].
///
/// All fields are isolate-safe primitives or typed data so the object can be
/// sent across isolate boundaries by [compute].

class TextPdfParams {
  /// The text content to render.

  final String content;

  /// File name shown in the page header.

  final String fileName;

  /// Page dimensions and margins.

  final double pageWidth;
  final double pageHeight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  /// Raw TTF bytes for the header font. Empty means use a built-in fallback.

  final Uint8List headerFontBytes;

  /// Raw TTF bytes for the body font. Empty means use a built-in fallback.

  final Uint8List contentFontBytes;

  const TextPdfParams({
    required this.content,
    required this.fileName,
    required this.pageWidth,
    required this.pageHeight,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
    required this.headerFontBytes,
    required this.contentFontBytes,
  });
}

/// Parameters for [generateImagePdf].

class ImagePdfParams {
  /// Raw image bytes (JPEG, PNG, or GIF).

  final Uint8List imageBytes;

  /// Page dimensions and margins.

  final double pageWidth;
  final double pageHeight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const ImagePdfParams({
    required this.imageBytes,
    required this.pageWidth,
    required this.pageHeight,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
  });
}

/// Generates a paginated text PDF.
///
/// This is a top-level function so it can be called from a background isolate
/// via [compute]. Font bytes are reconstructed into [pw.Font] objects inside
/// the isolate; when empty the built-in Latin-1 fonts are used as a fallback.

Future<Uint8List> generateTextPdf(TextPdfParams p) async {
  final headerFont = p.headerFontBytes.isNotEmpty
      ? pw.Font.ttf(p.headerFontBytes.buffer.asByteData())
      : pw.Font.helvetica();

  final contentFont = p.contentFontBytes.isNotEmpty
      ? pw.Font.ttf(p.contentFontBytes.buffer.asByteData())
      : pw.Font.courier();

  final format = PdfPageFormat(
    p.pageWidth,
    p.pageHeight,
    marginTop: p.marginTop,
    marginBottom: p.marginBottom,
    marginLeft: p.marginLeft,
    marginRight: p.marginRight,
  );

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      header: (pw.Context ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          p.fileName,
          style: pw.TextStyle(
            font: headerFont,
            color: PdfColors.grey600,
            fontSize: 10,
          ),
        ),
      ),
      build: (pw.Context ctx) {
        final style = pw.TextStyle(font: contentFont, fontSize: 10);

        // Split into individual lines so MultiPage can paginate between
        // them. A single pw.Text holding the entire content would exceed
        // the page height for long files and is not a SpanningWidget.

        return p.content.split('\n').map((line) {
          return pw.Text(line.isEmpty ? ' ' : line, style: style);
        }).toList();
      },
    ),
  );

  return await doc.save();
}

/// Generates a single-page image PDF.
///
/// This is a top-level function so it can be called from a background isolate
/// via [compute].

Future<Uint8List> generateImagePdf(ImagePdfParams p) async {
  final format = PdfPageFormat(
    p.pageWidth,
    p.pageHeight,
    marginTop: p.marginTop,
    marginBottom: p.marginBottom,
    marginLeft: p.marginLeft,
    marginRight: p.marginRight,
  );

  final doc = pw.Document();
  final image = pw.MemoryImage(p.imageBytes);

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (pw.Context ctx) => pw.Center(
        child: pw.Image(image, fit: pw.BoxFit.contain),
      ),
    ),
  );

  return await doc.save();
}
