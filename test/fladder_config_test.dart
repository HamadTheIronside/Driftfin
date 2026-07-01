import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/fladder_config.dart';

void main() {
  tearDown(() {
    FladderConfig.baseUrl = null;
    FladderConfig.seerrBaseUrl = null;
    FladderConfig.sentryDsn = null;
  });

  group('FladderConfig.fromJson', () {
    test('parses all fields from a fully populated config', () {
      FladderConfig.fromJson({
        'baseUrl': 'https://jellyfin.example.com',
        'seerrBaseUrl': 'https://seerr.example.com',
        'sentryDsn': 'https://key@o0.ingest.sentry.io/0',
      });

      expect(FladderConfig.baseUrl, 'https://jellyfin.example.com');
      expect(FladderConfig.seerrBaseUrl, 'https://seerr.example.com');
      expect(FladderConfig.sentryDsn, 'https://key@o0.ingest.sentry.io/0');
    });

    test('null values are preserved as null', () {
      FladderConfig.fromJson({'baseUrl': null, 'seerrBaseUrl': null, 'sentryDsn': null});

      expect(FladderConfig.baseUrl, isNull);
      expect(FladderConfig.seerrBaseUrl, isNull);
      expect(FladderConfig.sentryDsn, isNull);
    });

    test('empty strings are normalized to null', () {
      FladderConfig.fromJson({'baseUrl': '', 'seerrBaseUrl': '', 'sentryDsn': ''});

      expect(FladderConfig.baseUrl, isNull);
      expect(FladderConfig.seerrBaseUrl, isNull);
      expect(FladderConfig.sentryDsn, isNull);
    });

    test('missing keys are treated as null (docker-entrypoint always writes them, but be defensive)', () {
      FladderConfig.fromJson({});

      expect(FladderConfig.baseUrl, isNull);
      expect(FladderConfig.seerrBaseUrl, isNull);
      expect(FladderConfig.sentryDsn, isNull);
    });

    test('replaces the previous config wholesale rather than merging', () {
      FladderConfig.fromJson({'baseUrl': 'https://first.example.com', 'sentryDsn': 'https://first-dsn'});
      FladderConfig.fromJson({'seerrBaseUrl': 'https://second.example.com'});

      expect(FladderConfig.baseUrl, isNull);
      expect(FladderConfig.sentryDsn, isNull);
      expect(FladderConfig.seerrBaseUrl, 'https://second.example.com');
    });
  });

  group('FladderConfig static setters', () {
    test('can be set directly without going through fromJson', () {
      FladderConfig.sentryDsn = 'https://direct-dsn';
      expect(FladderConfig.sentryDsn, 'https://direct-dsn');
    });
  });
}
