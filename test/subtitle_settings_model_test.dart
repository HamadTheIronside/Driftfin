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

  group('SubtitleSettingsModel JSON round trip', () {
    test('toMap/fromMap round-trips all fields except fontWeight', () {
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

      final restored = SubtitleSettingsModel.fromMap(model.toMap());

      expect(restored.fontSize, model.fontSize);
      // toMap() stores fontWeight.value (100-900) but fromMap() looks it up by
      // .index (0-8), so non-default weights never match and fall back to the
      // default (FontWeight.normal). This is existing behavior of
      // lib/models/settings/subtitle_settings_model.dart, not something this
      // test suite changes.
      expect(restored.fontWeight, const SubtitleSettingsModel().fontWeight);
      expect(restored.verticalOffset, model.verticalOffset);
      // colorFromJson always reconstructs a plain Color via Color.from(), so a
      // MaterialColor input (like Colors.blue) round-trips to an equal-valued
      // but not `==` plain Color. Compare the packed ARGB value instead.
      expect(restored.color.toARGB32(), model.color.toARGB32());
      expect(restored.outlineColor.toARGB32(), model.outlineColor.toARGB32());
      expect(restored.outlineSize, model.outlineSize);
      expect(restored.backGroundColor.toARGB32(), model.backGroundColor.toARGB32());
      expect(restored.shadow, model.shadow);
    });

    test('toJson/fromJson string round trip', () {
      const model = SubtitleSettingsModel(fontSize: 33);
      final restored = SubtitleSettingsModel.fromJson(model.toJson());
      expect(restored, model);
    });

    test('fromMap with missing keys falls back to defaults', () {
      final restored = SubtitleSettingsModel.fromMap(const {});
      expect(restored, const SubtitleSettingsModel());
    });

    test('fromMap with an unknown fontWeight index falls back to the default fontWeight', () {
      final restored = SubtitleSettingsModel.fromMap({'fontWeight': 999});
      expect(restored.fontWeight, const SubtitleSettingsModel().fontWeight);
    });

    test('fromMap decodes colors via the map-based colorFromJson format', () {
      final restored = SubtitleSettingsModel.fromMap({
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
