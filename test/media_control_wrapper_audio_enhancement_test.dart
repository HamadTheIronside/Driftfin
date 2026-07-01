// Exercises MediaControlsWrapper's live audio-enhancement settings listener
// and its subscription cleanup, using FakeBasePlayer (no live mpv/ExoPlayer).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/providers/settings/video_player_settings_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/util/audio_filter_chain.dart';
import 'package:driftfin/wrappers/media_control_wrapper.dart';

import 'support/video_player_test_support.dart';

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MediaControlsWrapper wrapper;
  late FakeBasePlayer player;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    wrapper = MediaControlsWrapper(ref: container.read(_refProvider));
    player = FakeBasePlayer();
    await wrapper.setup(player);
  });

  tearDown(() => container.dispose());

  test('applies the current (default, off) Night-Mode Audio settings when the player is set up', () {
    expect(player.lastAudioEnhancement?.enableSmartDownmix, isFalse);
    expect(player.lastAudioEnhancement?.dialogueBoost, DialogueBoostLevel.off);
  });

  test('re-applies audio enhancement settings live when they change', () async {
    container.read(videoPlayerSettingsProvider.notifier).setEnableSmartDownmix(true);
    await Future<void>.delayed(Duration.zero);

    expect(player.lastAudioEnhancement?.enableSmartDownmix, isTrue);
  });

  test('dispose closes the audio enhancement settings subscription', () async {
    await wrapper.dispose();
    final callsBeforeChange = player.audioEnhancementCallCount;

    // A settings change after dispose must not reach the disposed player.
    container.read(videoPlayerSettingsProvider.notifier).setDialogueBoost(DialogueBoostLevel.high);
    await Future<void>.delayed(Duration.zero);

    expect(player.audioEnhancementCallCount, callsBeforeChange);
  });
}
