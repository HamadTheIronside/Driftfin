// Shared fakes/helpers for widget tests that exercise video-player screens
// without touching a live media_kit/ExoPlayer backend.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/direct_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/wrappers/media_control_wrapper.dart';
import 'package:driftfin/wrappers/players/base_player.dart';
import 'package:driftfin/wrappers/players/player_states.dart';

/// Minimal [BasePlayer] fake: every call is a no-op, no widgets/platform
/// channels are touched.
class FakeBasePlayer implements BasePlayer {
  @override
  PlayerState lastState = PlayerState();

  @override
  Stream<PlayerState> get stateStream => const Stream.empty();

  @override
  Future<void> init(settings) async {}

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
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> addToPlaylist(String url) async {}

  @override
  Future<void> removeFromPlaylist(int index) async {}

  @override
  Future<void> playerNext() async {}

  @override
  Future<void> playerPrevious() async {}

  @override
  Stream<int> get playlistIndexStream => const Stream.empty();

  @override
  Future<Uint8List?> takeScreenshot() async => null;

  @override
  Future<int> setSubtitleTrack(model, playbackModel) async => -1;

  @override
  Future<int> setAudioTrack(model, playbackModel) async => -1;

  @override
  void applySubtitleSettings(settings) {}

  @override
  Future<void> setSubtitleDelay(Duration delay) async {}

  @override
  Uri? isValidUrl(String input) => null;
}

/// Fake [VideoPlayerNotifier] whose state is a [MediaControlsWrapper] backed
/// by [FakeBasePlayer] — avoids AudioService.init entirely (the real
/// [VideoPlayerNotifier.init] is never called).
class FakeVideoPlayerNotifier extends VideoPlayerNotifier {
  FakeVideoPlayerNotifier(super.ref);

  Future<void> setupFake() async {
    await state.setup(FakeBasePlayer());
  }
}

ItemBaseModel testItem({
  String id = 'item-1',
  String name = 'Test Item',
  Duration? runTime,
}) =>
    ItemBaseModel(
      name: name,
      id: id,
      overview: OverviewModel(runTime: runTime),
      parentId: null,
      playlistId: null,
      images: null,
      childCount: null,
      primaryRatio: null,
      userData: const UserData(),
      canDownload: null,
      canDelete: null,
      jellyType: null,
    );

PlaybackModel testPlaybackModel({ItemBaseModel? item, List<ItemBaseModel> queue = const []}) {
  return DirectPlaybackModel(
    item: item ?? testItem(),
    media: const Media(url: 'https://example.com/video.mp4'),
    queue: queue,
  );
}
