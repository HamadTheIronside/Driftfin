import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/color_extensions.dart';

void main() {
  group('colorFromJson', () {
    test('null input returns null', () {
      expect(colorFromJson(null), isNull);
    });

    test('parses a map with alpha/red/green/blue components', () {
      final color = colorFromJson({
        'alpha': 1.0,
        'red': 0.5,
        'green': 0.25,
        'blue': 0.0,
      });
      expect(color, isNotNull);
      expect(color!.a, 1.0);
      expect(color.r, closeTo(0.5, 0.001));
      expect(color.g, closeTo(0.25, 0.001));
      expect(color.b, 0.0);
    });

    test('map with missing components defaults to 1.0', () {
      final color = colorFromJson(<String, dynamic>{});
      expect(color!.a, 1.0);
      expect(color.r, 1.0);
      expect(color.g, 1.0);
      expect(color.b, 1.0);
    });

    test('parses deprecated integer color format', () {
      final color = colorFromJson(0xFF00FF00);
      expect(color, const Color(0xFF00FF00));
    });

    test('unsupported type returns null', () {
      expect(colorFromJson('not a color'), isNull);
      expect(colorFromJson(3.14), isNull);
    });
  });

  group('ColorExtensions.toMap', () {
    test('converts a color into a map of its components', () {
      const color = Color(0xFF112233);
      final map = color.toMap;
      expect(map['alpha'], color.a);
      expect(map['red'], color.r);
      expect(map['green'], color.g);
      expect(map['blue'], color.b);
    });

    test('round trips through colorFromJson', () {
      const color = Color(0xFF445566);
      final map = color.toMap;
      final restored = colorFromJson(map);
      expect(restored!.a, color.a);
      expect(restored.r, closeTo(color.r, 0.001));
      expect(restored.g, closeTo(color.g, 0.001));
      expect(restored.b, closeTo(color.b, 0.001));
    });
  });
}
