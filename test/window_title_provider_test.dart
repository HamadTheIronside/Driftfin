import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/media_playback_model.dart';
import 'package:driftfin/providers/dashboard_mode_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/providers/window_title_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // window_manager's setTitle uses a MethodChannel with no test handler
  // registered; stub it out so it resolves instead of throwing/hanging.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      (call) async => null,
    );
  });

  ProviderContainer container() {
    final c = ProviderContainer();
    c.read(windowTitleProvider); // build the notifier
    return c;
  }

  group('WindowTitleNotifier', () {
    test('defaults to the app name with no nav title or play title', () async {
      final c = container();
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin');
    });

    test('updateTitle sets a nav title that becomes the window title', () async {
      final c = container();
      addTearDown(c.dispose);
      c.read(windowTitleProvider.notifier).updateTitle('key1', 'Home');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - Home');
    });

    test('the most recently pushed title wins (stack behavior)', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'First');
      notifier.updateTitle('b', 'Second');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - Second');
    });

    test('re-pushing an existing key moves it back to the top of the stack', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'First');
      notifier.updateTitle('b', 'Second');
      notifier.updateTitle('a', 'First Updated');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - First Updated');
    });

    test('removeTitle falls back to the next title on the stack', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'First');
      notifier.updateTitle('b', 'Second');
      notifier.removeTitle('b');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - First');
    });

    test('removeTitle for an untracked key is a no-op', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'First');
      await Future<void>.delayed(Duration.zero);
      final before = c.read(windowTitleProvider);
      notifier.removeTitle('never-added');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), before);
    });

    test('clearStack resets the nav title', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'First');
      await Future<void>.delayed(Duration.zero);
      notifier.clearStack();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin');
    });

    test('setPlayTitle is used while the player is active and not minimized', () async {
      final c = container();
      addTearDown(c.dispose);
      c.read(mediaPlaybackProvider.notifier).state = MediaPlaybackModel(state: VideoPlayerState.fullScreen);
      c.read(windowTitleProvider.notifier).setPlayTitle('Now Playing');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - Now Playing');
    });

    test('nav title wins over play title while the player is minimized', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'Nav Title');
      notifier.setPlayTitle('Now Playing');
      c.read(mediaPlaybackProvider.notifier).state = MediaPlaybackModel(state: VideoPlayerState.minimized);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - Nav Title');
    });

    test('play title wins over nav title when the player is expanded', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'Nav Title');
      notifier.setPlayTitle('Now Playing');
      c.read(mediaPlaybackProvider.notifier).state = MediaPlaybackModel(state: VideoPlayerState.fullScreen);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - Now Playing');
    });

    test('falls back to nav title when play title is null even if player is active', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'Nav Title');
      c.read(mediaPlaybackProvider.notifier).state = MediaPlaybackModel(state: VideoPlayerState.fullScreen);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Driftfin - Nav Title');
    });

    test('music dashboard mode swaps the app name to Tjilp', () async {
      final c = container();
      addTearDown(c.dispose);
      c.read(musicDashboardModeProvider.notifier).state = true;
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), 'Tjilp');
    });

    test('refreshTitle recomputes without changing any inputs', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(windowTitleProvider.notifier);
      notifier.updateTitle('a', 'First');
      await Future<void>.delayed(Duration.zero);
      final before = c.read(windowTitleProvider);
      notifier.refreshTitle();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(windowTitleProvider), before);
    });
  });
}
