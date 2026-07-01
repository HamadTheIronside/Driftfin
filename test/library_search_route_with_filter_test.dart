import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/library_filter_model.dart';
import 'package:driftfin/routes/auto_router.gr.dart';
import 'package:driftfin/screens/library_search/library_search_screen.dart';

void main() {
  group('LibrarySearchRouteExtension.withFilter', () {
    test('carries genres, studios, tags, years and official ratings through to the route', () {
      final a24 = Studio(id: 's1', name: 'A24');
      final model = LibraryFilterModel(
        genres: const {'Sci-Fi': true},
        studios: {a24: true},
        tags: const {'Feel Good': true},
        years: const {1999: true},
        officialRatings: const {'PG-13': true},
        favourites: true,
        recursive: false,
      );

      final route = LibrarySearchRoute().withFilter(model);
      final args = route.args!;

      expect(args.genres, {'Sci-Fi': true});
      expect(args.studios, {a24: true});
      expect(args.tags, {'Feel Good': true});
      expect(args.years, {1999: true});
      expect(args.officialRatings, {'PG-13': true});
      expect(args.favourites, isTrue);
      expect(args.recursive, isFalse);
    });

    test('carries an empty filter through without dropping keys entirely', () {
      const model = LibraryFilterModel();
      final args = LibrarySearchRoute().withFilter(model).args!;

      expect(args.studios, isEmpty);
      expect(args.tags, isEmpty);
      expect(args.years, isEmpty);
      expect(args.officialRatings, isEmpty);
    });
  });

  group('LibrarySearchScreen', () {
    test('defaults new filter fields to an empty map when not passed via the route', () {
      const screen = LibrarySearchScreen();
      expect(screen.studios, isNull);
      expect(screen.tags, isNull);
      expect(screen.years, isNull);
      expect(screen.officialRatings, isNull);
    });

    test('accepts the full set of filter fields', () {
      final a24 = Studio(id: 's1', name: 'A24');
      final screen = LibrarySearchScreen(
        studios: {a24: true},
        tags: const {'Feel Good': true},
        years: const {1999: true},
        officialRatings: const {'PG-13': true},
      );
      expect(screen.studios, {a24: true});
      expect(screen.tags, {'Feel Good': true});
      expect(screen.years, {1999: true});
      expect(screen.officialRatings, {'PG-13': true});
    });
  });
}
