import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/episode_model.dart';
import 'package:driftfin/models/items/images_models.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/radarr_provider.dart';
import 'package:driftfin/providers/sonarr_provider.dart';
import 'package:driftfin/util/item_query_fields.dart';
import 'package:driftfin/util/timed_cache.dart';

/// A single airing in the calendar (an episode). Merged from Jellyfin "upcoming"
/// (navigable, in-library) and the Sonarr calendar (richer, incl. not-yet-grabbed).
class CalendarEntry {
  final DateTime airDate; // local
  final String seriesTitle;
  final int? season;
  final int? episode;
  final String episodeTitle;
  final bool hasFile;
  final ItemBaseModel? item; // navigable Jellyfin item, null for Sonarr/Radarr-only
  final ImageData? image;
  final bool isMovie;

  const CalendarEntry({
    required this.airDate,
    required this.seriesTitle,
    required this.season,
    required this.episode,
    required this.episodeTitle,
    required this.hasFile,
    required this.item,
    required this.image,
    this.isMovie = false,
  });

  String get codeLabel => (season != null && episode != null) ? 'S${season}E$episode' : '';
  String get dedupeKey => isMovie ? 'movie|${seriesTitle.toLowerCase()}' : '${seriesTitle.toLowerCase()}|$season|$episode';
}

/// Groups entries by local calendar day, each day's list sorted by air time.
Map<DateTime, List<CalendarEntry>> groupCalendarByDay(List<CalendarEntry> entries) {
  final sorted = [...entries]..sort((a, b) => a.airDate.compareTo(b.airDate));
  final byDay = <DateTime, List<CalendarEntry>>{};
  for (final entry in sorted) {
    final day = DateTime(entry.airDate.year, entry.airDate.month, entry.airDate.day);
    (byDay[day] ??= []).add(entry);
  }
  return byDay;
}

final _calendarCache = TimedCache<String, Map<DateTime, List<CalendarEntry>>>(ttl: const Duration(minutes: 15));

void refreshCalendar() => _calendarCache.clear();

/// Upcoming/airing episodes grouped by day. Combines Jellyfin "upcoming" with
/// the Sonarr calendar when Sonarr is configured. Cached for 15 minutes.
final calendarProvider = FutureProvider.autoDispose<Map<DateTime, List<CalendarEntry>>>((ref) async {
  const cacheKey = 'calendar';
  final cached = _calendarCache.get(cacheKey);
  if (cached != null) return cached;

  final now = DateTime.now();
  final entries = <CalendarEntry>[];
  final seen = <String>{};

  // Jellyfin: upcoming episodes for shows in the library (navigable).
  try {
    final response = await ref.read(jellyApiProvider).showsUpcoming(limit: 100, fields: posterItemFields);
    for (final dto in response.body?.items ?? const []) {
      final item = ItemBaseModel.fromBaseDto(dto, ref);
      if (item is EpisodeModel && item.dateAired != null) {
        final entry = CalendarEntry(
          airDate: item.dateAired!.toLocal(),
          seriesTitle: item.seriesName ?? item.name,
          season: item.season,
          episode: item.episode,
          episodeTitle: item.name,
          hasFile: false,
          item: item,
          image: item.images?.primary ?? item.getPosters?.primary,
        );
        if (seen.add(entry.dedupeKey)) entries.add(entry);
      }
    }
  } catch (_) {/* best-effort */}

  // Sonarr: full calendar (includes not-yet-grabbed episodes).
  try {
    final sonarr = await ref.read(sonarrProvider.notifier).calendar(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 35)),
        );
    for (final item in sonarr) {
      final airDateUtc = item.airDateUtc;
      if (airDateUtc == null) continue;
      final entry = CalendarEntry(
        airDate: airDateUtc.toLocal(),
        seriesTitle: item.seriesTitle,
        season: item.seasonNumber,
        episode: item.episodeNumber,
        episodeTitle: item.episodeTitle,
        hasFile: item.hasFile,
        item: null,
        image: null,
      );
      if (seen.add(entry.dedupeKey)) entries.add(entry);
    }
  } catch (_) {/* best-effort */}

  // Radarr: upcoming movie releases (if configured).
  try {
    final movies = await ref.read(radarrProvider.notifier).calendar(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 35)),
        );
    for (final movie in movies) {
      final releaseDate = movie.releaseDate;
      if (releaseDate == null) continue;
      final entry = CalendarEntry(
        airDate: releaseDate.toLocal(),
        seriesTitle: movie.title,
        season: null,
        episode: null,
        episodeTitle: '',
        hasFile: movie.hasFile,
        item: null,
        image: null,
        isMovie: true,
      );
      if (seen.add(entry.dedupeKey)) entries.add(entry);
    }
  } catch (_) {/* best-effort */}

  final grouped = groupCalendarByDay(entries);
  _calendarCache.set(cacheKey, grouped);
  return grouped;
});
