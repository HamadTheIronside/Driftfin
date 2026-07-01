import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/screens/home_screen.dart';

// NOTE: HomeScreen itself is not tested here. Building it requires a fully
// wired AutoRoute router (see lib/main.dart's MaterialApp.router + AppRouter)
// plus authenticated user/session/sync/seerr providers with live navigation
// targets (DashboardRoute, LibraryRoute, FavouritesRoute, SeerrRoute,
// SyncedRoute, LibrarySearchRoute, SeerrSearchRoute). There is no reasonable
// seam to stub AutoRouter's route table in a unit/widget test without
// duplicating the app's router configuration, so the widget build itself is
// skipped. `HomeTabs.navigate` is skipped for the same reason (it calls
// `context.router.navigate(...)`, which needs a live StackRouter).
//
// What's covered below is the pure, hand-written logic on the `HomeTabs`
// enum: the icon/selectedIcon getters and the localized `label`.
void main() {
  group('HomeTabs.icon / selectedIcon', () {
    test('each tab has a distinct outlined icon and a distinct bold selected icon', () {
      const expectedIcons = {
        HomeTabs.dashboard: IconsaxPlusLinear.home_1,
        HomeTabs.library: IconsaxPlusLinear.book,
        HomeTabs.favorites: IconsaxPlusLinear.heart,
        HomeTabs.seerr: IconsaxPlusLinear.discover_1,
        HomeTabs.sync: IconsaxPlusLinear.cloud,
      };
      const expectedSelectedIcons = {
        HomeTabs.dashboard: IconsaxPlusBold.home_1,
        HomeTabs.library: IconsaxPlusBold.book,
        HomeTabs.favorites: IconsaxPlusBold.heart,
        HomeTabs.seerr: IconsaxPlusBold.discover,
        HomeTabs.sync: IconsaxPlusBold.cloud,
      };

      for (final tab in HomeTabs.values) {
        expect(tab.icon, expectedIcons[tab]);
        expect(tab.selectedIcon, expectedSelectedIcons[tab]);
      }
    });
  });

  group('HomeTabs.label', () {
    testWidgets('returns the correct localized (or hardcoded) label for every tab', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(HomeTabs.dashboard.label(capturedContext), l10n.dashboard);
      expect(HomeTabs.library.label(capturedContext), l10n.library(0));
      expect(HomeTabs.favorites.label(capturedContext), l10n.favorites);
      expect(HomeTabs.seerr.label(capturedContext), 'Seerr');
      expect(HomeTabs.sync.label(capturedContext), l10n.sync);
    });
  });
}
