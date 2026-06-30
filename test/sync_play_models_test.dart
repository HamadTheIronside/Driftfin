import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/syncplay/sync_play_models.dart';

void main() {
  group('SyncGroupState.parse', () {
    test('maps known states case-insensitively', () {
      expect(SyncGroupState.parse('Idle'), SyncGroupState.idle);
      expect(SyncGroupState.parse('WAITING'), SyncGroupState.waiting);
      expect(SyncGroupState.parse('paused'), SyncGroupState.paused);
      expect(SyncGroupState.parse('Playing'), SyncGroupState.playing);
    });

    test('falls back to unknown for null/garbage', () {
      expect(SyncGroupState.parse(null), SyncGroupState.unknown);
      expect(SyncGroupState.parse('nonsense'), SyncGroupState.unknown);
    });
  });

  group('SyncGroupUpdateType.parse', () {
    test('maps every discriminator the server sends', () {
      expect(SyncGroupUpdateType.parse('GroupJoined'), SyncGroupUpdateType.groupJoined);
      expect(SyncGroupUpdateType.parse('GroupLeft'), SyncGroupUpdateType.groupLeft);
      expect(SyncGroupUpdateType.parse('UserJoined'), SyncGroupUpdateType.userJoined);
      expect(SyncGroupUpdateType.parse('UserLeft'), SyncGroupUpdateType.userLeft);
      expect(SyncGroupUpdateType.parse('StateUpdate'), SyncGroupUpdateType.stateUpdate);
      expect(SyncGroupUpdateType.parse('PlayQueue'), SyncGroupUpdateType.playQueue);
      expect(SyncGroupUpdateType.parse('NotInGroup'), SyncGroupUpdateType.notInGroup);
      expect(SyncGroupUpdateType.parse('GroupDoesNotExist'), SyncGroupUpdateType.groupDoesNotExist);
      expect(SyncGroupUpdateType.parse('LibraryAccessDenied'), SyncGroupUpdateType.libraryAccessDenied);
    });

    test('falls back to unknown', () {
      expect(SyncGroupUpdateType.parse(null), SyncGroupUpdateType.unknown);
      expect(SyncGroupUpdateType.parse('Whatever'), SyncGroupUpdateType.unknown);
    });
  });

  group('SyncPlayGroupUpdate.fromJson', () {
    test('decodes the PascalCase envelope and exposes groupInfo for a map payload', () {
      final update = SyncPlayGroupUpdate.fromJson({
        'Type': 'GroupJoined',
        'GroupId': 'abc-123',
        'Data': {'GroupName': 'Movie night', 'Participants': []},
      });
      expect(update.type, SyncGroupUpdateType.groupJoined);
      expect(update.groupId, 'abc-123');
      expect(update.groupInfo, isNotNull);
      expect(update.groupInfo!['GroupName'], 'Movie night');
    });

    test('groupInfo is null when Data is a non-map (e.g. a participant name string)', () {
      final update = SyncPlayGroupUpdate.fromJson({
        'Type': 'UserJoined',
        'GroupId': 'abc-123',
        'Data': 'Alice',
      });
      expect(update.type, SyncGroupUpdateType.userJoined);
      expect(update.groupInfo, isNull);
      expect(update.data, 'Alice');
    });

    test('tolerates missing GroupId/Data', () {
      final update = SyncPlayGroupUpdate.fromJson({'Type': 'GroupLeft'});
      expect(update.type, SyncGroupUpdateType.groupLeft);
      expect(update.groupId, isNull);
      expect(update.data, isNull);
    });
  });

  group('parseSyncCommand', () {
    test('resume is Unpause, not Play (the Jellyfin gotcha)', () {
      expect(parseSyncCommand('Unpause'), SyncCommand.unpause);
      expect(parseSyncCommand('Play'), SyncCommand.unknown);
    });

    test('maps the remaining commands and falls back to unknown', () {
      expect(parseSyncCommand('Pause'), SyncCommand.pause);
      expect(parseSyncCommand('Stop'), SyncCommand.stop);
      expect(parseSyncCommand('Seek'), SyncCommand.seek);
      expect(parseSyncCommand(null), SyncCommand.unknown);
    });
  });
}
