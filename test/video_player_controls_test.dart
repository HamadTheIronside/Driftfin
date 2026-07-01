import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/media_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/screens/home_screen.dart';
import 'package:driftfin/screens/video_player/video_player_controls.dart';
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

Future<ProviderContainer> _pumpControls(
  WidgetTester tester, {
  PlaybackModel? playbackModel,
  MediaPlaybackModel? mediaPlayback,
}) async {
  final container = ProviderContainer(
    overrides: [
      videoPlayerProvider.overrideWith((ref) => FakeVideoPlayerNotifier(ref)),
      playBackModel.overrideWith((ref) => playbackModel),
      mediaPlaybackProvider.overrideWith((ref) => mediaPlayback ?? MediaPlaybackModel()),
    ],
  );
  addTearDown(container.dispose);

  // Wire up the fake player backend before the widget reads `hasPlayer`.
  await (container.read(videoPlayerProvider.notifier) as FakeVideoPlayerNotifier).setupFake();

  // The default 800x600 test surface is narrower than any real desktop
  // window; at that width the bottom control bar's right-hand cluster
  // (stop/quality/volume/fullscreen) overflows its Flexible. Use a realistic
  // desktop window size instead, matching what the ViewSize.desktop layout
  // used by this test actually assumes.
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdaptiveLayout(
          data: _adaptiveModel,
          child: Scaffold(
            body: DesktopControls(),
          ),
        ),
      ),
    ),
  );
  // `MediaPlaybackModel(buffering: true)` renders an indeterminate
  // LinearProgressIndicator (see VideoProgressBar), which drives its own
  // infinitely-repeating AnimationController. `pumpAndSettle` never
  // considers the widget tree "settled" while that ticker is registered, so
  // it must not be used here - pump a bounded number of frames instead.
  if (mediaPlayback?.buffering ?? false) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The `pip` plugin's MethodChannel has no test handler registered by
  // default, so PipManager.dispose (invoked when the ProviderContainer is
  // torn down) throws a MissingPluginException. Stub it out so teardown
  // resolves cleanly instead.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('pip'),
      (call) async => null,
    );
  });

  testWidgets('renders with no active playback model without throwing', (tester) async {
    await _pumpControls(tester);
    expect(find.byType(DesktopControls), findsOneWidget);
  });

  testWidgets('renders playing state with a playback model and queue', (tester) async {
    final item = testItem(id: 'a', name: 'Movie A');
    final next = testItem(id: 'b', name: 'Movie B');
    final model = testPlaybackModel(item: item, queue: [item, next]);

    await _pumpControls(
      tester,
      playbackModel: model,
      mediaPlayback: MediaPlaybackModel(
        playing: true,
        position: const Duration(minutes: 10),
        duration: const Duration(minutes: 90),
        buffer: const Duration(minutes: 12),
      ),
    );

    expect(find.byType(DesktopControls), findsOneWidget);
  });

  testWidgets('renders buffering/paused state and tapping play/pause does not throw', (tester) async {
    final item = testItem(id: 'a', name: 'Movie A');
    final model = testPlaybackModel(item: item);

    await _pumpControls(
      tester,
      playbackModel: model,
      mediaPlayback: MediaPlaybackModel(playing: false, buffering: true),
    );

    expect(find.byType(DesktopControls), findsOneWidget);

    final playPauseButtons = find.byType(IconButton);
    expect(playPauseButtons, findsWidgets);

    // Tap the overlay to toggle it - exercises the GestureDetector callback.
    // Still buffering here (indeterminate progress indicator active), so
    // pump a bounded number of frames rather than pumpAndSettle.
    await tester.tap(find.byType(DesktopControls));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
