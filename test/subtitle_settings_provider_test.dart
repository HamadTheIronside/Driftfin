import 'package:driftfin/models/settings/subtitle_settings_model.dart';
import 'package:driftfin/providers/settings/subtitle_settings_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('setFontWeight applies a non-null weight and ignores null', () async {
    final container = await makeContainer();
    final notifier = container.read(subtitleSettingsProvider.notifier);

    notifier.setFontWeight(FontWeight.bold);
    expect(container.read(subtitleSettingsProvider).fontWeight, FontWeight.bold);

    // Null means "leave unchanged" (the freezed copyWith can't take null here).
    notifier.setFontWeight(null);
    expect(container.read(subtitleSettingsProvider).fontWeight, FontWeight.bold);
  });

  test('the remaining setters update their fields', () async {
    final container = await makeContainer();
    final notifier = container.read(subtitleSettingsProvider.notifier);

    notifier.setFontSize(80);
    notifier.setVerticalOffset(0.3);
    notifier.setSubColor(const Color(0xFF112233));
    notifier.setOutlineColor(const Color(0xFF445566));
    notifier.setOutlineThickness(7);
    notifier.setShadowIntensity(0.9);
    notifier.setBackgroundColor(const Color(0xFF778899));
    notifier.setBackGroundOpacity(0.4);

    final state = container.read(subtitleSettingsProvider);
    expect(state.fontSize, 80);
    expect(state.verticalOffset, 0.3);
    expect(state.color.toARGB32(), const Color(0xFF112233).toARGB32());
    expect(state.outlineColor.toARGB32(), const Color(0xFF445566).toARGB32());
    expect(state.outlineSize, 7);
    expect(state.shadow, 0.9);
    expect(state.backGroundColor.a, closeTo(0.4, 0.01));
  });

  test('resetSettings returns to defaults', () async {
    final container = await makeContainer();
    final notifier = container.read(subtitleSettingsProvider.notifier);

    notifier.setFontSize(120);
    expect(container.read(subtitleSettingsProvider).fontSize, 120);

    notifier.resetSettings();
    expect(container.read(subtitleSettingsProvider), const SubtitleSettingsModel());
  });
}
