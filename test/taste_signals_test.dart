import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/util/taste_signals.dart';

ItemBaseModel _item(
  String id, {
  List<String> genres = const [],
  List<Person> people = const [],
  List<Studio> studios = const [],
  bool played = false,
  double? communityRating,
  int playCount = 0,
  Duration? runTime,
}) {
  return ItemBaseModel(
    name: id,
    id: id,
    overview: OverviewModel(
      genres: genres,
      people: people,
      studios: studios,
      communityRating: communityRating,
      runTime: runTime,
    ),
    parentId: null,
    playlistId: null,
    images: null,
    childCount: null,
    primaryRatio: null,
    userData: UserData(played: played, playCount: playCount),
    canDownload: null,
    canDelete: null,
    jellyType: null,
  );
}

Person _director(String id, String name) => Person(id: id, name: name, type: PersonKind.director);

Person _actor(String id, String name) => Person(id: id, name: name, type: PersonKind.actor);

void main() {
  group('TasteSignals.topGenres', () {
    test('ranks genres by frequency, most common first', () {
      final items = [
        _item('1', genres: const ['Comedy', 'Action']),
        _item('2', genres: const ['Comedy']),
        _item('3', genres: const ['Action']),
        _item('4', genres: const ['Comedy']),
      ];
      final top = TasteSignals.topGenres(items);
      expect(top.first.key, 'Comedy');
      expect(top.first.value, 3);
    });

    test('respects the limit', () {
      final items = [
        _item('1', genres: const ['A']),
        _item('2', genres: const ['B']),
        _item('3', genres: const ['C']),
      ];
      expect(TasteSignals.topGenres(items, limit: 2), hasLength(2));
    });

    test('empty input returns an empty list', () {
      expect(TasteSignals.topGenres(const []), isEmpty);
    });
  });

  group('TasteSignals.topStudios', () {
    test('ranks studios by frequency, most common first', () {
      final a24 = Studio(id: 's1', name: 'A24');
      final marvel = Studio(id: 's2', name: 'Marvel');
      final items = [
        _item('1', studios: [a24]),
        _item('2', studios: [a24, marvel]),
        _item('3', studios: [a24]),
      ];
      final top = TasteSignals.topStudios(items);
      expect(top.first.key, a24);
      expect(top.first.value, 3);
    });

    test('respects the limit', () {
      final items = [
        _item('1', studios: [Studio(id: 's1', name: 'A')]),
        _item('2', studios: [Studio(id: 's2', name: 'B')]),
      ];
      expect(TasteSignals.topStudios(items, limit: 1), hasLength(1));
    });
  });

  group('TasteSignals.topDirectors', () {
    test('dedupes a director appearing across multiple items by id', () {
      final items = [
        _item('1', people: [_director('d1', 'Denis Villeneuve')]),
        _item('2', people: [_director('d1', 'Denis Villeneuve')]),
        _item('3', people: [_director('d2', 'Greta Gerwig')]),
      ];
      final top = TasteSignals.topDirectors(items);
      expect(top.first.key.name, 'Denis Villeneuve');
      expect(top.first.value, 2);
    });

    test('ignores non-director people', () {
      final items = [
        _item('1', people: [_actor('a1', 'Some Actor')]),
      ];
      expect(TasteSignals.topDirectors(items), isEmpty);
    });
  });

  group('TasteSignals.topActors', () {
    test('only counts people typed as actor', () {
      final items = [
        _item('1', people: [_actor('a1', 'Actor One'), _director('d1', 'Director One')]),
      ];
      final top = TasteSignals.topActors(items);
      expect(top, hasLength(1));
      expect(top.single.key.name, 'Actor One');
    });
  });

  group('TasteSignals.hiddenGems', () {
    test('excludes already-played items', () {
      final items = [
        _item('1', communityRating: 9, played: true),
        _item('2', communityRating: 9, played: false),
      ];
      final gems = TasteSignals.hiddenGems(items);
      expect(gems.map((e) => e.id), ['2']);
    });

    test('excludes items below the minimum rating', () {
      final items = [
        _item('1', communityRating: 5),
        _item('2', communityRating: 8),
      ];
      final gems = TasteSignals.hiddenGems(items, minRating: 7);
      expect(gems.map((e) => e.id), ['2']);
    });

    test('sorts by rating descending', () {
      final items = [
        _item('low', communityRating: 7),
        _item('high', communityRating: 9),
      ];
      final gems = TasteSignals.hiddenGems(items);
      expect(gems.first.id, 'high');
    });
  });

  group('TasteSignals.totalWatchTime', () {
    test('multiplies runtime by play count', () {
      final items = [_item('1', runTime: const Duration(minutes: 30), playCount: 2)];
      expect(TasteSignals.totalWatchTime(items), const Duration(minutes: 60));
    });

    test('ignores items with an unknown runtime', () {
      final items = [_item('1', playCount: 5)];
      expect(TasteSignals.totalWatchTime(items), Duration.zero);
    });
  });

  group('TasteSignals.explainSuggestion', () {
    test('explains via a shared favourite genre when present', () {
      final candidate = _item('1', genres: const ['Comedy']);
      final explanation = TasteSignals.explainSuggestion(
        candidate,
        favouriteGenres: const [MapEntry('Comedy', 5)],
        favouriteDirectors: const [],
      );
      expect(explanation, contains('Comedy'));
    });

    test('falls back to a shared favourite director when no genre matches', () {
      final director = _director('d1', 'Denis Villeneuve');
      final candidate = _item('1', people: [director]);
      final explanation = TasteSignals.explainSuggestion(
        candidate,
        favouriteGenres: const [],
        favouriteDirectors: [MapEntry(Person(id: 'd1', name: 'Denis Villeneuve'), 3)],
      );
      expect(explanation, contains('Denis Villeneuve'));
    });

    test('returns null when nothing matches', () {
      final candidate = _item('1', genres: const ['Horror']);
      final explanation = TasteSignals.explainSuggestion(
        candidate,
        favouriteGenres: const [MapEntry('Comedy', 5)],
        favouriteDirectors: const [],
      );
      expect(explanation, isNull);
    });
  });
}
