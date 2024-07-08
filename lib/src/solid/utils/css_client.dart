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
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:dio/dio.dart';
import 'package:chunked_uploader/chunked_uploader.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:solidpod/src/solid/utils/misc.dart';
import 'package:solidpod/src/solid/constants/common.dart';

class CSSClient {
  static http.Client? _client;
  static Dio? _dio;

  static Future<void> streamUp1(String fileUrl, File file) async {
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, 'PUT');
    // _dio ??= Dio();

    final dio = Dio(BaseOptions(
      headers: {
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': ResourceContentType.binary.value,
        'Content-Length': '${await file.length()}',
        'DPoP': dPopToken,
      },
    ));
    final uploader = ChunkedUploader(dio);

    // using data stream
    final response = await uploader.upload(
      fileName: path.basename(file.path),
      fileSize: await file.length(),
      fileDataStream: file.openRead(),
      maxChunkSize: 65536,
      path: fileUrl,
      method: 'PUT',
      onUploadProgress: (progress) => print(progress),
    );

    debugPrint('Response status: ${response!.statusCode}');
  }

  static Future<void> streamUp(String fileUrl, File file) async {
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, 'PUT');
    _dio ??= Dio();
    final response = await _dio!.put(
      fileUrl,
      data: file.openRead(),
      options: Options(headers: {
        'Accept': '*/*',
        'Authorization': 'DPoP $accessToken',
        'Connection': 'keep-alive',
        'Content-Type': ResourceContentType.binary.value,
        'Content-Length': '${await file.length()}',
        'DPoP': dPopToken,
      }),
      onSendProgress: (int sent, int total) {
        debugPrint('Sent: $sent / $total (${sent * 100 ~/ total}%)');
      },
    );

    debugPrint('Response status: ${response.statusCode}');
  }

  static Future<Stream<Uint8List>> streamDown0(String fileUrl) async {
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, 'GET');
    _dio ??= Dio();
    var q = 0;
    final response = await _dio!.get(fileUrl,
        options: Options(responseType: ResponseType.stream, headers: {
          'Accept': '*/*',
          'Authorization': 'DPoP $accessToken',
          'Connection': 'keep-alive',
          'Content-Type': ResourceContentType.binary.value,
          'DPoP': dPopToken,
        }), onReceiveProgress: (int count, int total) {
      final percent = count * 100 ~/ total;
      if (percent / 10 == q) {
        q += 1;
        debugPrint('Received: $count / $total ($percent %)');
      }
    });

    final stream = response.data.stream;
    print(stream.runtimeType);
    _dio!.close();

    return stream as Stream<Uint8List>;
  }

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
      sleep(const Duration(milliseconds: 10));
      if (progressFunc != null) {
        progressFunc(sentSize * 1.0 / contentLength);
      }
    },
        onDone: () => unawaited(request.sink.close()),
        onError: (e) => print('Error occurred: $e'));

    // final response = await request.send().then(http.Response.fromStream);
    // final response = await _client.send(request).then(http.Response.fromStream);
    final response = await _client!.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send data!'
          '\nURL: $fileUrl'
          '\nERROR: ${response.headers}');
    }
  }

  static Future<void> sendDataChunk(String fileUrl,
      {required int byteStart,
      required int byteEnd,
      // required int byteTotal,
      required List<int> chunk}) async {
    final items = fileUrl.split('/');
    final name = items.last;
    final parentUrl = '${items.getRange(0, items.length - 1).join('/')}/';
    const httpMethod = 'PATCH';

    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, httpMethod);

    final response =
        await http.patch(Uri.parse(fileUrl), // Uri.parse(parentUrl),
            headers: {
              'Accept': '*/*',
              'Authorization': 'DPoP $accessToken',
              'Connection': 'keep-alive',
              'Content-Type': ResourceContentType.binary.value,
              'Content-Range': 'bytes $byteStart-$byteEnd/*',
              // 'Content-Length': '$byteTotal',
              'Link': fileTypeLink,
              'Slug': name,
              'DPoP': dPopToken,
            },
            body: chunk);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send data chunk (bytes: $byteStart-$byteEnd)'
          '\nURL: $fileUrl'
          '\nERROR: ${response.body}');
    }
  }

  static Future<Uint8List> getDataChunk(String fileUrl,
      {int byteStart = 0, int? byteEnd}) async {
    const httpMethod = 'GET';
    final (:accessToken, :dPopToken) =
        await getTokensForResource(fileUrl, httpMethod);

    final response = await http.get(Uri.parse(fileUrl), headers: {
      'Accept': '*/*',
      'Authorization': 'DPoP $accessToken',
      'Connection': 'keep-alive',
      'Content-Type': ResourceContentType.binary.value,
      'Range': 'bytes=$byteStart-${byteEnd ?? ""}',
      'DPoP': dPopToken,
    });

    // final response = await _client.send(request);
    // return response.stream.cast<List<int>>();
    // print(response.statusCode);
    if ([200, 206].contains(response.statusCode)) {
      return response.bodyBytes;
    } else {
      throw Exception(
          'Failed to get data chunk (bytes: $byteStart-${byteEnd ?? 'END'})');
    }
  }

  static Future<Stream<List<int>>> streamDown(String fileUrl) async {
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

    final response = await _client!.send(request);
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

    final streamedResponse = await _client!.send(request);
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
