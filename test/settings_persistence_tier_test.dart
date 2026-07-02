import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/models/server_integration_config.dart';
import 'package:driftfin/models/settings/settings_entry.dart';
import 'package:driftfin/providers/server_integration_config_provider.dart';
import 'package:driftfin/providers/settings/settings_persistence_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/providers/sonarr_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
  });

  test('a setting in syncedSettingIds resolves to syncsAcrossDevices', () {
    final tier = container.read(settingsPersistenceTierProvider(SettingId.themeMode));
    expect(tier, SettingsPersistenceTier.syncsAcrossDevices);
  });

  test('an unregistered/local-only setting resolves to staysOnDevice', () {
    final tier = container.read(settingsPersistenceTierProvider(SettingId.downloadsMaxConcurrent));
    expect(tier, SettingsPersistenceTier.staysOnDevice);
  });

  test('sonarr resolves to staysOnDevice while unmanaged', () {
    final tier = container.read(settingsPersistenceTierProvider(SettingId.sonarrIntegration));
    expect(tier, SettingsPersistenceTier.staysOnDevice);
  });

  test('sonarr resolves to savedOnServer once the Driftfin plugin manages it', () {
    // Construct sonarrProvider first so its ref.listen on
    // serverIntegrationConfigProvider is registered before the config arrives.
    container.read(sonarrProvider);

    container.read(serverIntegrationConfigProvider.notifier).state = const ServerIntegrationConfig(
      sonarr: ArrServerConfig(enabled: true, url: 'http://sonarr.example.com', apiKey: 'key'),
    );

    expect(container.read(sonarrProvider).managed, isTrue);
    final tier = container.read(settingsPersistenceTierProvider(SettingId.sonarrIntegration));
    expect(tier, SettingsPersistenceTier.savedOnServer);
  });

  test('seerr resolves to savedOnServer once the Driftfin plugin manages it', () {
    container.read(serverIntegrationConfigProvider.notifier).state = const ServerIntegrationConfig(
      seerr: SeerrServerConfig(enabled: true, url: 'http://seerr.example.com', apiKey: 'key'),
    );

    final tier = container.read(settingsPersistenceTierProvider(SettingId.seerrIntegration));
    expect(tier, SettingsPersistenceTier.savedOnServer);
  });
}
