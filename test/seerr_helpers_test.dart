import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/seerr/seerr_dashboard_model.dart';
import 'package:driftfin/seerr/seerr_models.dart';
import 'package:driftfin/util/seerr_helpers.dart';

SeerrTvDetails _tvDetails({
  SeerrMediaInfo? mediaInfo,
  List<SeerrSeason>? seasons,
  List<SeerrKeyword>? keywords,
  List<SeerrGenre>? genres,
}) {
  return SeerrTvDetails(
    id: 1,
    name: 'Show',
    mediaInfo: mediaInfo,
    seasons: seasons,
    keywords: keywords,
    genres: genres,
  );
}

void main() {
  group('SeerrHelpers.buildSeasonStatusMap', () {
    test('empty details produce an empty map', () {
      final map = SeerrHelpers.buildSeasonStatusMap(_tvDetails());
      expect(map, isEmpty);
    });

    test('seeds statuses from mediaInfo seasons', () {
      final details = _tvDetails(
        mediaInfo: SeerrMediaInfo(
          seasons: [
            const SeerrMediaInfoSeason(seasonNumber: 1, status: 5), // available
            const SeerrMediaInfoSeason(seasonNumber: 2, status: 2), // pending
          ],
        ),
      );
      final map = SeerrHelpers.buildSeasonStatusMap(details);
      expect(map[1], SeerrMediaStatus.available);
      expect(map[2], SeerrMediaStatus.pending);
    });

    test('ignores mediaInfo seasons with a null seasonNumber', () {
      final details = _tvDetails(
        mediaInfo: SeerrMediaInfo(
          seasons: [const SeerrMediaInfoSeason(seasonNumber: null, status: 5)],
        ),
      );
      expect(SeerrHelpers.buildSeasonStatusMap(details), isEmpty);
    });

    test('a pending request updates all known seasons when it lists none explicitly', () {
      final details = _tvDetails(
        seasons: [SeerrSeason(seasonNumber: 1), SeerrSeason(seasonNumber: 2)],
        mediaInfo: SeerrMediaInfo(
          requests: [SeerrMediaRequest(status: 1)], // pending, no seasons list
        ),
      );
      final map = SeerrHelpers.buildSeasonStatusMap(details);
      expect(map[1], SeerrMediaStatus.pending);
      expect(map[2], SeerrMediaStatus.pending);
    });

    test('a request naming specific seasons only updates those', () {
      final details = _tvDetails(
        seasons: [SeerrSeason(seasonNumber: 1), SeerrSeason(seasonNumber: 2)],
        mediaInfo: SeerrMediaInfo(
          requests: [
            SeerrMediaRequest(status: 2, seasons: [2])
          ], // approved -> processing
        ),
      );
      final map = SeerrHelpers.buildSeasonStatusMap(details);
      expect(map[1], isNull);
      expect(map[2], SeerrMediaStatus.processing);
    });

    test('a request never downgrades an available or deleted season', () {
      final details = _tvDetails(
        mediaInfo: SeerrMediaInfo(
          seasons: [const SeerrMediaInfoSeason(seasonNumber: 1, status: 5)], // available
          requests: [
            SeerrMediaRequest(status: 1, seasons: [1])
          ], // pending request
        ),
      );
      final map = SeerrHelpers.buildSeasonStatusMap(details);
      expect(map[1], SeerrMediaStatus.available, reason: 'available must not be downgraded to pending');
    });

    test('declined/failed/unknown requests are ignored entirely', () {
      final details = _tvDetails(
        seasons: [SeerrSeason(seasonNumber: 1)],
        mediaInfo: SeerrMediaInfo(
          requests: [
            SeerrMediaRequest(status: 3, seasons: [1]), // declined
            SeerrMediaRequest(status: 4, seasons: [1]), // failed
          ],
        ),
      );
      expect(SeerrHelpers.buildSeasonStatusMap(details), isEmpty);
    });

    test('a completed request marks named seasons available', () {
      final details = _tvDetails(
        seasons: [SeerrSeason(seasonNumber: 3)],
        mediaInfo: SeerrMediaInfo(
          requests: [
            SeerrMediaRequest(status: 5, seasons: [3])
          ], // completed
        ),
      );
      expect(SeerrHelpers.buildSeasonStatusMap(details)[3], SeerrMediaStatus.available);
    });
  });

  group('SeerrHelpers.extractContentRating', () {
    test('null or empty list yields null', () {
      expect(SeerrHelpers.extractContentRating(null, 'US'), isNull);
      expect(SeerrHelpers.extractContentRating([], 'US'), isNull);
    });

    test('prefers an exact region match (case-insensitive)', () {
      final ratings = [
        SeerrContentRating(countryCode: 'us', rating: 'PG-13'),
        SeerrContentRating(countryCode: 'DE', rating: '12'),
      ];
      expect(SeerrHelpers.extractContentRating(ratings, 'de'), '12');
    });

    test('falls back to US when the region is not present', () {
      final ratings = [
        SeerrContentRating(countryCode: 'US', rating: 'R'),
        SeerrContentRating(countryCode: 'FR', rating: '16'),
      ];
      expect(SeerrHelpers.extractContentRating(ratings, 'JP'), 'R');
    });

    test('falls back to any rating when neither region nor US present', () {
      final ratings = [SeerrContentRating(countryCode: 'FR', rating: '16')];
      expect(SeerrHelpers.extractContentRating(ratings, 'JP'), '16');
    });

    test('skips entries with a null or empty rating value', () {
      final ratings = [
        SeerrContentRating(countryCode: 'JP', rating: ''),
        SeerrContentRating(countryCode: 'US', rating: 'PG'),
      ];
      expect(SeerrHelpers.extractContentRating(ratings, 'JP'), 'PG');
    });
  });

  group('SeerrHelpers.isAnime', () {
    test('true when a keyword named anime is present', () {
      final details = _tvDetails(keywords: [SeerrKeyword(name: 'Anime')]);
      expect(SeerrHelpers.isAnime(details), isTrue);
    });

    test('true when a genre named animation or anime is present', () {
      expect(SeerrHelpers.isAnime(_tvDetails(genres: [SeerrGenre(name: 'Animation')])), isTrue);
      expect(SeerrHelpers.isAnime(_tvDetails(genres: [SeerrGenre(name: 'anime')])), isTrue);
    });

    test('false when neither keywords nor genres match', () {
      final details = _tvDetails(
        keywords: [SeerrKeyword(name: 'space')],
        genres: [SeerrGenre(name: 'Drama')],
      );
      expect(SeerrHelpers.isAnime(details), isFalse);
    });

    test('false when keywords and genres are both null', () {
      expect(SeerrHelpers.isAnime(_tvDetails()), isFalse);
    });
  });
}
