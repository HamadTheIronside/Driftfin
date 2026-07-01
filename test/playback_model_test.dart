import 'package:flutter/material.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/audio_model.dart';
import 'package:driftfin/models/items/channel_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/direct_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/playback/playback_queue_state.dart';
import 'package:driftfin/models/playback/transcode_playback_model.dart';
import 'package:driftfin/models/playback/tv_playback_model.dart';
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

  AudioStreamModel buildAudioStream(int index) => AudioStreamModel(
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

  SubStreamModel buildSubStream(int index) => SubStreamModel(
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

  MediaStreamsModel buildMediaStreams({int? defaultAudioStreamIndex, int? defaultSubStreamIndex}) => MediaStreamsModel(
        defaultAudioStreamIndex: defaultAudioStreamIndex,
        defaultSubStreamIndex: defaultSubStreamIndex,
        versionStreams: [
          VersionStreamModel(
            name: 'v1',
            index: 0,
            defaultAudioStreamIndex: defaultAudioStreamIndex,
            defaultSubStreamIndex: defaultSubStreamIndex,
            videoStreams: const [],
            audioStreams: [buildAudioStream(0), buildAudioStream(1)],
            subStreams: [buildSubStream(0), buildSubStream(1)],
          ),
        ],
      );

  group('PlaybackModelExtension.defaultSubStream', () {
    test('null on a null PlaybackModel', () {
      const PlaybackModel? model = null;
      expect(model.defaultSubStream, isNull);
    });

    test('null when the model has no mediaStreams (subStreams still resolves via DirectPlaybackModel override)', () {
      final model = DirectPlaybackModel(item: _videoItem('a'), media: null);
      // DirectPlaybackModel.subStreams always has at least the synthetic "off" entry.
      expect(model.subStreams, isNotEmpty);
      // defaultSubStreamIndex is null -> falls back to SubStreamModel.no().
      expect(model.defaultSubStream?.index, -1);
    });

    test('finds the sub stream matching mediaStreams.defaultSubStreamIndex', () {
      final model = DirectPlaybackModel(
        item: _videoItem('a'),
        media: null,
        mediaStreams: buildMediaStreams(defaultSubStreamIndex: 1),
      );
      expect(model.defaultSubStream?.index, 1);
    });

    test('falls back to SubStreamModel.no() when no sub stream matches the index', () {
      final model = DirectPlaybackModel(
        item: _videoItem('a'),
        media: null,
        mediaStreams: buildMediaStreams(defaultSubStreamIndex: 99),
      );
      expect(model.defaultSubStream?.index, -1);
      expect(model.defaultSubStream?.title, 'Off');
    });
  });

  group('PlaybackModelExtension.defaultAudioStream', () {
    test('null on a null PlaybackModel', () {
      const PlaybackModel? model = null;
      expect(model.defaultAudioStream, isNull);
    });

    test('finds the audio stream matching mediaStreams.defaultAudioStreamIndex', () {
      final model = DirectPlaybackModel(
        item: _videoItem('a'),
        media: null,
        mediaStreams: buildMediaStreams(defaultAudioStreamIndex: 0),
      );
      expect(model.defaultAudioStream?.index, 0);
    });

    test('falls back to AudioStreamModel.no() when no audio stream matches the index', () {
      final model = DirectPlaybackModel(
        item: _videoItem('a'),
        media: null,
        mediaStreams: buildMediaStreams(defaultAudioStreamIndex: 99),
      );
      expect(model.defaultAudioStream?.index, -1);
      expect(model.defaultAudioStream?.displayTitle, 'Off');
    });
  });

  group('PlaybackModelExtension.label', () {
    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();
      return capturedContext;
    }

    testWidgets('returns the localized name for each concrete PlaybackModel subtype', (tester) async {
      final context = await pumpContext(tester);
      final l10n = AppLocalizations.of(context);

      final direct = DirectPlaybackModel(item: _videoItem('a'), media: null);
      final transcode = TranscodePlaybackModel(item: _videoItem('a'), media: null, playbackInfo: null);
      final tv = TvPlaybackModel(
        channel: ChannelModel(
          channelId: 'c',
          startDate: DateTime(2024),
          endDate: DateTime(2024),
          iCurrentProgram: null,
          name: 'c',
          id: 'c',
          overview: const OverviewModel(),
          parentId: null,
          playlistId: null,
          images: null,
          childCount: null,
          primaryRatio: null,
          userData: const UserData(),
          canDownload: null,
          canDelete: null,
        ),
        isNativePlayerBackend: false,
        item: _videoItem('a'),
        media: null,
        playbackInfo: null,
      );

      expect(direct.label(context), l10n.playbackTypeDirect);
      expect(transcode.label(context), l10n.playbackTypeTranscode);
      expect(tv.label(context), l10n.playbackTypeTV);
    });

    testWidgets('falls back to "unknown" for a plain PlaybackModel and for null', (tester) async {
      final context = await pumpContext(tester);
      final l10n = AppLocalizations.of(context);

      final plain = _model(_videoItem('a'));
      expect(plain.label(context), l10n.unknown);

      const PlaybackModel? nullModel = null;
      expect(nullModel.label(context), l10n.unknown);
    });
  });
}
