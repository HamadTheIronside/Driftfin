// Tests the pure queue-manipulation surface of MediaControlsWrapper's
// AudioQueueHandler extension (lib/wrappers/audio_queue_handler.dart).
//
// These methods only read/write the `playBackModel` provider; they don't
// touch a real player backend (the internal `_player` field stays null,
// which short-circuits `_syncMpvPlaylist()` and the crossfade/mpv-only
// branches). That lets us exercise them against a real MediaControlsWrapper
// without a live mpv/mdk/native engine.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/media_playback_model.dart';
import 'package:driftfin/models/playback/direct_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/playback/playback_queue_state.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/wrappers/media_control_wrapper.dart';

ItemBaseModel _item(String id) => ItemBaseModel(
      name: id,
      id: id,
      overview: const OverviewModel(),
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

PlaybackModel _model(List<ItemBaseModel> queue, {String? currentId, AudioRepeatMode repeatMode = AudioRepeatMode.off}) {
  final current = currentId != null ? queue.firstWhere((e) => e.id == currentId) : queue.first;
  return DirectPlaybackModel(
    playbackInfo: null,
    item: current,
    media: null,
    playbackQueue: PlaybackQueueState.fromQueue(queue, initialItemId: current.id, repeatMode: repeatMode),
  );
}

void main() {
  group('MediaControlsWrapper audio queue extension', () {
    late ProviderContainer container;
    late MediaControlsWrapper wrapper;

    setUp(() {
      container = ProviderContainer();
      final refProvider = Provider<Ref>((ref) => ref);
      wrapper = MediaControlsWrapper(ref: container.read(refProvider));
    });

    tearDown(() {
      container.dispose();
    });

    test('fullAudioQueue returns empty list when nothing is playing', () {
      expect(wrapper.fullAudioQueue(), isEmpty);
    });

    test('fullAudioQueue reflects the current playback queue', () {
      final items = [_item('a'), _item('b'), _item('c')];
      container.read(playBackModel.notifier).state = _model(items);

      expect(wrapper.fullAudioQueue().map((e) => e.id), ['a', 'b', 'c']);
    });

    test('audioQueueForDisplay returns empty when no playback model', () {
      expect(wrapper.audioQueueForDisplay(wrapAround: false), isEmpty);
    });

    test('audioQueueForDisplay returns current item followed by the rest, no wrap-around', () {
      final items = [_item('a'), _item('b'), _item('c')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      final display = wrapper.audioQueueForDisplay(wrapAround: false);
      expect(display.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('temporaryQueueStartInDisplay and count are null with an empty next-up queue', () {
      final items = [_item('a'), _item('b')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      expect(wrapper.temporaryQueueStartInDisplay(wrapAround: false), isNull);
      expect(wrapper.temporaryQueueCountInDisplay(), isNull);
    });

    test('temporaryQueueStartInDisplay/count reflect items added to the next-up queue', () {
      final items = [_item('a'), _item('b')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      wrapper.clearTemporaryQueue();
      // Add via the internal update path used by addToTemporaryQueue when a
      // model already exists.
      final extra = [_item('x'), _item('y')];
      // Reach the queue-state update through the public API.
      // (addToTemporaryQueue awaits _syncMpvPlaylist internally, which is a
      // no-op when _player is null.)
      // ignore: unawaited_futures
      wrapper.addToTemporaryQueue(extra);

      expect(wrapper.temporaryQueueCountInDisplay(), 2);
      expect(wrapper.temporaryQueueStartInDisplay(wrapAround: false), 1);
    });

    test('setShuffleEnabled updates both playbackQueue and mediaPlaybackProvider', () async {
      final items = [_item('a'), _item('b'), _item('c')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      await wrapper.setShuffleEnabled(true);

      expect(container.read(playBackModel)?.playbackQueue.shuffleEnabled, isTrue);
      expect(container.read(mediaPlaybackProvider).shuffleEnabled, isTrue);
    });

    test('setAudioRepeatMode updates both playbackQueue and mediaPlaybackProvider', () async {
      final items = [_item('a'), _item('b')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      await wrapper.setAudioRepeatMode(AudioRepeatMode.one);

      expect(container.read(playBackModel)?.playbackQueue.repeatMode, AudioRepeatMode.one);
      expect(container.read(mediaPlaybackProvider).repeatMode, AudioRepeatMode.one);
    });

    test('removeAudioQueueItem removes the item from the queue', () async {
      final items = [_item('a'), _item('b'), _item('c')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      await wrapper.removeAudioQueueItem('b');

      expect(wrapper.fullAudioQueue().map((e) => e.id), ['a', 'c']);
    });

    test('clearTemporaryQueue empties the next-up queue', () async {
      final items = [_item('a'), _item('b')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');
      // ignore: unawaited_futures
      wrapper.addToTemporaryQueue([_item('x')]);
      expect(container.read(playBackModel)?.playbackQueue.nextUpQueue, isNotEmpty);

      wrapper.clearTemporaryQueue();

      expect(container.read(playBackModel)?.playbackQueue.nextUpQueue, isEmpty);
    });

    test('addToTemporaryQueue is a no-op for an empty list', () async {
      final items = [_item('a')];
      container.read(playBackModel.notifier).state = _model(items, currentId: 'a');

      await wrapper.addToTemporaryQueue([]);

      expect(container.read(playBackModel)?.playbackQueue.nextUpQueue, isEmpty);
    });
  });
}
