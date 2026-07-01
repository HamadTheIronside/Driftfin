// Exercises BasePlayer.isValidUrl, the one piece of pure logic implemented
// directly on the abstract base class. Everything else on BasePlayer is an
// abstract method delegating to a live player engine (mpv/mdk/native), so a
// minimal no-op subclass is used purely as scaffolding to reach isValidUrl.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/settings/video_player_settings.dart';
import 'package:driftfin/wrappers/players/base_player.dart';
import 'package:driftfin/wrappers/players/player_states.dart';

class _NoopPlayer extends BasePlayer {
  final _controller = StreamController<PlayerState>.broadcast();

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> init(VideoPlayerSettingsModel settings) async {}

  @override
  Widget? videoWidget(Key key, BoxFit fit) => null;

  @override
  Widget? subtitles(bool showOverlay, {GlobalKey? controlsKey}) => null;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> open(BuildContext context) async {}

  @override
  Future<void> loadVideo(String url, bool play, {Duration startPosition = Duration.zero}) async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> loop(bool loop) async {}

  @override
  Future<Uint8List?> takeScreenshot() async => null;

  @override
  Future<int> setSubtitleTrack(SubStreamModel? model, PlaybackModel playbackModel) async => -1;

  @override
  Future<int> setAudioTrack(AudioStreamModel? model, PlaybackModel playbackModel) async => -1;
}

void main() {
  group('BasePlayer.isValidUrl', () {
    late _NoopPlayer player;

    setUp(() {
      player = _NoopPlayer();
    });

    test('accepts absolute http URLs', () {
      final uri = player.isValidUrl('http://example.com/stream.m3u8');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'http');
    });

    test('accepts absolute https URLs', () {
      final uri = player.isValidUrl('https://example.com:8096/videos/1/stream');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
    });

    test('rejects non-http(s) schemes', () {
      expect(player.isValidUrl('ftp://example.com/file'), isNull);
      expect(player.isValidUrl('file:///home/user/video.mp4'), isNull);
    });

    test('rejects relative paths and plain file paths', () {
      expect(player.isValidUrl('/home/user/video.mp4'), isNull);
      expect(player.isValidUrl('relative/path/video.mp4'), isNull);
      expect(player.isValidUrl('C:\\Users\\video.mp4'), isNull);
    });

    test('rejects empty and malformed input', () {
      expect(player.isValidUrl(''), isNull);
      expect(player.isValidUrl('   '), isNull);
      expect(player.isValidUrl('not a url at all'), isNull);
    });
  });
}
