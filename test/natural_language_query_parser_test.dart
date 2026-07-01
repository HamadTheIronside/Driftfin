import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:driftfin/util/natural_language_query_parser.dart';

void main() {
  group('NaturalLanguageQueryParser.parse', () {
    test('parses mood, runtime budget and "haven\'t seen" from a full sentence', () {
      final result = NaturalLanguageQueryParser.parse("cozy slow-burn mysteries under 2 hours I haven't seen");
      expect(result.genres, containsAll(['Family', 'Romance', 'Drama', 'Mystery']));
      expect(result.maxRuntime, const Duration(hours: 2));
      expect(result.unseenOnly, isTrue);
      expect(result.favoritesOnly, isFalse);
    });

    test('parses a runtime budget given in minutes', () {
      final result = NaturalLanguageQueryParser.parse('something funny under 45 minutes');
      expect(result.maxRuntime, const Duration(minutes: 45));
      expect(result.genres, contains('Comedy'));
    });

    test('detects favourites-only requests', () {
      final result = NaturalLanguageQueryParser.parse('my favorite movies');
      expect(result.favoritesOnly, isTrue);
    });

    test('a plain title falls back to a leftover search term', () {
      final result = NaturalLanguageQueryParser.parse('batman');
      expect(result.genres, isEmpty);
      expect(result.searchTerm, 'batman');
    });

    test('drops filler stop words from the leftover search term', () {
      final result = NaturalLanguageQueryParser.parse('the office');
      expect(result.searchTerm, 'office');
    });

    test('unplayed filter is only added when unseen phrasing is present', () {
      final withUnseen = NaturalLanguageQueryParser.parse("haven't seen this");
      final withoutUnseen = NaturalLanguageQueryParser.parse('something to watch');
      expect(withUnseen.filters, contains(ItemFilter.isunplayed));
      expect(withoutUnseen.filters, isEmpty);
    });

    test('hasStructuredSignal is false only when nothing was parsed', () {
      expect(const NaturalLanguageQuery().hasStructuredSignal, isFalse);
      expect(NaturalLanguageQueryParser.parse('funny').hasStructuredSignal, isTrue);
    });
  });
}
