// Copyright (c) 2018, Sami Zerouta. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

enum LoggingLevel {
  basic,
  headers,
  body,
}

typedef void Logger(String message);

class LoggingClient extends BaseClient {
  final Client _inner;

  final Logger _logger;

  final LoggingLevel _level;

  LoggingLevel get level => _level;

  LoggingClient(
    this._inner, {
    LoggingLevel level,
    Logger logger,
  })
      : _level = level ?? LoggingLevel.basic,
        _logger = logger ?? print;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    bool logBody = _level == LoggingLevel.body;
    bool logHeaders = logBody || _level == LoggingLevel.headers;

    String beginRequestMessage = '--> ${request.method} ${request.url}';
    if (!logHeaders && request.contentLength != null) {
      beginRequestMessage += ' (${request.contentLength}-byte body)';
    }
    _logger(beginRequestMessage);

    if (logHeaders) {
      if (request.contentLength != null) {
        _logger('content-length: ${request.contentLength}');
      }

      request.headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-length') {
          _logger('$key: $value');
        }
      });

      if (!logBody) {
        _logger('--> END ${request.method}');
      } else {
        Encoding encoding = _encoding(request.headers);

        String body = await request.finalize().bytesToString(encoding);

        if (_isPlaintext(body)) {
          if (body.isNotEmpty) {
            _logger(body);
          }
          _logger(
              '--> END ${request.method} (${request.contentLength}-byte body)');
        } else {
          _logger(
              '--> END ${request.method} (${request.contentLength}-byte body omitted)');
        }

        request = _copyRequest(request, body, encoding);
      }
    }

    Stopwatch watch = new Stopwatch()..start();
    StreamedResponse response;

    try {
      response = await _inner.send(request);
    } catch (e) {
      _logger('<-- HTTP FAILED: $e');
      rethrow;
    }

    String beginResponseMessage = '<-- ${response.statusCode}';
    if (response.reasonPhrase != null) {
      beginResponseMessage += ' ${response.reasonPhrase}';
    }
    beginResponseMessage +=
        ' ${response.request.url} (${watch.elapsedMilliseconds}ms';
    if (!logHeaders) {
      beginResponseMessage += ', ';

      if (response.contentLength != null) {
        beginResponseMessage += '${response.contentLength}-byte';
      } else {
        beginResponseMessage += 'unknown-length';
      }
      beginResponseMessage += ' body';
    }
    beginResponseMessage += ')';
    _logger(beginResponseMessage);

    if (logHeaders) {
      response.headers.forEach((key, value) => _logger('$key: $value'));

      if (!logBody) {
        _logger('<-- END HTTP');
      } else {
        Encoding encoding = _encoding(response.headers);

        String body = await response.stream.bytesToString(encoding);

        if (_isPlaintext(body)) {
          if (body.isNotEmpty) {
            _logger(body);
          }
          _logger('<-- END HTTP (${response.contentLength}-byte body)');
        } else {
          _logger(
              '<-- END HTTP (binary ${response.contentLength}-byte body omitted)');
        }

        response = _copyResponse(response, body, encoding);
      }
    }

    return response;
  }

  void close() => _inner.close();

  static BaseRequest _copyRequest(
          BaseRequest original, String body, Encoding encoding) =>
      new Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..persistentConnection = original.persistentConnection
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..body = body
        ..encoding = encoding;

  static StreamedResponse _copyResponse(
          StreamedResponse original, String body, Encoding encoding) =>
      new StreamedResponse(
          new ByteStream.fromBytes(encoding.encode(body)), original.statusCode,
          headers: original.headers,
          contentLength: original.contentLength,
          isRedirect: original.isRedirect,
          persistentConnection: original.persistentConnection,
          reasonPhrase: original.reasonPhrase,
          request: original.request);

  static Encoding _encoding(Map<String, String> headers) {
    String contentType = headers['content-type'];

    if (contentType != null) {
      try {
        MediaType mediaType = new MediaType.parse(contentType);
        String charset = mediaType.parameters['charset'];
        Encoding encoding = Encoding.getByName(charset);

        if (encoding != null) {
          return encoding;
        }
      } catch (_) {}
    }

    return UTF8;
  }

  static bool _isPlaintext(String s) => s.runes
      .take(16)
      .every((rune) => !_isIsoControl(rune) || _isWhitespace(rune));

  static bool _isIsoControl(int rune) =>
      (rune >= 0x00 && rune <= 0x1F) || (rune >= 0x7F && rune <= 0x9F);

  static bool _isWhitespace(int rune) =>
      (rune >= 0x0009 && rune <= 0x000D) ||
      rune == 0x0020 ||
      rune == 0x0085 ||
      rune == 0x00A0 ||
      rune == 0x1680 ||
      rune == 0x180E ||
      (rune >= 0x2000 && rune <= 0x200A) ||
      rune == 0x2028 ||
      rune == 0x2029 ||
      rune == 0x202F ||
      rune == 0x205F ||
      rune == 0x3000 ||
      rune == 0xFEFF;
}
