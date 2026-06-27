import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:driftfin/providers/sonarr_provider.dart';

void main() {
  const base = 'http://sonarr.test:8989';
  const key = 'APIKEY';

  SonarrApi api(http.Client client) => SonarrApi(baseUrl: base, apiKey: key, client: client);

  group('normalizeSonarrUrl', () {
    test('trims and strips trailing slashes', () {
      expect(normalizeSonarrUrl('  http://host:8989/  '), 'http://host:8989');
      expect(normalizeSonarrUrl('http://host:8989///'), 'http://host:8989');
      expect(normalizeSonarrUrl('http://host:8989'), 'http://host:8989');
    });
  });

  group('SonarrSettings', () {
    test('isConfigured requires enabled + url + key', () {
      expect(const SonarrSettings(enabled: true, baseUrl: 'x', apiKey: 'k').isConfigured, isTrue);
      expect(const SonarrSettings(enabled: false, baseUrl: 'x', apiKey: 'k').isConfigured, isFalse);
      expect(const SonarrSettings(enabled: true, baseUrl: '', apiKey: 'k').isConfigured, isFalse);
      expect(const SonarrSettings(enabled: true, baseUrl: 'x', apiKey: '').isConfigured, isFalse);
    });

    test('json round-trip', () {
      const settings = SonarrSettings(enabled: true, baseUrl: 'http://h', apiKey: 'k');
      final restored = SonarrSettings.fromJson(settings.toJson());
      expect(restored.enabled, isTrue);
      expect(restored.baseUrl, 'http://h');
      expect(restored.apiKey, 'k');
    });
  });

  group('SonarrApi', () {
    test('findSeriesIdByTvdb matches tvdbId and sends api-key header', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode([
            {'id': 1, 'tvdbId': 111},
            {'id': 7, 'tvdbId': 222},
          ]),
          200,
        );
      });
      expect(await api(client).findSeriesIdByTvdb(222), 7);
      expect(captured.url.toString(), '$base/api/v3/series');
      expect(captured.headers['X-Api-Key'], key);
    });

    test('findSeriesIdByTvdb returns null when not found', () async {
      final client = MockClient((req) async => http.Response(jsonEncode([
            {'id': 1, 'tvdbId': 111}
          ]), 200));
      expect(await api(client).findSeriesIdByTvdb(999), isNull);
    });

    test('findSeriesIdByTvdb returns null on non-200', () async {
      final client = MockClient((req) async => http.Response('nope', 401));
      expect(await api(client).findSeriesIdByTvdb(111), isNull);
    });

    test('findEpisodeId matches season+episode and queries seriesId', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode([
            {'id': 10, 'seasonNumber': 1, 'episodeNumber': 1},
            {'id': 20, 'seasonNumber': 2, 'episodeNumber': 5},
          ]),
          200,
        );
      });
      expect(await api(client).findEpisodeId(7, 2, 5), 20);
      expect(captured.url.path, '/api/v3/episode');
      expect(captured.url.queryParameters['seriesId'], '7');
    });

    test('monitorEpisodes PUTs episode/monitor with monitored=true', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('', 202);
      });
      expect(await api(client).monitorEpisodes([20]), isTrue);
      expect(captured.method, 'PUT');
      expect(captured.url.toString(), '$base/api/v3/episode/monitor');
      expect(jsonDecode(captured.body), {'episodeIds': [20], 'monitored': true});
    });

    test('searchEpisodes POSTs EpisodeSearch command', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('', 201);
      });
      expect(await api(client).searchEpisodes([20]), isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.toString(), '$base/api/v3/command');
      expect(jsonDecode(captured.body), {'name': 'EpisodeSearch', 'episodeIds': [20]});
    });

    test('requestEpisodeByTvdb happy path: success + correct call sequence', () async {
      final calls = <String>[];
      final client = MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        return switch (req.url.path) {
          '/api/v3/series' => http.Response(jsonEncode([
              {'id': 7, 'tvdbId': 222}
            ]), 200),
          '/api/v3/episode' => http.Response(jsonEncode([
              {'id': 20, 'seasonNumber': 2, 'episodeNumber': 5}
            ]), 200),
          '/api/v3/episode/monitor' => http.Response('', 202),
          '/api/v3/command' => http.Response('', 201),
          _ => http.Response('not found', 404),
        };
      });
      expect(
        await api(client).requestEpisodeByTvdb(tvdbId: 222, season: 2, episode: 5),
        SonarrRequestResult.success,
      );
      expect(calls, [
        'GET /api/v3/series',
        'GET /api/v3/episode',
        'PUT /api/v3/episode/monitor',
        'POST /api/v3/command',
      ]);
    });

    test('requestEpisodeByTvdb -> seriesNotFound', () async {
      final client = MockClient((req) async => http.Response(jsonEncode([]), 200));
      expect(
        await api(client).requestEpisodeByTvdb(tvdbId: 1, season: 1, episode: 1),
        SonarrRequestResult.seriesNotFound,
      );
    });

    test('requestEpisodeByTvdb -> episodeNotFound', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/api/v3/series') {
          return http.Response(jsonEncode([
            {'id': 7, 'tvdbId': 222}
          ]), 200);
        }
        return http.Response(jsonEncode([]), 200);
      });
      expect(
        await api(client).requestEpisodeByTvdb(tvdbId: 222, season: 9, episode: 9),
        SonarrRequestResult.episodeNotFound,
      );
    });

    test('requestEpisodeByTvdb -> failed when the search command errors', () async {
      final client = MockClient((req) async {
        return switch (req.url.path) {
          '/api/v3/series' => http.Response(jsonEncode([
              {'id': 7, 'tvdbId': 222}
            ]), 200),
          '/api/v3/episode' => http.Response(jsonEncode([
              {'id': 20, 'seasonNumber': 2, 'episodeNumber': 5}
            ]), 200),
          '/api/v3/episode/monitor' => http.Response('', 202),
          _ => http.Response('err', 500),
        };
      });
      expect(
        await api(client).requestEpisodeByTvdb(tvdbId: 222, season: 2, episode: 5),
        SonarrRequestResult.failed,
      );
    });
  });
}
