@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/sonarr_provider.dart';

/// Live integration test against a real Sonarr. Skipped unless
/// SONARR_TEST_URL and SONARR_TEST_APIKEY are set, so it never runs in CI.
///
///   SONARR_TEST_URL=http://localhost:8989 SONARR_TEST_APIKEY=xxx \
///     flutter test test/sonarr_integration_test.dart
void main() {
  final url = Platform.environment['SONARR_TEST_URL'];
  final key = Platform.environment['SONARR_TEST_APIKEY'];
  final configured = url != null && key != null;

  group('SonarrApi (live)', () {
    test('add-if-missing then monitor + search a single episode', () async {
      final api = SonarrApi(baseUrl: url!, apiKey: key!);
      // Firefly (TVDB 78874), S1E1 — a small, finished show.
      final result = await api.requestEpisodeByTvdb(
        tvdbId: 78874,
        season: 1,
        episode: 1,
        addIfMissing: true,
      );
      expect(result, SonarrRequestResult.success);
    });

    test('requesting an episode of an already-added show also succeeds', () async {
      final api = SonarrApi(baseUrl: url!, apiKey: key!);
      // Breaking Bad (TVDB 81189) was added during setup.
      final result = await api.requestEpisodeByTvdb(
        tvdbId: 81189,
        season: 1,
        episode: 2,
        addIfMissing: true,
      );
      expect(result, SonarrRequestResult.success);
    });
  }, skip: configured ? false : 'set SONARR_TEST_URL + SONARR_TEST_APIKEY to run');
}
