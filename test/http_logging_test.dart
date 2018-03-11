// Copyright (c) 2018, Sami Zerouta. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:http_logging/http_logging.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('get', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient(
              (request) async => new Response('', 200, reasonPhrase: 'OK')),
          level: LoggingLevel.basic,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/ (0-byte body)'),
            matches(
                '<-- 200 OK https://www.dartlang.org/ \\(\\d+ms, 0-byte body\\)'),
          ]));
    });

    test('post', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient(
              (request) async => new Response('', 200, reasonPhrase: 'OK')),
          level: LoggingLevel.basic,
          logger: logs.add);

      await client.post('https://www.dartlang.org/', body: 'Hi?');

      expect(
          logs,
          orderedEquals([
            equals('--> POST https://www.dartlang.org/ (3-byte body)'),
            matches(
                '<-- 200 OK https://www.dartlang.org/ \\(\\d+ms, 0-byte body\\)'),
          ]));
    });

    test('response boby', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response('Hello!', 200,
              reasonPhrase: 'OK',
              headers: {'content-type': 'text/plain; charset=utf-8'})),
          level: LoggingLevel.basic,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/ (0-byte body)'),
            matches(
                '<-- 200 OK https://www.dartlang.org/ \\(\\d+ms, 6-byte body\\)'),
          ]));
    });

    test('streamed response boby', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient.streaming((request, _) async => new StreamedResponse(
              new Stream.fromIterable([
                [0x48, 0x65],
                [0x6c, 0x6c],
                [0x6f, 0x21]
              ]),
              200,
              reasonPhrase: 'OK',
              headers: {'content-type': 'text/plain; charset=utf-8'})),
          level: LoggingLevel.basic,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/ (0-byte body)'),
            matches(
                '<-- 200 OK https://www.dartlang.org/ \\(\\d+ms, unknown-length body\\)'),
          ]));
    });
  });

  group('headers', () {
    test('get', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response('', 200,
              reasonPhrase: 'OK', headers: {'content-length': '0'})),
          level: LoggingLevel.headers,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/'),
            equals('content-length: 0'),
            equals('--> END GET'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-length: 0'),
            equals('<-- END HTTP'),
          ]));
    });

    test('post', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response('', 200,
              reasonPhrase: 'OK', headers: {'content-length': '0'})),
          level: LoggingLevel.headers,
          logger: logs.add);

      await client.post('https://www.dartlang.org/',
          body: 'Hi?', headers: {'content-type': 'text/plain; charset=utf-8'});

      expect(
          logs,
          orderedEquals([
            equals('--> POST https://www.dartlang.org/'),
            equals('content-length: 3'),
            equals('content-type: text/plain; charset=utf-8'),
            equals('--> END POST'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-length: 0'),
            equals('<-- END HTTP'),
          ]));
    });

    test('response boby', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response('Hello!', 200,
                  reasonPhrase: 'OK',
                  headers: {
                    'content-length': '6',
                    'content-type': 'text/plain; charset=utf-8'
                  })),
          level: LoggingLevel.headers,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/'),
            equals('content-length: 0'),
            equals('--> END GET'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-length: 6'),
            equals('content-type: text/plain; charset=utf-8'),
            equals('<-- END HTTP'),
          ]));
    });
  });

  group('body', () {
    test('get', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response('', 200,
              reasonPhrase: 'OK', headers: {'content-length': '0'})),
          level: LoggingLevel.body,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/'),
            equals('content-length: 0'),
            equals('--> END GET (0-byte body)'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-length: 0'),
            equals('<-- END HTTP (0-byte body)'),
          ]));
    });

    test('post', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response('', 200,
              reasonPhrase: 'OK', headers: {'content-length': '0'})),
          level: LoggingLevel.body,
          logger: logs.add);

      await client.post('https://www.dartlang.org/', body: 'Hi?');

      expect(
          logs,
          orderedEquals([
            equals('--> POST https://www.dartlang.org/'),
            equals('content-length: 3'),
            equals('content-type: text/plain; charset=utf-8'),
            equals('Hi?'),
            equals('--> END POST (3-byte body)'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-length: 0'),
            equals('<-- END HTTP (0-byte body)'),
          ]));
    });

    test('get malformed charset', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response(
              'Body with unknown charset', 200,
              reasonPhrase: 'OK',
              headers: {'content-type': 'text/html; charset=0'})),
          level: LoggingLevel.body,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/'),
            equals('content-length: 0'),
            equals('--> END GET (0-byte body)'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-type: text/html; charset=0'),
            equals('Body with unknown charset'),
            equals('<-- END HTTP (25-byte body)'),
          ]));
    });

    test('reponse body is binary', () async {
      List<String> logs = [];
      Client client = new LoggingClient(
          new MockClient((request) async => new Response.bytes(
              UTF8.encode(new String.fromCharCodes(
                  [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
              200,
              reasonPhrase: 'OK',
              headers: {'content-type': 'image/png; charset=utf-8'})),
          level: LoggingLevel.body,
          logger: logs.add);

      await client.get('https://www.dartlang.org/');

      expect(
          logs,
          orderedEquals([
            equals('--> GET https://www.dartlang.org/'),
            equals('content-length: 0'),
            equals('--> END GET (0-byte body)'),
            matches('<-- 200 OK https://www.dartlang.org/ \\(\\d+ms\\)'),
            equals('content-type: image/png; charset=utf-8'),
            equals('<-- END HTTP (binary 9-byte body omitted)'),
          ]));
    });
  });
}
