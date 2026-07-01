import 'package:driftfin/models/items/channel_model.dart';
import 'package:driftfin/models/items/channel_program.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/tv_playback_model.dart';
import 'package:flutter_test/flutter_test.dart';

ChannelProgram _program(String id, {DateTime? start, DateTime? end}) => ChannelProgram(
      id: id,
      channelId: 'chan1',
      name: 'Program $id',
      officialRating: '',
      productionYear: 2024,
      indexNumber: 0,
      parentIndexNumber: 0,
      startDate: start ?? DateTime(2024, 1, 1, 10),
      endDate: end ?? DateTime(2024, 1, 1, 11),
      isSeries: false,
    );

ChannelModel _channel({List<ChannelProgram> programs = const [], ChannelProgram? current}) => ChannelModel(
      channelId: 'chan1',
      programs: programs,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 2),
      iCurrentProgram: current,
      name: 'Channel 1',
      id: 'chan1',
      overview: const OverviewModel(),
      parentId: null,
      playlistId: null,
      images: null,
      childCount: null,
      primaryRatio: null,
      userData: const UserData(),
      canDownload: false,
      canDelete: false,
    );

void main() {
  group('TvPlaybackModel.playingProgram', () {
    test('prefers the explicitly-tracked currentProgram over the channel program', () {
      final channelProgram = _program('channel-current');
      final trackedProgram = _program('tracked');
      final channel = _channel(current: channelProgram);
      final model = TvPlaybackModel(channel: channel, item: channel, currentProgram: trackedProgram);

      expect(model.playingProgram?.id, 'tracked');
    });

    test('falls back to the channel current program when none is tracked yet', () {
      final channelProgram = _program('channel-current');
      final channel = _channel(current: channelProgram);
      final model = TvPlaybackModel(channel: channel, item: channel);

      expect(model.playingProgram?.id, 'channel-current');
    });

    test('is null when neither the model nor channel has a program', () {
      final channel = _channel();
      final model = TvPlaybackModel(channel: channel, item: channel);
      expect(model.playingProgram, isNull);
    });
  });

  group('TvPlaybackModel.item', () {
    test('derives the item from the playing program when one exists', () {
      final program = _program('p1');
      final channel = _channel(current: program);
      final model = TvPlaybackModel(channel: channel, item: channel);

      expect(model.item.id, 'p1');
      expect(model.item.parentId, 'chan1', reason: 'toItemBaseModel maps channelId to parentId');
    });

    test('falls back to the channel itself when there is no program', () {
      final channel = _channel();
      final model = TvPlaybackModel(channel: channel, item: channel);
      expect(model.item.id, 'chan1');
    });
  });

  group('TvPlaybackModel.copyWith', () {
    test('overrides only the named fields and keeps the rest', () {
      final channel = _channel();
      final model = TvPlaybackModel(channel: channel, item: channel, isNativePlayerBackend: false);

      final newProgram = _program('new');
      final updated =
          model.copyWith(currentProgram: newProgram, position: const Duration(minutes: 1)) as TvPlaybackModel;

      expect(updated.currentProgram?.id, 'new');
      expect(updated.position, const Duration(minutes: 1));
      expect(updated.channel.id, channel.id);
      expect(updated.isNativePlayerBackend, isFalse);
    });

    test('updateUserData never actually takes effect (known bug)', () {
      // BUG: TvPlaybackModel.item is an override getter — `playingProgram?.toItemBaseModel() ?? channel` —
      // that always recomputes from `channel`/`currentProgram`, ignoring the stored `item` field entirely.
      // updateUserData() writes `item.copyWith(userData: ...)` into that stored field via copyWith(item: ...),
      // but the very next read of `.item` throws the update away, with or without an active program.
      // Documented here rather than silently fixed, since the correct fix (push userData onto the
      // channel or the current program, whichever is active) is a design decision beyond test scope.
      final program = _program('p1');
      final channel = _channel(current: program);
      final withProgram = TvPlaybackModel(channel: channel, item: channel);
      expect(withProgram.updateUserData(const UserData(isFavourite: true))?.item.userData.isFavourite, isFalse);

      final noProgramChannel = _channel();
      final withoutProgram = TvPlaybackModel(channel: noProgramChannel, item: noProgramChannel);
      expect(withoutProgram.updateUserData(const UserData(isFavourite: true))?.item.userData.isFavourite, isFalse);
    });
  });
}
