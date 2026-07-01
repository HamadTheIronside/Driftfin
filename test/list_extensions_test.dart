import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/list_extensions.dart';

void main() {
  group('reorderInPlace', () {
    test('moves item forward', () {
      final list = [1, 2, 3, 4];
      list.reorderInPlace(0, 3);
      expect(list, [2, 3, 1, 4]);
    });

    test('moves item backward', () {
      final list = [1, 2, 3, 4];
      list.reorderInPlace(3, 0);
      expect(list, [4, 1, 2, 3]);
    });

    test('same index is a no-op', () {
      final list = [1, 2, 3];
      list.reorderInPlace(1, 1);
      expect(list, [1, 2, 3]);
    });

    test('moving to the very next index is a no-op (ReorderableListView semantics)', () {
      // newIndex follows Flutter's ReorderableListView.onReorder convention:
      // it's the index in the list *before* the item is removed, so moving
      // index 0 to "index 1" lands the item back where it started.
      final list = [1, 2, 3];
      list.reorderInPlace(0, 1);
      expect(list, [1, 2, 3]);
    });

    test('moving to two positions ahead performs an adjacent-style swap', () {
      final list = [1, 2, 3];
      list.reorderInPlace(0, 2);
      expect(list, [2, 1, 3]);
    });
  });

  group('reordered', () {
    test('returns a new list without mutating the original', () {
      final original = [1, 2, 3, 4];
      final result = original.reordered(0, 3);
      expect(result, [2, 3, 1, 4]);
      expect(original, [1, 2, 3, 4]);
    });
  });

  group('replace', () {
    test('replaces entry at its current index', () {
      final list = ['a', 'b', 'c'];
      final result = list.replace('b');
      expect(result, ['a', 'b', 'c']);
    });

    test('does not mutate original list', () {
      final list = ['a', 'b', 'c'];
      list.replace('b');
      expect(list, ['a', 'b', 'c']);
    });
  });

  group('toggle', () {
    test('adds entry when not present', () {
      expect([1, 2].toggle(3), [1, 2, 3]);
    });

    test('removes entry when present', () {
      expect([1, 2, 3].toggle(2), [1, 3]);
    });

    test('does not mutate the original list', () {
      final list = [1, 2];
      list.toggle(3);
      expect(list, [1, 2]);
    });
  });

  group('containsAny', () {
    test('true when any entry is contained', () {
      expect([1, 2, 3].containsAny([5, 2]), isTrue);
    });

    test('false when none of the entries are contained', () {
      expect([1, 2, 3].containsAny([5, 6]), isFalse);
    });

    test('empty entries returns false', () {
      expect([1, 2, 3].containsAny([]), isFalse);
    });

    test('empty list returns false', () {
      expect(<int>[].containsAny([1]), isFalse);
    });
  });

  group('toggleUnique', () {
    test('toggling off removes only the first occurrence, then dedupes', () {
      // toggle() removes only the first matching entry; the remaining
      // duplicate survives deduplication since it's still present once.
      expect([1, 1, 2].toggleUnique(1), unorderedEquals([1, 2]));
    });

    test('toggling off the only occurrence removes it entirely', () {
      expect([1, 2].toggleUnique(1), unorderedEquals([2]));
    });

    test('toggling on a new entry and deduping', () {
      expect([1, 2].toggleUnique(3), unorderedEquals([1, 2, 3]));
    });
  });

  group('uniqueBy', () {
    test('keeps first occurrence for each key', () {
      final result = [1, 2, 3, 4, 5].uniqueBy((e) => e % 2);
      expect(result, [1, 2]);
    });

    test('empty list returns empty list', () {
      expect(<int>[].uniqueBy((e) => e), isEmpty);
    });

    test('all unique keys returns all items', () {
      expect([1, 2, 3].uniqueBy((e) => e), [1, 2, 3]);
    });
  });

  group('mapWithLast', () {
    test('marks only the last element as last', () {
      final result = [1, 2, 3].mapWithLast((value, last) => '$value-$last');
      expect(result, ['1-false', '2-false', '3-true']);
    });

    test('single element list marks it as last', () {
      final result = [1].mapWithLast((value, last) => last);
      expect(result, [true]);
    });

    test('empty list returns empty list', () {
      expect(<int>[].mapWithLast((value, last) => value), isEmpty);
    });
  });

  group('chunk', () {
    test('splits list into chunks of given size', () {
      final chunks = [1, 2, 3, 4, 5].chunk(2).toList();
      expect(chunks, [
        [1, 2],
        [3, 4],
        [5],
      ]);
    });

    test('chunk size equal to list length returns one chunk', () {
      expect([1, 2, 3].chunk(3).toList(), [
        [1, 2, 3]
      ]);
    });

    test('chunk size larger than list returns single partial chunk', () {
      expect([1, 2].chunk(5).toList(), [
        [1, 2]
      ]);
    });

    test('empty list yields no chunks', () {
      expect(<int>[].chunk(2).toList(), isEmpty);
    });

    test('throws ArgumentError for zero or negative size', () {
      expect(() => [1, 2].chunk(0).toList(), throwsArgumentError);
      expect(() => [1, 2].chunk(-1).toList(), throwsArgumentError);
    });
  });

  group('nextOrNull', () {
    test('returns the element after the given item', () {
      expect([1, 2, 3].nextOrNull(2), 3);
    });

    test('returns null for the last item', () {
      expect([1, 2, 3].nextOrNull(3), isNull);
    });

    test('returns null when item is not found', () {
      expect([1, 2, 3].nextOrNull(99), isNull);
    });
  });

  group('previousOrNull', () {
    test('returns the element before the given item', () {
      expect([1, 2, 3].previousOrNull(2), 1);
    });

    test('returns null for the first item', () {
      expect([1, 2, 3].previousOrNull(1), isNull);
    });

    test('returns null when item is not found', () {
      expect([1, 2, 3].previousOrNull(99), isNull);
    });
  });

  group('nextWhereOrNull', () {
    test('returns element after the first match', () {
      expect([1, 2, 3, 4].nextWhereOrNull((e) => e == 2), 3);
    });

    test('returns null when match is the last element', () {
      expect([1, 2, 3].nextWhereOrNull((e) => e == 3), isNull);
    });

    test('returns null when no match found', () {
      expect([1, 2, 3].nextWhereOrNull((e) => e == 99), isNull);
    });
  });

  group('previousWhereOrNull', () {
    test('returns element before the first match', () {
      expect([1, 2, 3, 4].previousWhereOrNull((e) => e == 3), 2);
    });

    test('returns null when match is the first element', () {
      expect([1, 2, 3].previousWhereOrNull((e) => e == 1), isNull);
    });

    test('returns null when no match found', () {
      expect([1, 2, 3].previousWhereOrNull((e) => e == 99), isNull);
    });
  });
}
