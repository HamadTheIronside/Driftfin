import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/screens/home_screen.dart';
import 'package:driftfin/screens/settings/client_sections/client_settings_advanced.dart';
import 'package:driftfin/screens/shared/flat_button.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout_model.dart';
import 'package:driftfin/util/poster_defaults.dart';

const _adaptiveModel = AdaptiveLayoutModel(
  viewSize: ViewSize.phone,
  layoutMode: LayoutMode.single,
  inputDevice: InputDevice.touch,
  platform: TargetPlatform.android,
  isDesktop: false,
  posterDefaults: PosterDefaults(size: 100, ratio: 0.66),
  controller: <HomeTabs, ScrollController>{},
  sideBarWidth: 0,
  topBarHeight: 0,
);

Widget _harness(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AdaptiveLayout(
        data: _adaptiveModel,
        child: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ListView(children: buildClientSettingsAdvanced(context, ref)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crash reporting toggle is off by default and persists via the provider', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_harness(prefs));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.crashReportingTitle), findsOneWidget);
    expect(find.text(l10n.crashReportingDesc), findsOneWidget);

    final switchFinder = find.descendant(
      of: find.ancestor(of: find.text(l10n.crashReportingTitle), matching: find.byType(FlatButton)),
      matching: find.byType(Switch),
    );
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    final container = ProviderScope.containerOf(tester.element(find.byType(ListView)));
    expect(container.read(clientSettingsProvider).enableCrashReporting, isFalse);

    await tester.tap(switchFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(container.read(clientSettingsProvider).enableCrashReporting, isTrue);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    // Flush the notifier's debounced persistence timer so it doesn't outlive the test.
    await tester.pump(const Duration(seconds: 1));
  });
}
