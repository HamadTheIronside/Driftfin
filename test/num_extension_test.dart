import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/num_extension.dart';

void main() {
  group('isInRange', () {
    test('true when value is strictly within range around index', () {
      expect(5.isInRange(5, 2), isTrue);
      expect(4.isInRange(5, 2), isTrue);
      expect(6.isInRange(5, 2), isTrue);
    });

    test('false when value is exactly at the boundary', () {
      expect(3.isInRange(5, 2), isFalse);
      expect(7.isInRange(5, 2), isFalse);
    });

    test('false when value is outside range', () {
      expect(0.isInRange(5, 2), isFalse);
      expect(10.isInRange(5, 2), isFalse);
    });

    test('works with negative numbers', () {
      expect((-5).isInRange(-5, 2), isTrue);
      expect((-8).isInRange(-5, 2), isFalse);
    });

    test('zero range only matches exact equality is false due to strict inequality', () {
      // index - 0 < this && this < index + 0 can never be true.
      expect(5.isInRange(5, 0), isFalse);
    });
  });

  group('roundTo', () {
    test('rounds to given decimal places', () {
      expect(3.14159.roundTo(2), 3.14);
      expect(3.14559.roundTo(2), 3.15);
    });

    test('rounds to zero places behaves like round', () {
      expect(3.6.roundTo(0), 4.0);
      expect(3.4.roundTo(0), 3.0);
    });

    test('handles negative numbers', () {
      expect((-3.14159).roundTo(2), -3.14);
    });

    test('handles zero', () {
      expect(0.0.roundTo(2), 0.0);
    });

    test('already exact value is unchanged', () {
      expect(2.5.roundTo(1), 2.5);
    });
  });
}
