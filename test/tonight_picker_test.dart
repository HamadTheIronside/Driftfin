import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/util/tonight_picker.dart';

ItemBaseModel _item(
  String id, {
  Duration? runTime,
  double? communityRating,
  List<String> genres = const [],
  bool played = false,
  double progress = 0,
}) {
  return ItemBaseModel(
    name: id,
    id: id,
    overview: OverviewModel(runTime: runTime, communityRating: communityRating, genres: genres),
    parentId: null,
    playlistId: null,
    images: null,
    childCount: null,
    primaryRatio: null,
    userData: UserData(played: played, progress: progress),
    canDownload: null,
    canDelete: null,
    jellyType: null,
  );
}

void main() {
  group('TonightPicker.pick', () {
    test('dedupes candidates by id, keeping the first occurrence', () {
      final a = _item('1', communityRating: 9);
      final duplicate = _item('1', communityRating: 1);
      final result = TonightPicker.pick([a, duplicate]);
      expect(result, hasLength(1));
      expect(result.single.overview.communityRating, 9);
    });

    test('caps at maxPicks even with a larger pool', () {
      final pool = List.generate(10, (i) => _item('$i', communityRating: i.toDouble()));
      final result = TonightPicker.pick(pool);
      expect(result.length, TonightPicker.maxPicks);
    });

    test('sorts highest scoring (community rating) first', () {
      final low = _item('low', communityRating: 3);
      final high = _item('high', communityRating: 9);
      final result = TonightPicker.pick([low, high]);
      expect(result.first.id, 'high');
    });

    test('penalizes already-played items below unplayed ones', () {
      // played scores 9 - 4 = 5; unplayed scores 6 - 0 = 6, so despite the
      // lower raw rating, unplayed should still come out ahead.
      final played = _item('played', communityRating: 9, played: true);
      final unplayed = _item('unplayed', communityRating: 6);
      final result = TonightPicker.pick([played, unplayed]);
      expect(result.first.id, 'unplayed');
    });

    test('boosts items matching the requested mood genres', () {
      final comedy = _item('comedy', communityRating: 5, genres: const ['Comedy']);
      final drama = _item('drama', communityRating: 5, genres: const ['Documentary']);
      final result = TonightPicker.pick([comedy, drama], mood: TonightMood.funny);
      expect(result.first.id, 'comedy');
    });

    test('every mood other than any maps to at least one genre keyword', () {
      for (final mood in TonightMood.values) {
        if (mood == TonightMood.any) {
          expect(mood.genreKeywords, isEmpty);
        } else {
          expect(mood.genreKeywords, isNotEmpty, reason: '$mood should have at least one genre keyword');
        }
      }
    });

    test('boosts family/adventure items for an uplifting mood', () {
      final uplifting = _item('uplifting', communityRating: 5, genres: const ['Adventure']);
      final horror = _item('horror', communityRating: 5, genres: const ['Horror']);
      final result = TonightPicker.pick([uplifting, horror], mood: TonightMood.uplifting);
      expect(result.first.id, 'uplifting');
    });

    test('filters out items that do not fit the time budget', () {
      final shorts = List.generate(
        3,
        (i) => _item('short-$i', runTime: const Duration(minutes: 20), communityRating: 5),
      );
      final long = _item('long', runTime: const Duration(hours: 3), communityRating: 9);
      final result = TonightPicker.pick(
        [...shorts, long],
        timeAvailable: const Duration(minutes: 30),
      );
      expect(result.every((e) => e.id.startsWith('short')), isTrue);
    });

    test('keeps items with unknown runtime regardless of the time budget', () {
      final unknownRuntime = _item('unknown', communityRating: 5);
      final result = TonightPicker.pick(
        [unknownRuntime],
        timeAvailable: const Duration(minutes: 10),
      );
      expect(result, isNotEmpty);
    });

    test('relaxes the time budget rather than returning fewer than minPicks', () {
      final tooLong = List.generate(
        5,
        (i) => _item('long-$i', runTime: const Duration(hours: 3), communityRating: i.toDouble()),
      );
      final result = TonightPicker.pick(tooLong, timeAvailable: const Duration(minutes: 30));
      expect(result.length, greaterThanOrEqualTo(TonightPicker.minPicks));
    });

    test('empty input returns an empty list', () {
      expect(TonightPicker.pick(const []), isEmpty);
    });
  });
}
