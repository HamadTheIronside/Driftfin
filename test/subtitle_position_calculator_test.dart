import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/settings/subtitle_settings_model.dart';
import 'package:driftfin/util/subtitle_position_calculator.dart';

void main() {
  group('SubtitlePositionCalculator.calculateOffset', () {
    test('returns raw vertical offset when overlay is not shown', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.5);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: false,
        screenHeight: 1000,
      );
      expect(result, 0.5);
    });

    test('uses fallback menu height percentage when menuHeight is null', () {
      // offset (0.10 default) < fallback (0.15) -> clamps to fallback.
      const settings = SubtitleSettingsModel(verticalOffset: 0.10);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 1000,
      );
      expect(result, closeTo(0.15, 1e-9));
    });

    test('uses fallback when screenHeight is zero even if menuHeight given', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.05);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 0,
        menuHeight: 100,
      );
      expect(result, closeTo(0.15, 1e-9));
    });

    test('computes menu height percentage when menuHeight and screenHeight provided', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.5);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 1000,
        menuHeight: 200,
      );
      // verticalOffset (0.5) >= minSafeOffset (0.2) -> returns min(0.5, 0.85) = 0.5
      expect(result, closeTo(0.5, 1e-9));
    });

    test('offset above the max is clamped to _maxSubtitleOffset', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.95);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 1000,
        menuHeight: 100,
      );
      expect(result, closeTo(0.85, 1e-9));
    });

    test('offset below minSafeOffset is bumped up to minSafeOffset', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.05);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 1000,
        menuHeight: 300, // minSafeOffset = 0.3
      );
      expect(result, closeTo(0.3, 1e-9));
    });

    test('offset exactly equal to minSafeOffset is kept (>= branch)', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.2);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 1000,
        menuHeight: 200, // minSafeOffset = 0.2
      );
      expect(result, closeTo(0.2, 1e-9));
    });

    test('minSafeOffset itself is clamped to max when it exceeds it', () {
      const settings = SubtitleSettingsModel(verticalOffset: 0.0);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 100,
        menuHeight: 95, // minSafeOffset = 0.95 > max 0.85
      );
      expect(result, closeTo(0.85, 1e-9));
    });

    test('negative verticalOffset falls into the bump-up branch, floored at 0', () {
      const settings = SubtitleSettingsModel(verticalOffset: -1);
      final result = SubtitlePositionCalculator.calculateOffset(
        settings: settings,
        showOverlay: true,
        screenHeight: 1000,
        menuHeight: 0,
      );
      expect(result, closeTo(0.0, 1e-9));
    });
  });
}
