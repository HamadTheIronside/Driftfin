import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/channel_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/media_playback_model.dart';
import 'package:driftfin/models/playback/direct_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/playback/transcode_playback_model.dart';
import 'package:driftfin/models/playback/tv_playback_model.dart';
import 'package:driftfin/models/video_stream_model.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldFallbackToTranscode', () {
    test('true for a DirectPlaybackModel', () {
      final model = DirectPlaybackModel(item: _item('a'), media: null);
      expect(shouldFallbackToTranscode(model), isTrue);
    });

    test('false for a TranscodePlaybackModel (already the fallback)', () {
      final model = TranscodePlaybackModel(item: _item('a'), media: null, playbackInfo: null);
      expect(shouldFallbackToTranscode(model), isFalse);
    });

    test('false for a TvPlaybackModel (live TV has no further fallback)', () {
      final model = TvPlaybackModel(
        channel: ChannelModel(
          channelId: 'c',
          startDate: DateTime(2026),
          endDate: DateTime(2026),
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
        item: _item('a'),
        media: null,
        playbackInfo: null,
      );
      expect(shouldFallbackToTranscode(model), isFalse);
    });

    test('false when there is no current model', () {
      expect(shouldFallbackToTranscode(null), isFalse);
    });
  });

  group('VideoPlayerNotifier.fallbackToTranscodeOnFailure', () {
    late _FakePlaybackModelHelper fakeHelper;
    late ProviderContainer container;
    late VideoPlayerNotifier notifier;

    Future<void> setUpWith({required PlaybackModel? currentModel, PlaybackModel? fallbackResult}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      fakeHelper = _FakePlaybackModelHelper(fallbackResult);
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          playBackModel.overrideWith((ref) => currentModel),
          mediaPlaybackProvider.overrideWith((ref) => MediaPlaybackModel(
                position: const Duration(minutes: 2),
                playing: true,
              )),
          playbackModelHelper.overrideWithValue(fakeHelper),
        ],
      );
      addTearDown(container.dispose);
      notifier = VideoPlayerNotifier(container.read(_refProvider));
    }

    test('does nothing for a non-Direct model (e.g. already transcoding)', () async {
      final transcode = TranscodePlaybackModel(item: _item('a'), media: null, playbackInfo: null);
      await setUpWith(currentModel: transcode);

      await notifier.fallbackToTranscodeOnFailure();

      expect(fakeHelper.calls, 0);
    });

    test('requests a forced transcode at the current position for a DirectPlaybackModel', () async {
      final direct = DirectPlaybackModel(item: _item('a'), media: null);
      final transcode = TranscodePlaybackModel(item: _item('a'), media: null, playbackInfo: null);
      await setUpWith(currentModel: direct, fallbackResult: transcode);

      await notifier.fallbackToTranscodeOnFailure();

      expect(fakeHelper.calls, 1);
      expect(fakeHelper.lastForcedType, PlaybackType.transcode);
      expect(fakeHelper.lastOldModel, direct);
      expect(fakeHelper.lastStartPosition, const Duration(minutes: 2));
      expect(container.read(playBackModel), transcode);
    });

    test('only attempts the fallback once per notifier instance', () async {
      final direct = DirectPlaybackModel(item: _item('a'), media: null);
      final transcode = TranscodePlaybackModel(item: _item('a'), media: null, playbackInfo: null);
      await setUpWith(currentModel: direct, fallbackResult: transcode);

      await notifier.fallbackToTranscodeOnFailure();
      await notifier.fallbackToTranscodeOnFailure();

      expect(fakeHelper.calls, 1);
    });

    test('leaves playBackModel untouched when the helper cannot produce a fallback', () async {
      final direct = DirectPlaybackModel(item: _item('a'), media: null);
      await setUpWith(currentModel: direct, fallbackResult: null);

      await notifier.fallbackToTranscodeOnFailure();

      expect(fakeHelper.calls, 1);
      expect(container.read(playBackModel), direct);
    });

    test('swallows errors thrown by the helper instead of propagating them', () async {
      final direct = DirectPlaybackModel(item: _item('a'), media: null);
      await setUpWith(currentModel: direct);
      fakeHelper.shouldThrow = true;

      await expectLater(notifier.fallbackToTranscodeOnFailure(), completes);
    });
  });
}

final _refProvider = Provider<Ref>((ref) => ref);

class _FakePlaybackModelHelper extends PlaybackModelHelper {
  // The fake never touches `ref` (createPlaybackModel is fully overridden
  // below), so a throwaway container just satisfies the required field.
  _FakePlaybackModelHelper(this.result) : super(ref: ProviderContainer().read(_refProvider));

  final PlaybackModel? result;
  bool shouldThrow = false;
  int calls = 0;
  PlaybackType? lastForcedType;
  PlaybackModel? lastOldModel;
  Duration? lastStartPosition;

  @override
  Future<PlaybackModel?> createPlaybackModel(
    BuildContext? context,
    ItemBaseModel? item, {
    PlaybackModel? oldModel,
    List<ItemBaseModel>? libraryQueue,
    PlaybackQueueSource? queueSource,
    bool showPlaybackOptions = false,
    PlaybackType? forcedPlaybackType,
    Duration? startPosition,
  }) async {
    calls++;
    lastForcedType = forcedPlaybackType;
    lastOldModel = oldModel;
    lastStartPosition = startPosition;
    if (shouldThrow) throw Exception('boom');
    return result;
  }
}
