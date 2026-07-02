import 'dart:convert';

import 'package:driftfin/models/settings/subtitle_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubtitleSettingsModel.style', () {
    test('reflects fontSize/fontWeight/color and fixed presentation fields', () {
      const model = SubtitleSettingsModel(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      );
      final style = model.style;

      expect(style.fontSize, 42);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, Colors.red);
      expect(style.height, 1.4);
      expect(style.fontFamily, 'OpenSans');
      expect(style.letterSpacing, 0.0);
      expect(style.wordSpacing, 0.0);
    });
  });

  group('SubtitleSettingsModel.backGroundStyle', () {
    test('omits shadows when shadow is at/near zero', () {
      const model = SubtitleSettingsModel(shadow: 0.0);
      expect(model.backGroundStyle.shadows, isNull);
    });

    test('adds two shadows using the shadow alpha when shadow is above the threshold', () {
      const model = SubtitleSettingsModel(shadow: 0.5);
      final shadows = model.backGroundStyle.shadows;
      expect(shadows, isNotNull);
      expect(shadows!.length, 2);
      expect(shadows[0].blurRadius, 16);
      expect(shadows[1].blurRadius, 8);
      expect(shadows[0].color.a, closeTo(0.5, 0.01));
    });

    test('the stroke width scales with outlineSize and fontSize', () {
      const model = SubtitleSettingsModel(outlineSize: 4, fontSize: 60);
      final paint = model.backGroundStyle.foreground!;
      expect(paint.strokeWidth, 4 * (60 / 30));
    });
  });

  group('SubtitleSettingsModel JSON round trip (freezed + json_serializable)', () {
    test('toJson/fromJson round-trips every field, including non-default fontWeight', () {
      const model = SubtitleSettingsModel(
        fontSize: 50,
        fontWeight: FontWeight.w600,
        verticalOffset: 0.25,
        color: Colors.blue,
        outlineColor: Colors.black,
        outlineSize: 6,
        backGroundColor: Colors.white,
        shadow: 0.9,
      );

      final restored = SubtitleSettingsModel.fromJson(model.toJson());

      expect(restored.fontSize, model.fontSize);
      // The pre-migration model stored fontWeight.value but read it back by
      // .index, so any non-default weight silently reverted to normal. The
      // freezed FontWeightConverter matches by .value, so w600 now survives.
      expect(restored.fontWeight, FontWeight.w600);
      expect(restored.verticalOffset, model.verticalOffset);
      // The color converter always reconstructs a plain Color via Color.from(),
      // so a MaterialColor input (Colors.blue) round-trips to an equal-valued
      // but not `==` plain Color. Compare the packed ARGB value instead.
      expect(restored.color.toARGB32(), model.color.toARGB32());
      expect(restored.outlineColor.toARGB32(), model.outlineColor.toARGB32());
      expect(restored.outlineSize, model.outlineSize);
      expect(restored.backGroundColor.toARGB32(), model.backGroundColor.toARGB32());
      expect(restored.shadow, model.shadow);
    });

    test('the JSON keys are exactly the pre-migration keys (no drift)', () {
      final json = const SubtitleSettingsModel().toJson();
      expect(
        json.keys.toSet(),
        {
          'fontSize',
          'fontWeight',
          'verticalOffset',
          'color',
          'outlineColor',
          'outlineSize',
          'backGroundColor',
          'shadow',
        },
      );
      // Colors still serialize as the {alpha, red, green, blue} map, and
      // fontWeight still serializes as its numeric weight — the exact shapes
      // the hand-rolled toMap produced.
      expect(json['color'], isA<Map<String, dynamic>>());
      expect((json['color'] as Map).keys.toSet(), {'alpha', 'red', 'green', 'blue'});
      expect(json['fontWeight'], isA<int>());
    });

    test('fromJson reads a real pre-migration payload (Phase 4 migration guard)', () {
      // This is exactly what the old hand-rolled `toJson()` wrote to
      // SharedPreferences before the freezed migration: fontWeight as its
      // numeric weight (700), colors as {alpha,red,green,blue} doubles.
      const preMigrationJson = '''
      {
        "fontSize": 48.0,
        "fontWeight": 700,
        "verticalOffset": 0.2,
        "color": {"alpha": 1.0, "red": 1.0, "green": 1.0, "blue": 1.0},
        "outlineColor": {"alpha": 0.85, "red": 0.0, "green": 0.0, "blue": 0.0},
        "outlineSize": 5.0,
        "backGroundColor": {"alpha": 0.0, "red": 0.0, "green": 0.0, "blue": 0.0},
        "shadow": 0.75
      }
      ''';

      final restored = SubtitleSettingsModel.fromJson(jsonDecode(preMigrationJson) as Map<String, dynamic>);

      expect(restored.fontSize, 48.0);
      expect(restored.fontWeight, FontWeight.w700);
      expect(restored.verticalOffset, 0.2);
      expect(restored.color.toARGB32(), Colors.white.toARGB32());
      expect(restored.outlineColor.a, closeTo(0.85, 0.01));
      expect(restored.outlineSize, 5.0);
      expect(restored.backGroundColor.a, 0.0);
      expect(restored.shadow, 0.75);
    });

    test('fromJson reads the even-older integer color format via colorFromJson', () {
      final restored = SubtitleSettingsModel.fromJson({
        'color': 0xFF00FF00, // deprecated packed-int color format
      });
      expect(restored.color.toARGB32(), const Color(0xFF00FF00).toARGB32());
    });

    test('fromJson with missing keys falls back to defaults', () {
      final restored = SubtitleSettingsModel.fromJson(const {});
      expect(restored, const SubtitleSettingsModel());
    });

    test('fromJson with an unknown fontWeight value falls back to the default fontWeight', () {
      final restored = SubtitleSettingsModel.fromJson({'fontWeight': 999});
      expect(restored.fontWeight, const SubtitleSettingsModel().fontWeight);
    });

    test('fromJson decodes colors via the map-based colorFromJson format', () {
      final restored = SubtitleSettingsModel.fromJson({
        'color': {'alpha': 1.0, 'red': 0.0, 'green': 1.0, 'blue': 0.0},
      });
      expect(restored.color.g, 1.0);
      expect(restored.color.r, 0.0);
    });
  });

  group('SubtitleSettingsModel equality/hashCode', () {
    test('equal when all fields match', () {
      const a = SubtitleSettingsModel(fontSize: 10, shadow: 0.2);
      const b = SubtitleSettingsModel(fontSize: 10, shadow: 0.2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when a single field differs', () {
      const a = SubtitleSettingsModel(fontSize: 10);
      const b = SubtitleSettingsModel(fontSize: 11);
      expect(a == b, isFalse);
    });
  });

  group('SubtitleSettingsModel.copyWith', () {
    test('overrides only the given fields', () {
      const model = SubtitleSettingsModel();
      final updated = model.copyWith(fontSize: 99);
      expect(updated.fontSize, 99);
      expect(updated.fontWeight, model.fontWeight);
      expect(updated.color, model.color);
    });
  });
}
