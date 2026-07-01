import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/audio_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/playback/playback_queue_state.dart';
import 'package:flutter_test/flutter_test.dart';

ItemBaseModel _videoItem(String id, {Duration? runTime, int playbackPositionTicks = 0}) => ItemBaseModel(
      name: id,
      id: id,
      overview: OverviewModel(runTime: runTime),
      parentId: null,
      playlistId: null,
      images: null,
      childCount: null,
      primaryRatio: null,
      userData: UserData(playbackPositionTicks: playbackPositionTicks),
      canDownload: null,
      canDelete: null,
      jellyType: null,
    );

AudioModel _audioItem(String id, {Duration? runTime}) => AudioModel(
      name: id,
      id: id,
      overview: OverviewModel(runTime: runTime),
      parentId: null,
      playlistId: null,
      images: null,
      childCount: null,
      primaryRatio: null,
      userData: const UserData(),
      parentImages: null,
      mediaStreams: MediaStreamsModel(versionStreams: const []),
      canDelete: null,
      canDownload: null,
      jellyType: null,
    );

PlaybackModel _model(
  ItemBaseModel item, {
  List<ItemBaseModel> queue = const [],
}) =>
    PlaybackModel(
      playbackInfo: null,
      item: item,
      media: null,
      queue: queue,
    );

void main() {
  group('isAudioPlayback', () {
    test('true for an AudioModel item', () {
      expect(_model(_audioItem('a')).isAudioPlayback, isTrue);
    });

    test('false for a non-audio item', () {
      expect(_model(_videoItem('v')).isAudioPlayback, isFalse);
    });
  });

  group('resolvedStopPosition', () {
    test('returns the raw position for video playback', () {
      final model = _model(_videoItem('v'));
      const position = Duration(minutes: 10);
      expect(model.resolvedStopPosition(position, const Duration(minutes: 20)), position);
    });

    test('for audio, prefers the reported total duration', () {
      final model = _model(_audioItem('a', runTime: const Duration(minutes: 3)));
      final result = model.resolvedStopPosition(const Duration(seconds: 30), const Duration(minutes: 4));
      expect(result, const Duration(minutes: 4));
    });

    test('for audio, falls back to the item runtime when no total duration is given', () {
      final model = _model(_audioItem('a', runTime: const Duration(minutes: 3)));
      final result = model.resolvedStopPosition(const Duration(seconds: 30), null);
      expect(result, const Duration(minutes: 3));
    });

    test('for audio, falls back to the raw position when neither is available', () {
      final model = _model(_audioItem('a'));
      final result = model.resolvedStopPosition(const Duration(seconds: 30), null);
      expect(result, const Duration(seconds: 30));
    });
  });

  group('resolvedStartPosition', () {
    test('audio always starts at zero, ignoring any requested position', () async {
      final model = _model(_audioItem('a'));
      final result = await model.resolvedStartPosition(const Duration(minutes: 1));
      expect(result, Duration.zero);
    });

    test('video uses the explicitly requested start position when given', () async {
      final model = _model(_videoItem('v'));
      final result = await model.resolvedStartPosition(const Duration(minutes: 2));
      expect(result, const Duration(minutes: 2));
    });

    test('video falls back to the saved playback position when none is requested', () async {
      final model = _model(_videoItem('v', playbackPositionTicks: 10 * 10000000)); // 10s in ticks
      final result = await model.resolvedStartPosition();
      expect(result, const Duration(seconds: 10));
    });
  });

  group('startDuration', () {
    test('is always zero for audio', () async {
      final model = _model(_audioItem('a'));
      expect(await model.startDuration(), Duration.zero);
    });

    test('mirrors the saved playback position for video', () async {
      final model = _model(_videoItem('v', playbackPositionTicks: 5 * 10000000));
      expect(await model.startDuration(), const Duration(seconds: 5));
    });
  });

  group('nextVideo / previousVideo', () {
    test('delegate to the playback queue relative to the current item', () {
      final a = _videoItem('a');
      final b = _videoItem('b');
      final c = _videoItem('c');
      final model = _model(b, queue: [a, b, c]);

      expect(model.nextVideo?.id, 'c');
      expect(model.previousVideo?.id, 'a');
    });

    test('are null at the edges of a non-repeating queue', () {
      final a = _videoItem('a');
      final model = _model(a, queue: [a]);
      expect(model.nextVideo, isNull);
      expect(model.previousVideo, isNull);
    });
  });

  group('default PlaybackQueueState', () {
    test('is derived from item + queue when not explicitly provided', () {
      final a = _videoItem('a');
      final b = _videoItem('b');
      final model = _model(a, queue: [a, b]);
      expect(model.playbackQueue.mainQueueCurrentId, 'a');
      expect(model.queue.map((e) => e.id).toList(), ['a', 'b']);
    });

    test('an explicitly-provided queue state is used as-is', () {
      final a = _videoItem('a');
      final b = _videoItem('b');
      final explicit = PlaybackQueueState.fromQueue([a, b], initialItemId: 'b');
      final model = PlaybackModel(playbackInfo: null, item: a, media: null, playbackQueue: explicit);
      expect(model.playbackQueue.mainQueueCurrentId, 'b');
    });
  });
}
