import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/models/items/episode_model.dart';
import 'package:driftfin/models/items/series_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';

/// Outcome of a direct-Sonarr episode request.
enum SonarrRequestResult {
  success,
  notConfigured,
  seriesNotFound,
  episodeNotFound,
  failed,
}

/// Direct Sonarr integration so a single episode can be monitored + searched
/// — something Jellyseerr/Overseerr can't do (its requests are season-level).
/// This talks to Sonarr's v3 API directly and only works for shows already
/// added to Sonarr. Standard season/episode numbering (anime absolute numbering
/// is not handled).
class SonarrSettings {
  final String baseUrl;
  final String apiKey;
  final bool enabled;

  const SonarrSettings({this.baseUrl = '', this.apiKey = '', this.enabled = false});

  bool get isConfigured => enabled && baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  SonarrSettings copyWith({String? baseUrl, String? apiKey, bool? enabled}) => SonarrSettings(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {'baseUrl': baseUrl, 'apiKey': apiKey, 'enabled': enabled};

  factory SonarrSettings.fromJson(Map<String, dynamic> json) => SonarrSettings(
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
      );
}

const String _sonarrSettingsKey = 'sonarrSettings';

final sonarrProvider = StateNotifierProvider<SonarrNotifier, SonarrSettings>((ref) {
  return SonarrNotifier(ref);
});

class SonarrNotifier extends StateNotifier<SonarrSettings> {
  SonarrNotifier(this.ref) : super(_load(ref)) {
    _client = http.Client();
  }

  final Ref ref;
  late final http.Client _client;

  static SonarrSettings _load(Ref ref) {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_sonarrSettingsKey);
      if (raw == null || raw.isEmpty) return const SonarrSettings();
      return SonarrSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const SonarrSettings();
    }
  }

  void _persist() => ref.read(sharedPreferencesProvider).setString(_sonarrSettingsKey, jsonEncode(state.toJson()));

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
    _persist();
  }

  void setBaseUrl(String value) {
    // Strip a trailing slash so '/api/v3/...' joins cleanly.
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    state = state.copyWith(baseUrl: normalized);
    _persist();
  }

  void setApiKey(String value) {
    state = state.copyWith(apiKey: value.trim());
    _persist();
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${state.baseUrl}/api/v3/$path').replace(queryParameters: query);

  Map<String, String> get _headers => {'X-Api-Key': state.apiKey, 'Content-Type': 'application/json'};

  /// Resolves the show's TVDB id from the Jellyfin episode, then monitors and
  /// searches that single episode in Sonarr.
  Future<SonarrRequestResult> requestEpisode(EpisodeModel episode) async {
    if (!state.isConfigured) return SonarrRequestResult.notConfigured;
    final seriesId = episode.parentId;
    if (seriesId == null) return SonarrRequestResult.seriesNotFound;

    try {
      final seriesItem = await ref.read(jellyApiProvider).usersUserIdItemsItemIdGet(itemId: seriesId);
      final series = seriesItem.body;
      final providerIds = series is SeriesModel ? series.providerIds : null;
      final rawTvdb = providerIds?['Tvdb'];
      final tvdbId = rawTvdb is int ? rawTvdb : int.tryParse(rawTvdb?.toString() ?? '');
      if (tvdbId == null) return SonarrRequestResult.seriesNotFound;

      final sonarrSeriesId = await _findSeriesIdByTvdb(tvdbId);
      if (sonarrSeriesId == null) return SonarrRequestResult.seriesNotFound;

      final episodeId = await _findEpisodeId(sonarrSeriesId, episode.season, episode.episode);
      if (episodeId == null) return SonarrRequestResult.episodeNotFound;

      await _monitorEpisodes([episodeId]);
      final searched = await _searchEpisodes([episodeId]);
      return searched ? SonarrRequestResult.success : SonarrRequestResult.failed;
    } catch (_) {
      return SonarrRequestResult.failed;
    }
  }

  Future<int?> _findSeriesIdByTvdb(int tvdbId) async {
    final response = await _client.get(_uri('series'), headers: _headers);
    if (response.statusCode != 200) return null;
    final list = jsonDecode(response.body) as List<dynamic>;
    final match = list.firstWhereOrNull((series) => series['tvdbId'] == tvdbId);
    return match?['id'] as int?;
  }

  Future<int?> _findEpisodeId(int seriesId, int season, int episode) async {
    final response = await _client.get(_uri('episode', {'seriesId': '$seriesId'}), headers: _headers);
    if (response.statusCode != 200) return null;
    final list = jsonDecode(response.body) as List<dynamic>;
    final match = list
        .firstWhereOrNull((entry) => entry['seasonNumber'] == season && entry['episodeNumber'] == episode);
    return match?['id'] as int?;
  }

  Future<bool> _monitorEpisodes(List<int> episodeIds) async {
    final response = await _client.put(
      _uri('episode/monitor'),
      headers: _headers,
      body: jsonEncode({'episodeIds': episodeIds, 'monitored': true}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> _searchEpisodes(List<int> episodeIds) async {
    final response = await _client.post(
      _uri('command'),
      headers: _headers,
      body: jsonEncode({'name': 'EpisodeSearch', 'episodeIds': episodeIds}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
