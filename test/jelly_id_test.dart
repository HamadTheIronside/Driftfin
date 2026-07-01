import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/jelly_id.dart';

void main() {
  group('jellyId', () {
    test('is 32 characters long', () {
      expect(jellyId.length, 32);
    });

    test('contains no hyphens', () {
      expect(jellyId.contains('-'), isFalse);
    });

    test('is composed only of hex characters', () {
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(jellyId), isTrue);
    });

    test('generates unique values across calls', () {
      final ids = List.generate(20, (_) => jellyId);
      expect(ids.toSet().length, 20);
    });
  });
}
