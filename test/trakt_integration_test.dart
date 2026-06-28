@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/trakt_provider.dart';

/// Live Trakt integration test. Skipped unless TRAKT_CLIENT_ID/SECRET and
/// TRAKT_ACCESS_TOKEN are set, so it never runs in CI. Uses low progress so it
/// does NOT mark anything watched in the account (Trakt only records history at
/// >=80%).
void main() {
  final id = Platform.environment['TRAKT_CLIENT_ID'];
  final secret = Platform.environment['TRAKT_CLIENT_SECRET'];
  final token = Platform.environment['TRAKT_ACCESS_TOKEN'];
  final configured = id != null && secret != null && token != null;

  group('Trakt (live)', () {
    test('scrobble start + stop a movie at low progress (no watched entry)', () async {
      final api = TraktApi(clientId: id!, clientSecret: secret!, accessToken: token);
      // Fight Club (TMDB 550). Low progress so Trakt discards it (<80%).
      final start = await api.scrobble(TraktScrobbleAction.start, ids: {'tmdb': 550}, isMovie: true, progress: 1.0);
      expect(start, isTrue, reason: 'scrobble start should be accepted');
      final stop = await api.scrobble(TraktScrobbleAction.stop, ids: {'tmdb': 550}, isMovie: true, progress: 1.0);
      expect(stop, isTrue, reason: 'scrobble stop should be accepted');
    });
  }, skip: configured ? false : 'set TRAKT_CLIENT_ID/SECRET + TRAKT_ACCESS_TOKEN to run');
}
