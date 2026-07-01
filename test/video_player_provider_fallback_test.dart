import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/channel_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/direct_playback_model.dart';
import 'package:driftfin/models/playback/transcode_playback_model.dart';
import 'package:driftfin/models/playback/tv_playback_model.dart';
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
}
