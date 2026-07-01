// Exercises NativePlayer.loadVideo's resume-position behavior by stubbing
// the pigeon-generated VideoPlayerApi's BasicMessageChannel directly, rather
// than a live Android platform channel.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/src/video_player_helper.g.dart';
import 'package:driftfin/wrappers/players/native_player.dart';
import 'package:driftfin/wrappers/players/player_states.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const codec = VideoPlayerApi.pigeonChannelCodec;
  const openChannel = 'dev.flutter.pigeon.io_github_hamadtheironside_driftfin.video.VideoPlayerApi.open';
  const seekToChannel = 'dev.flutter.pigeon.io_github_hamadtheironside_driftfin.video.VideoPlayerApi.seekTo';

  late List<List<Object?>?> openCalls;
  late List<int?> seekToCalls;

  setUp(() {
    openCalls = [];
    seekToCalls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      openChannel,
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        openCalls.add(args);
        return codec.encodeMessage(<Object?>[true]);
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      seekToChannel,
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        seekToCalls.add(args?.first as int?);
        return codec.encodeMessage(<Object?>[null]);
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(openChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(seekToChannel, null);
  });

  group('NativePlayer.loadVideo', () {
    test('opens the url and does not seek when startPosition is zero', () async {
      final player = NativePlayer();
      await player.loadVideo('https://example.com/video.mp4', true);

      expect(openCalls, [
        ['https://example.com/video.mp4', true],
      ]);
      expect(seekToCalls, isEmpty);
    });

    test('seeks to the requested start position after opening', () async {
      final player = NativePlayer();
      await player.loadVideo(
        'https://example.com/video.mp4',
        true,
        startPosition: const Duration(seconds: 30),
      );

      expect(openCalls, [
        ['https://example.com/video.mp4', true],
      ]);
      expect(seekToCalls, [30000]);
    });
  });

  group('NativePlayer.onPlaybackStateChanged', () {
    test('propagates the native failed flag into PlayerState', () {
      final player = NativePlayer();

      player.onPlaybackStateChanged(PlaybackState(
        position: 1000,
        buffered: 1000,
        duration: 60000,
        playing: false,
        buffering: false,
        completed: false,
        failed: true,
      ));

      expect(player.lastState.error?.fatal, isTrue);
    });

    test('a healthy state keeps failed false', () {
      final player = NativePlayer();

      player.onPlaybackStateChanged(PlaybackState(
        position: 1000,
        buffered: 2000,
        duration: 60000,
        playing: true,
        buffering: false,
        completed: false,
        failed: false,
      ));

      expect(player.lastState.error, isNull);
    });

    test('emits the updated state on stateStream', () async {
      final player = NativePlayer();
      final states = <PlayerState>[];
      final sub = player.stateStream.listen(states.add);

      player.onPlaybackStateChanged(PlaybackState(
        position: 0,
        buffered: 0,
        duration: 0,
        playing: false,
        buffering: true,
        completed: false,
        failed: true,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states, isNotEmpty);
      expect(states.last.error?.fatal, isTrue);
      await sub.cancel();
    });
  });
}
