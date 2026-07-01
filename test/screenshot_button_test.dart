// Widget-level proof for issue #47 (BasePlayer capability matrix): the
// screenshot control must gray out on a backend that can't take screenshots,
// instead of silently no-oping when tapped.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/screens/video_player/components/video_player_controls_extras.dart';
import 'package:driftfin/wrappers/players/player_capabilities.dart';

import 'support/video_player_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('pip'),
      (call) async => null,
    );
  });

  Future<ProviderContainer> pumpScreenshotButton(
    WidgetTester tester, {
    required PlayerCapabilities capabilities,
  }) async {
    final container = ProviderContainer(
      overrides: [
        videoPlayerProvider.overrideWith((ref) => FakeVideoPlayerNotifier(ref)),
      ],
    );
    addTearDown(container.dispose);

    await (container.read(videoPlayerProvider.notifier) as FakeVideoPlayerNotifier).setupFake(
      capabilities: capabilities,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ScreenshotButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('is enabled on a backend that supports screenshots', (tester) async {
    await pumpScreenshotButton(tester, capabilities: const PlayerCapabilities(screenshots: true));

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('grays out on a backend that does not support screenshots', (tester) async {
    await pumpScreenshotButton(tester, capabilities: PlayerCapabilities.none);

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });
}
