import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/settings/settings_entry.dart';
import 'package:driftfin/providers/config_sync_provider.dart';
import 'package:driftfin/providers/radarr_provider.dart';
import 'package:driftfin/providers/server_integration_config_provider.dart';
import 'package:driftfin/providers/sonarr_provider.dart';
import 'package:driftfin/providers/trakt_provider.dart';

/// The three persistence tiers a setting can fall into (issue #50). Every
/// [SettingId] that reaches [settingsPersistenceTierProvider] gets exactly
/// one; there is no "unknown" tier — an id not in [syncedSettingIds] and not
/// one of the server-managed integrations simply stays on-device.
enum SettingsPersistenceTier {
  syncsAcrossDevices,
  savedOnServer,
  staysOnDevice,
}

/// The Sonarr/Radarr/Trakt/Seerr integrations that the Jellyfin.Plugin.Driftfin
/// server plugin can take over — see jellyfin-plugin/README.md. When managed,
/// they're "saved on the server" rather than synced client-side.
const Set<SettingId> _serverManageableSettingIds = {
  SettingId.sonarrIntegration,
  SettingId.radarrIntegration,
  SettingId.traktIntegration,
  SettingId.seerrIntegration,
};

/// Resolves which persistence tier badge a settings tile should show. Watch
/// this (not [syncedSettingIds] directly) from UI code — it also accounts for
/// integrations currently taken over by the Driftfin server plugin.
final settingsPersistenceTierProvider = Provider.family<SettingsPersistenceTier, SettingId>((ref, id) {
  if (_serverManageableSettingIds.contains(id)) {
    final managed = switch (id) {
      SettingId.sonarrIntegration => ref.watch(sonarrProvider.select((value) => value.managed)),
      SettingId.radarrIntegration => ref.watch(radarrProvider.select((value) => value.managed)),
      SettingId.traktIntegration => ref.watch(traktProvider.select((value) => value.managed)),
      SettingId.seerrIntegration =>
        ref.watch(serverIntegrationConfigProvider.select((value) => value?.seerr.isManaged ?? false)),
      _ => false,
    };
    if (managed) return SettingsPersistenceTier.savedOnServer;
  }
  if (syncedSettingIds.contains(id)) return SettingsPersistenceTier.syncsAcrossDevices;
  return SettingsPersistenceTier.staysOnDevice;
});
