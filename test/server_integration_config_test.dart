import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/models/server_integration_config.dart';
import 'package:driftfin/providers/radarr_provider.dart';
import 'package:driftfin/providers/server_integration_config_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/providers/sonarr_provider.dart';
import 'package:driftfin/providers/trakt_provider.dart';

/// Test double for the plugin config provider so we can drive managed state
/// without hitting the network.
class _FakeServerIntegrationConfig extends ServerIntegrationConfigNotifier {
  _FakeServerIntegrationConfig(Ref ref, ServerIntegrationConfig? initial) : super(ref) {
    state = initial;
  }

  void emit(ServerIntegrationConfig? config) => state = config;
}

ProviderContainer _container(SharedPreferences prefs, ServerIntegrationConfig? initial) {
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    serverIntegrationConfigProvider.overrideWith((ref) => _FakeServerIntegrationConfig(ref, initial)),
  ]);
}

void main() {
  group('ServerIntegrationConfig.fromJson', () {
    test('parses nested camelCase groups', () {
      final config = ServerIntegrationConfig.fromJson({
        'seerr': {'enabled': true, 'url': 'https://seerr', 'apiKey': 'k1'},
        'sonarr': {'enabled': true, 'url': 'https://sonarr', 'apiKey': 'k2'},
        'radarr': {'enabled': false, 'url': 'https://radarr', 'apiKey': 'k3'},
        'trakt': {'enabled': true, 'clientId': 'cid', 'clientSecret': 'sec'},
      });

      expect(config.seerr.url, 'https://seerr');
      expect(config.seerr.isManaged, isTrue);
      expect(config.sonarr.isManaged, isTrue);
      expect(config.radarr.isManaged, isFalse, reason: 'disabled is never managed');
      expect(config.trakt.clientId, 'cid');
      expect(config.trakt.isManaged, isTrue);
      expect(config.anyManaged, isTrue);
    });

    test('missing/garbage keys fall back to empty + unmanaged', () {
      final empty = ServerIntegrationConfig.fromJson({});
      expect(empty.anyManaged, isFalse);
      expect(empty.sonarr.url, '');

      final garbage = ServerIntegrationConfig.fromJson({'sonarr': 'not-an-object'});
      expect(garbage.sonarr.isManaged, isFalse);
    });

    test('enabled but incomplete config is not managed', () {
      const noKey = ArrServerConfig(enabled: true, url: 'https://x', apiKey: '');
      const noUrl = ArrServerConfig(enabled: true, url: '  ', apiKey: 'k');
      expect(noKey.isManaged, isFalse);
      expect(noUrl.isManaged, isFalse);
    });

    test('json round-trip', () {
      const original = ServerIntegrationConfig(
        seerr: SeerrServerConfig(enabled: true, url: 'u', apiKey: 'k'),
        trakt: TraktServerConfig(enabled: true, clientId: 'c', clientSecret: 's'),
      );
      final restored = ServerIntegrationConfig.fromJson(original.toJson());
      expect(restored.seerr, isA<SeerrServerConfig>());
      expect(restored.seerr.apiKey, 'k');
      expect(restored.trakt.clientSecret, 's');
    });
  });

  group('managed flag is transient (survives plugin removal)', () {
    test('Sonarr/Radarr settings never serialize the managed flag', () {
      const sonarr = SonarrSettings(baseUrl: 'u', apiKey: 'k', enabled: true, managed: true);
      const radarr = RadarrSettings(baseUrl: 'u', apiKey: 'k', enabled: true, managed: true);
      expect(sonarr.toJson().containsKey('managed'), isFalse);
      expect(radarr.toJson().containsKey('managed'), isFalse);
      expect(SonarrSettings.fromJson(sonarr.toJson()).managed, isFalse);
    });

    test('Trakt settings never serialize the managed flag', () {
      const trakt = TraktSettings(clientId: 'c', clientSecret: 's', enabled: true, managed: true);
      expect(trakt.toJson().containsKey('managed'), isFalse);
      expect(TraktSettings.fromJson(trakt.toJson()).managed, isFalse);
    });
  });

  group('integration providers + server plugin', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('absent plugin → providers use local prefs, fully editable', () {
      final container = _container(prefs, null);
      addTearDown(container.dispose);

      container.read(sonarrProvider.notifier).setEnabled(true);
      container.read(sonarrProvider.notifier).setBaseUrl('http://local-sonarr');
      container.read(sonarrProvider.notifier).setApiKey('local-key');

      final state = container.read(sonarrProvider);
      expect(state.managed, isFalse);
      expect(state.baseUrl, 'http://local-sonarr');
      expect(state.apiKey, 'local-key');
    });

    test('managed config overrides local and locks setters', () {
      const managed = ServerIntegrationConfig(
        sonarr: ArrServerConfig(enabled: true, url: 'https://server-sonarr/', apiKey: 'server-key'),
      );
      final container = _container(prefs, managed);
      addTearDown(container.dispose);

      final state = container.read(sonarrProvider);
      expect(state.managed, isTrue);
      expect(state.baseUrl, 'https://server-sonarr', reason: 'normalized (trailing slash stripped)');
      expect(state.apiKey, 'server-key');

      // Setters are no-ops while managed.
      container.read(sonarrProvider.notifier).setBaseUrl('http://hacked');
      container.read(sonarrProvider.notifier).setApiKey('hacked');
      container.read(sonarrProvider.notifier).setEnabled(false);
      final after = container.read(sonarrProvider);
      expect(after.baseUrl, 'https://server-sonarr');
      expect(after.apiKey, 'server-key');
      expect(after.enabled, isTrue);
    });

    test('removing the plugin reverts to the stored local config', () async {
      // Seed a local Radarr config in prefs first.
      final seed = _container(prefs, null);
      seed.read(radarrProvider.notifier).setEnabled(true);
      seed.read(radarrProvider.notifier).setBaseUrl('http://local-radarr');
      seed.read(radarrProvider.notifier).setApiKey('local-key');
      seed.dispose();

      const managed = ServerIntegrationConfig(
        radarr: ArrServerConfig(enabled: true, url: 'https://server-radarr', apiKey: 'server-key'),
      );
      final container = _container(prefs, managed);
      addTearDown(container.dispose);

      expect(container.read(radarrProvider).managed, isTrue);
      expect(container.read(radarrProvider).baseUrl, 'https://server-radarr');

      // Plugin goes away -> revert to the local prefs we seeded.
      final fake = container.read(serverIntegrationConfigProvider.notifier) as _FakeServerIntegrationConfig;
      fake.emit(null);
      await Future<void>.delayed(Duration.zero); // let the ref.listen callback run

      final reverted = container.read(radarrProvider);
      expect(reverted.managed, isFalse);
      expect(reverted.baseUrl, 'http://local-radarr');
      expect(reverted.apiKey, 'local-key');
    });

    test('Trakt: managed overlays credentials but keeps local OAuth tokens', () {
      const managed = ServerIntegrationConfig(
        trakt: TraktServerConfig(enabled: true, clientId: 'server-cid', clientSecret: 'server-sec'),
      );
      final container = _container(prefs, managed);
      addTearDown(container.dispose);

      final state = container.read(traktProvider);
      expect(state.managed, isTrue);
      expect(state.clientId, 'server-cid');
      expect(state.enabled, isTrue);

      // Credential setters are locked.
      container.read(traktProvider.notifier).setClientId('hacked');
      expect(container.read(traktProvider).clientId, 'server-cid');
    });
  });
}
