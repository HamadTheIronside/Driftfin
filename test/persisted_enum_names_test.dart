import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/items/media_segments_model.dart';
import 'package:driftfin/models/settings/client_settings_model.dart';
import 'package:driftfin/models/settings/home_settings_model.dart';
import 'package:driftfin/models/settings/video_player_settings.dart';
import 'package:driftfin/util/custom_color_themes.dart';

/// Issue #50 Phase 0 guardrail: these enums round-trip through `.name` in
/// persisted prefs and/or the cross-device sync payload
/// (config_sync_provider.dart). Renaming or reordering a value here doesn't
/// break Dart, but it silently corrupts every already-persisted value on
/// disk/the server — so lock the exact identifiers down. Change the display
/// string, not these names, if you want to rename something in the UI.
void main() {
  test('ColorThemes.fladder must not change — it round-trips through .name', () {
    // Note: ColorThemes.name is NOT Dart's built-in Enum.name — it's a custom
    // `final String name` field holding the human-readable display string
    // (see custom_color_themes.dart), and config_sync_provider.dart
    // (de)serializes themeColor through *this* field. That conflates display
    // text with a persistence key, so a "just tidy up the wording" edit here
    // would silently break sync for anyone with a synced theme. Don't fix the
    // conflation in Phase 0 — just freeze the current values.
    expect(ColorThemes.fladder.name, 'Fladder');
  });

  test('ColorThemes values keep their persisted names', () {
    expect(ColorThemes.values.map((e) => e.name).toList(), [
      'Fladder',
      'Deep Orange',
      'Amber',
      'Green',
      'Light Green',
      'Lime',
      'Cyan',
      'Blue',
      'Light Blue',
      'Indigo',
      'Deep Blue',
      'Brown',
      'Purple',
      'Deep Purple',
      'Blue Grey',
    ]);
  });

  test('ThemeMode values keep their persisted names', () {
    expect(ThemeMode.values.map((e) => e.name).toList(), ['system', 'light', 'dark']);
  });

  test('BackgroundType values keep their persisted names', () {
    expect(BackgroundType.values.map((e) => e.name).toList(), ['disabled', 'enabled', 'blurred']);
  });

  test('GlobalHotKeys values keep their persisted names', () {
    expect(GlobalHotKeys.values.map((e) => e.name).toList(), [
      'search',
      'closeWindow',
      'exit',
      'toggleSideBar',
    ]);
  });

  test('HomeBanner values keep their persisted names', () {
    expect(HomeBanner.values.map((e) => e.name).toList(), [
      'hide',
      'carousel',
      'banner',
      'detailedBanner',
      'tvSliderBanner',
    ]);
  });

  test('HomeCarouselSettings values keep their persisted names', () {
    expect(HomeCarouselSettings.values.map((e) => e.name).toList(), ['nextUp', 'cont', 'combined']);
  });

  test('HomeNextUp values keep their persisted names', () {
    expect(HomeNextUp.values.map((e) => e.name).toList(), ['off', 'nextUp', 'cont', 'combined', 'separate']);
  });

  test('SegmentSkip values keep their persisted names', () {
    expect(SegmentSkip.values.map((e) => e.name).toList(), ['none', 'askToSkip', 'skipOnce', 'skip']);
  });

  test('AutoNextType values keep their persisted names', () {
    expect(AutoNextType.values.map((e) => e.name).toList(), ['off', 'smart', 'static']);
  });

  test('PlayerOptions values keep their persisted names', () {
    expect(PlayerOptions.values.map((e) => e.name).toList(), ['libMDK', 'libMPV', 'nativePlayer']);
  });
}
