import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/settings/settings_entry.dart';
import 'package:driftfin/providers/config_sync_provider.dart';
import 'package:driftfin/providers/settings/settings_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;
  late List<SettingsEntry> registry;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    registry = buildSettingsRegistry();
  });

  group('buildSettingsRegistry', () {
    test('registers every SettingId exactly once', () {
      final ids = registry.map((entry) => entry.id).toList();
      final uniqueIds = ids.toSet();

      expect(uniqueIds.length, ids.length, reason: 'duplicate SettingId entries: ${_duplicates(ids)}');
      expect(uniqueIds, SettingId.values.toSet(), reason: 'registry must cover every declared SettingId exactly once');
    });

    test('every entry has a non-empty localized label', () {
      for (final entry in registry) {
        expect(entry.label(l10n), isNotEmpty, reason: '${entry.id} has an empty label');
      }
    });

    test('every entry resolves a route and its synonyms are invokable', () {
      for (final entry in registry) {
        expect(entry.route(), isA<PageRouteInfo>(), reason: '${entry.id} route() did not return a PageRouteInfo');
        // Invoke the synonyms closure (when present) so it, too, is exercised —
        // and assert every synonym is a non-empty string.
        final synonyms = entry.synonyms?.call(l10n);
        if (synonyms != null) {
          for (final synonym in synonyms) {
            expect(synonym, isNotEmpty, reason: '${entry.id} has an empty synonym');
          }
        }
      }
    });
  });

  group('SettingsEntry.matches / searchSettingsRegistry', () {
    test('matches by label substring, case-insensitively', () {
      final themeMode = registry.firstWhere((entry) => entry.id == SettingId.themeMode);
      expect(themeMode.matches('THEME', l10n), isTrue);
      expect(themeMode.matches('mode', l10n), isTrue);
    });

    test('matches by synonym even when the label does not contain the query', () {
      final wifiEntry = registry.firstWhere((entry) => entry.id == SettingId.downloadsRequireWifi);
      expect(wifiEntry.label(l10n).toLowerCase(), isNot(contains('wifi')));
      expect(wifiEntry.matches('wifi', l10n), isTrue);
    });

    test('empty or blank query matches nothing', () {
      final anyEntry = registry.first;
      expect(anyEntry.matches('', l10n), isFalse);
      expect(anyEntry.matches('   ', l10n), isFalse);
    });

    test('searchSettingsRegistry filters down to only matching entries', () {
      final results = searchSettingsRegistry(registry, 'theme', l10n);
      expect(results, isNotEmpty);
      expect(results.every((entry) => entry.matches('theme', l10n)), isTrue);
      expect(results.length, lessThan(registry.length));
    });

    test('searchSettingsRegistry returns nothing for a query matching no entry', () {
      expect(searchSettingsRegistry(registry, 'xyzzy-not-a-real-setting', l10n), isEmpty);
    });
  });

  group('syncedSettingIds coverage (issue #50 single-source-of-truth guarantee)', () {
    test('every synced id is registered in the searchable registry', () {
      final registeredIds = registry.map((entry) => entry.id).toSet();
      for (final id in syncedSettingIds) {
        expect(registeredIds, contains(id), reason: '$id is in syncedSettingIds but missing from the registry');
      }
    });

    // Locks in the exact set config_sync_provider._buildFrom/_apply currently
    // read/write, so an unrelated change can't silently grow or shrink what
    // syncs without a deliberate update to both places.
    test('matches the exact fields config_sync_provider currently syncs', () {
      expect(syncedSettingIds, {
        SettingId.homeBanner,
        SettingId.homeBannerInformation,
        SettingId.homeNextUp,
        SettingId.managePinnedCollections,
        SettingId.themeMode,
        SettingId.themeColor,
        SettingId.schemeVariant,
        SettingId.amoledBlack,
        SettingId.deriveColorsFromItem,
        SettingId.backgroundPosters,
        SettingId.blurEffects,
        SettingId.blurredPlaceholders,
        SettingId.posterSize,
        SettingId.displayLanguage,
        SettingId.showAllCollectionTypes,
        SettingId.usePostersForLibraryIcons,
        SettingId.seerrIntegration,
        SettingId.seerrRequestNotifications,
      });
    });
  });
}

List<SettingId> _duplicates(List<SettingId> ids) {
  final seen = <SettingId>{};
  final duplicates = <SettingId>[];
  for (final id in ids) {
    if (!seen.add(id)) duplicates.add(id);
  }
  return duplicates;
}
