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

  group('parseSyncRelayKind', () {
    test('maps every relay kind case-insensitively', () {
      expect(parseSyncRelayKind('Chat'), SyncRelayKind.chat);
      expect(parseSyncRelayKind('REACTION'), SyncRelayKind.reaction);
      expect(parseSyncRelayKind('typing'), SyncRelayKind.typing);
      expect(parseSyncRelayKind('Buffering'), SyncRelayKind.buffering);
    });

    test('falls back to unknown for null/garbage', () {
      expect(parseSyncRelayKind(null), SyncRelayKind.unknown);
      expect(parseSyncRelayKind('whatever'), SyncRelayKind.unknown);
    });
  });

  group('SyncRelayMessage.tryParse', () {
    test('parses a chat payload carrying the Driftfin relay marker', () {
      final msg = SyncRelayMessage.tryParse(
        header: syncRelayMarker,
        text: '{"k":"chat","s":"Alice","t":"hello"}',
      );
      expect(msg, isNotNull);
      expect(msg!.kind, SyncRelayKind.chat);
      expect(msg.sender, 'Alice');
      expect(msg.text, 'hello');
      expect(msg.emoji, isNull);
    });

    test('parses a reaction payload', () {
      final msg = SyncRelayMessage.tryParse(
        header: syncRelayMarker,
        text: '{"k":"reaction","s":"Bob","e":"👍"}',
      );
      expect(msg, isNotNull);
      expect(msg!.kind, SyncRelayKind.reaction);
      expect(msg.emoji, '👍');
    });

    test('null when the header is not the Driftfin relay marker (a genuine admin DisplayMessage)', () {
      final msg = SyncRelayMessage.tryParse(header: 'Server Admin', text: '{"k":"chat","s":"Alice","t":"hi"}');
      expect(msg, isNull);
    });

    test('null when the marker is present but text is not valid JSON', () {
      final msg = SyncRelayMessage.tryParse(header: syncRelayMarker, text: 'not json');
      expect(msg, isNull);
    });

    test('null when JSON is valid but not an object', () {
      final msg = SyncRelayMessage.tryParse(header: syncRelayMarker, text: '[1,2,3]');
      expect(msg, isNull);
    });

    test('null when the sender field is missing or empty', () {
      expect(SyncRelayMessage.tryParse(header: syncRelayMarker, text: '{"k":"chat","t":"hi"}'), isNull);
      expect(SyncRelayMessage.tryParse(header: syncRelayMarker, text: '{"k":"chat","s":"","t":"hi"}'), isNull);
    });

    test('unrecognized kind decodes to unknown rather than throwing', () {
      final msg = SyncRelayMessage.tryParse(header: syncRelayMarker, text: '{"k":"bogus","s":"Alice"}');
      expect(msg, isNotNull);
      expect(msg!.kind, SyncRelayKind.unknown);
    });
  });
}
