import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/providers/cast_provider.dart';
import 'package:driftfin/screens/home_screen.dart';
import 'package:driftfin/screens/video_player/components/cast_button.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout_model.dart';
import 'package:driftfin/util/poster_defaults.dart';

import 'support/video_player_test_support.dart';

const _adaptiveModel = AdaptiveLayoutModel(
  viewSize: ViewSize.desktop,
  layoutMode: LayoutMode.single,
  inputDevice: InputDevice.pointer,
  platform: TargetPlatform.linux,
  isDesktop: true,
  posterDefaults: PosterDefaults(size: 100, ratio: 0.66),
  controller: <HomeTabs, ScrollController>{},
  sideBarWidth: 0,
  topBarHeight: 0,
);

Future<ProviderContainer> _pumpCastButton(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [castProvider.overrideWith((ref) => FakeCastController(ref))],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      // AdaptiveLayout must wrap MaterialApp (as in lib/main.dart) since the
      // cast sheet is a modal route - a sibling of `home` under the root
      // Navigator, not a descendant of anything nested inside `home`.
      child: const AdaptiveLayout(
        data: _adaptiveModel,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CastButton()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows the idle cast icon when nothing is casting', (tester) async {
    await _pumpCastButton(tester);
    expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
  });

  testWidgets('tapping it triggers discovery and opens the cast sheet', (tester) async {
    final container = await _pumpCastButton(tester);

    await tester.tap(find.byType(CastButton));
    await tester.pumpAndSettle();

    expect((container.read(castProvider.notifier) as FakeCastController).discoverCallCount, 1);
    expect(find.text('Cast to TV'), findsOneWidget);
  });
}
