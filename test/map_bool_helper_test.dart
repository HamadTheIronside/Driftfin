import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/map_bool_helper.dart';

void main() {
  group('MapExtensions on Map<T, bool>', () {
    test('toggleKey flips only the matching key', () {
      final map = {'a': true, 'b': false, 'c': true};
      final result = map.toggleKey('b');
      expect(result, {'a': true, 'b': true, 'c': true});
    });

    test('toggleKey with missing key changes nothing', () {
      final map = {'a': true, 'b': false};
      final result = map.toggleKey('z');
      expect(result, map);
    });

    test('setKey sets the matching key to the given value', () {
      final map = {'a': true, 'b': false};
      expect(map.setKey('a', false), {'a': false, 'b': false});
      expect(map.setKey('b', true), {'a': true, 'b': true});
    });

    test('setKey with null wantedKey changes nothing', () {
      final map = {'a': true, 'b': false};
      expect(map.setKey(null, true), map);
    });

    test('setKeys sets multiple keys', () {
      final map = {'a': false, 'b': false, 'c': false};
      final result = map.setKeys(['a', 'c'], true);
      expect(result, {'a': true, 'b': false, 'c': true});
    });

    test('setKeys with empty iterable changes nothing', () {
      final map = {'a': false, 'b': true};
      expect(map.setKeys([], true), map);
    });

    test('setAll sets every value to the given bool', () {
      final map = {'a': true, 'b': false, 'c': true};
      expect(map.setAll(false), {'a': false, 'b': false, 'c': false});
      expect(map.setAll(true), {'a': true, 'b': true, 'c': true});
    });

    test('included returns keys with true value', () {
      final map = {'a': true, 'b': false, 'c': true};
      expect(map.included, ['a', 'c']);
    });

    test('included on empty map returns empty list', () {
      expect(<String, bool>{}.included, isEmpty);
    });

    test('notIncluded returns keys with false value', () {
      final map = {'a': true, 'b': false, 'c': true};
      expect(map.notIncluded, ['b']);
    });

    test('enabledFirst reorders enabled entries before disabled', () {
      final map = {'a': false, 'b': true, 'c': false, 'd': true};
      final result = map.enabledFirst;
      expect(result.keys.toList(), ['b', 'd', 'a', 'c']);
    });

    test('enabledFirst on all-disabled map preserves order', () {
      final map = {'a': false, 'b': false};
      expect(map.enabledFirst.keys.toList(), ['a', 'b']);
    });

    test('hasEnabled is true if any value is true', () {
      expect({'a': false, 'b': true}.hasEnabled, isTrue);
      expect({'a': false, 'b': false}.hasEnabled, isFalse);
      expect(<String, bool>{}.hasEnabled, isFalse);
    });

    test('replaceMap returns this unchanged when oldMap is empty', () {
      final map = {'a': true, 'b': false};
      expect(map.replaceMap({}), same(map));
    });

    test('replaceMap replaces values from oldMap, defaulting missing keys to false', () {
      final map = {'a': true, 'b': true, 'c': true};
      final oldMap = {'a': false, 'b': true};
      final result = map.replaceMap(oldMap);
      expect(result, {'a': false, 'b': true, 'c': false});
    });

    test('replaceMap with enabledOnly keeps own value unless oldMap has it enabled', () {
      final map = {'a': false, 'b': false, 'c': true};
      final oldMap = {'a': true, 'b': false};
      final result = map.replaceMap(oldMap, enabledOnly: true);
      expect(result, {'a': true, 'b': false, 'c': true});
    });

    test('sortByKey sorts entries using the key selector', () {
      final map = {'banana': true, 'apple': false, 'cherry': true};
      final result = map.sortByKey((k) => k);
      expect(result.keys.toList(), ['apple', 'banana', 'cherry']);
      expect(result, {'apple': false, 'banana': true, 'cherry': true});
    });

    test('sortByKey on single-element map', () {
      final map = {'only': true};
      expect(map.sortByKey((k) => k).keys.toList(), ['only']);
    });
  });

  group('MapExtensionsGeneric', () {
    test('setKey replaces value for matching key', () {
      final map = {'a': 1, 'b': 2};
      expect(map.setKey('a', 99), {'a': 99, 'b': 2});
    });

    test('setKey with unmatched key changes nothing', () {
      final map = {'a': 1, 'b': 2};
      expect(map.setKey('z', 99), map);
    });

    test('setKeys replaces multiple keys with the same value', () {
      final map = {'a': 1, 'b': 2, 'c': 3};
      expect(map.setKeys(['a', 'c'], 0), {'a': 0, 'b': 2, 'c': 0});
    });

    test('setKeys with empty map', () {
      expect(<String, int>{}.setKeys(['a'], 1), <String, int>{});
    });
  });
}
