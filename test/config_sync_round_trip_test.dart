import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/providers/config_sync_provider.dart';
import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/util/custom_color_themes.dart';

/// Issue #50 Definition-of-Done guard: a config_sync round-trip proving
/// `ColorThemes.fladder.name` still (de)serializes. The fladder theme is
/// persisted through the enum's custom `.name` field ('Fladder', not the Dart
/// identifier 'fladder'); if that field ever changed, every user's saved theme
/// would silently reset on the next sync. This exercises the real
/// ConfigSync.buildCurrentSettings -> applySettings path, not just the enum.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    // Construct ConfigSync (registers its listeners) up front.
    container.read(configSyncProvider);
    return container;
  }

  // Lets the clientSettings notifier's 1s debounced persistence fire while the
  // container is still alive, so no timer outlives the test.
  Future<void> flushDebounce() => Future<void>.delayed(const Duration(milliseconds: 1100));

  test('ColorThemes.fladder survives a build -> apply round trip', () async {
    final container = await makeContainer();
    final configSync = container.read(configSyncProvider);

    container.read(clientSettingsProvider.notifier)
      ..setThemeColor(ColorThemes.fladder)
      ..setThemeMode(ThemeMode.dark)
      ..setAmoledBlack(true);

    final built = configSync.buildCurrentSettings();

    // Serializes via the custom display-string `.name`, not the identifier.
    expect(ColorThemes.fladder.name, 'Fladder');
    expect(built.themeColor, 'Fladder');
    expect(built.themeMode, ThemeMode.dark.name);
    expect(built.amoledBlack, isTrue);

    // Clear it locally, then apply the built payload — the string must resolve
    // back to the fladder enum through _apply's name lookup.
    container.read(clientSettingsProvider.notifier).setThemeColor(null);
    expect(container.read(clientSettingsProvider).themeColor, isNull);

    configSync.applySettings(built);

    expect(container.read(clientSettingsProvider).themeColor, ColorThemes.fladder);
    expect(container.read(clientSettingsProvider).themeMode, ThemeMode.dark);
    expect(container.read(clientSettingsProvider).amoledBlack, isTrue);

    await flushDebounce();
    container.dispose();
  });

  test('every ColorThemes value round-trips through build -> apply', () async {
    for (final theme in ColorThemes.values) {
      final container = await makeContainer();
      final configSync = container.read(configSyncProvider);

      container.read(clientSettingsProvider.notifier).setThemeColor(theme);
      final built = configSync.buildCurrentSettings();
      expect(built.themeColor, theme.name, reason: '${theme.name} did not serialize to its .name');

      container.read(clientSettingsProvider.notifier).setThemeColor(null);
      configSync.applySettings(built);
      expect(container.read(clientSettingsProvider).themeColor, theme,
          reason: '${theme.name} did not deserialize back to its enum value');

      await flushDebounce();
      container.dispose();
    }
  });
}
