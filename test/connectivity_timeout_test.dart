import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/connectivity_provider.dart';

void main() {
  group('fetchSystemInfoDynamic timeout', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    test('tolerates a slow server that responds within a few seconds', () async {
      // Regression test: the health check used to time out after 1 second,
      // which is too aggressive for slow/congested LANs and caused false
      // "server offline" reports. It should now tolerate a multi-second delay.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ServerName': 'test', 'Id': 'abc', 'Version': '1.0.0'}));
        await request.response.close();
      });

      final baseUrl = 'http://${server.address.host}:${server.port}';
      final result = await fetchSystemInfoDynamic(baseUrl);

      expect(result, isNotNull);
      expect(result?.serverName, 'test');
    });

    test('still times out eventually for a server that never responds', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        // Never respond - simulates an unreachable/hung server.
      });

      final baseUrl = 'http://${server.address.host}:${server.port}';
      final stopwatch = Stopwatch()..start();
      final result = await fetchSystemInfoDynamic(baseUrl);
      stopwatch.stop();

      expect(result, isNull);
      expect(stopwatch.elapsed, greaterThan(const Duration(seconds: 4)));
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
