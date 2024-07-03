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
/// Authors: Dawei Chen

library;

import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:http/http.dart' as http;

import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/constants/common.dart';

class CssApiClient {
  static final _client = http.Client();

  static Future<void> pushBinaryData(String fileUrl,
      {required Stream<List<int>> stream,
      required int contentLength,
      void Function(double)? progressFunc}) async {
    const httpMethod = 'PUT';
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, httpMethod);
    final request = http.StreamedRequest(httpMethod, Uri.parse(fileUrl))
      ..headers.addAll({
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': ResourceContentType.binary.value,
        'Content-Length': contentLength.toString(),
        'DPoP': dPopToken,
      });

    int sentSize = 0;
    print('contentLength: $contentLength');

    // stream.listen(request.sink.add);
    stream.listen((chunk) {
      debugPrint('chunk size: ${chunk.length}');
      request.sink.add(chunk);
      sentSize += chunk.length;
      final percent = sentSize * 100.0 / contentLength;
      print('Progress: $percent%');
      // await Future.delayed(const Duration(seconds: 1));
      sleep(Duration(seconds: 1));
      if (progressFunc != null) {
        progressFunc(sentSize * 1.0 / contentLength);
      }
    },
        onDone: () => unawaited(request.sink.close()),
        onError: (e) => print('Error occurred: $e'));

    // final response = await request.send().then(http.Response.fromStream);
    // final response = await _client.send(request).then(http.Response.fromStream);
    final response = await _client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send data!'
          '\nURL: $fileUrl'
          '\nERROR: ${response.headers}');
    }
  }

  static Future<Stream<List<int>>> pullBinaryData(String fileUrl) async {
    const httpMethod = 'GET';
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, httpMethod);

    final request = http.Request(httpMethod, Uri.parse(fileUrl))
      ..headers.addAll({
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': ResourceContentType.binary.value,
        'DPoP': dPopToken,
      });

    final response = await _client.send(request);
    return response.stream.cast<List<int>>();
  }

  static Future<Map<String, String>> getResourceHeaders(String fileUrl) async {
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, 'HEAD');

    final request = http.Request('HEAD', Uri.parse(fileUrl))
      ..headers.addAll(
        {
          'Accept': '*/*',
          'Authorization': 'DPoP $accessToken',
          'Connection': 'keep-alive',
          'DPoP': dPopToken,
        },
      );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    print(response.statusCode);
    // print(response.headers);
    // print(response.contentLength); // this is 0
    print(response.headers['content-length']); // file size in bytes

    return response.headers;
  }

  // void downloadByHttp(Uri url, File file) async {
  //   var client = http.Client();
  //   var request = http.Request("GET", url);
  //   var response = await client.send(request);
  //   var sink = file.openWrite();
  //   await response.stream.pipe(sink);
  //   sink.close();
  // }
}
