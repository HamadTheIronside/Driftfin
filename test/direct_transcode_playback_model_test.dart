import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/direct_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/playback/playback_queue_state.dart';
import 'package:driftfin/models/playback/transcode_playback_model.dart';
import 'package:flutter_test/flutter_test.dart';

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

AudioStreamModel _audioStream(int index) => AudioStreamModel(
      displayTitle: 'Audio $index',
      name: 'Audio $index',
      codec: 'aac',
      isDefault: index == 0,
      isExternal: false,
      index: index,
      language: 'eng',
      channelLayout: 'stereo',
      sampleRate: null,
      channels: 2,
      bitRate: null,
      bitDepth: null,
      profile: null,
      spatialFormat: null,
    );

SubStreamModel _subStream(int index) => SubStreamModel(
      name: 'Sub $index',
      id: '$index',
      title: 'Sub $index',
      displayTitle: 'Sub $index',
      language: 'eng',
      codec: 'srt',
      isDefault: index == 0,
      isExternal: false,
      index: index,
    );

MediaStreamsModel _mediaStreams({int? defaultAudioStreamIndex, int? defaultSubStreamIndex}) => MediaStreamsModel(
      defaultAudioStreamIndex: defaultAudioStreamIndex,
      defaultSubStreamIndex: defaultSubStreamIndex,
      versionStreams: [
        VersionStreamModel(
          name: 'v1',
          index: 0,
          defaultAudioStreamIndex: defaultAudioStreamIndex,
          defaultSubStreamIndex: defaultSubStreamIndex,
          videoStreams: const [],
          audioStreams: [_audioStream(0), _audioStream(1)],
          subStreams: [_subStream(0), _subStream(1)],
        ),
      ],
    );

void main() {
  group('DirectPlaybackModel', () {
    test('subStreams prepends the synthetic "off" option', () {
      final model = DirectPlaybackModel(item: _item('a'), media: null, mediaStreams: _mediaStreams());
      expect(model.subStreams.map((e) => e.index).toList(), [-1, 0, 1]);
    });

    test('audioStreams prepends the synthetic "off" option', () {
      final model = DirectPlaybackModel(item: _item('a'), media: null, mediaStreams: _mediaStreams());
      expect(model.audioStreams.map((e) => e.index).toList(), [-1, 0, 1]);
    });

    test('subStreams/audioStreams degrade gracefully with null mediaStreams', () {
      final model = DirectPlaybackModel(item: _item('a'), media: null);
      expect(model.subStreams.map((e) => e.index).toList(), [-1]);
      expect(model.audioStreams.map((e) => e.index).toList(), [-1]);
    });

    test('itemsInQueue assigns sequential synthetic playlistItemIds', () {
      final model = DirectPlaybackModel(
        item: _item('a'),
        media: null,
        queue: [_item('a'), _item('b'), _item('c')],
      );
      expect(model.itemsInQueue.map((e) => e.playlistItemId).toList(),
          ['playlistItem0', 'playlistItem1', 'playlistItem2']);
      expect(model.itemsInQueue.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('updateUserData copies onto the item without touching other fields', () {
      final model = DirectPlaybackModel(item: _item('a'), media: null);
      final updated = model.updateUserData(const UserData(isFavourite: true));
      expect(updated?.item.userData.isFavourite, isTrue);
      expect(updated?.item.id, 'a');
    });

    test('updatePlaybackQueue swaps only the queue state', () {
      final a = _item('a');
      final b = _item('b');
      final model = DirectPlaybackModel(item: a, media: null, queue: [a, b]);
      final newQueue = PlaybackQueueState.fromQueue([a, b], initialItemId: 'b');
      final updated = model.updatePlaybackQueue(newQueue);
      expect(updated.playbackQueue.mainQueueCurrentId, 'b');
      expect(updated.item.id, 'a');
    });

    test('copyWith with no arguments preserves every field', () {
      final model = DirectPlaybackModel(item: _item('a'), media: const Media(url: 'u'), bitRateOptions: const {});
      final copy = model.copyWith();
      expect(copy.item.id, model.item.id);
      expect(copy.media?.url, 'u');
    });
  });

  group('TranscodePlaybackModel', () {
    test('subStreams/audioStreams prepend the synthetic "off" option', () {
      final model = TranscodePlaybackModel(
        item: _item('a'),
        media: null,
        playbackInfo: null,
        mediaStreams: _mediaStreams(),
      );
      expect(model.subStreams.map((e) => e.index).toList(), [-1, 0, 1]);
      expect(model.audioStreams.map((e) => e.index).toList(), [-1, 0, 1]);
    });

    test('itemsInQueue assigns sequential synthetic playlistItemIds', () {
      final model = TranscodePlaybackModel(
        item: _item('a'),
        media: null,
        playbackInfo: null,
        queue: [_item('a'), _item('b')],
      );
      expect(model.itemsInQueue.map((e) => e.playlistItemId).toList(), ['playlistItem0', 'playlistItem1']);
    });

    test('updateUserData copies onto the item', () {
      final model = TranscodePlaybackModel(item: _item('a'), media: null, playbackInfo: null);
      final updated = model.updateUserData(const UserData(played: true));
      expect(updated?.item.userData.played, isTrue);
    });

    test('updatePlaybackQueue swaps only the queue state', () {
      final a = _item('a');
      final b = _item('b');
      final model = TranscodePlaybackModel(item: a, media: null, playbackInfo: null, queue: [a, b]);
      final newQueue = PlaybackQueueState.fromQueue([a, b], initialItemId: 'b');
      final updated = model.updatePlaybackQueue(newQueue);
      expect(updated.playbackQueue.mainQueueCurrentId, 'b');
    });
  });
}
