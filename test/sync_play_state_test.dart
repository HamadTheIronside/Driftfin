import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/syncplay/sync_play_models.dart';
import 'package:driftfin/models/syncplay/sync_play_state.dart';

void main() {
  group('SyncPlayState defaults', () {
    test('a fresh state is disconnected, not in a group, idle', () {
      const s = SyncPlayState();
      expect(s.connection, SyncPlayConnection.disconnected);
      expect(s.inGroup, false);
      expect(s.groupId, isNull);
      expect(s.groupName, isNull);
      expect(s.members, isEmpty);
      expect(s.groupState, SyncGroupState.idle);
      expect(s.chat, isEmpty);
      expect(s.lastError, isNull);
    });

    test('isWaiting only when the group is buffering', () {
      expect(const SyncPlayState(groupState: SyncGroupState.waiting).isWaiting, true);
      expect(const SyncPlayState(groupState: SyncGroupState.playing).isWaiting, false);
      expect(const SyncPlayState().isWaiting, false);
    });
  });

  group('SyncPlayState.copyWith', () {
    const joined = SyncPlayState(
      connection: SyncPlayConnection.connected,
      inGroup: true,
      groupId: 'g1',
      groupName: 'Movie night',
      members: ['alice', 'bob'],
      groupState: SyncGroupState.playing,
      lastError: 'old error',
    );

    test('overrides only the named fields, keeps the rest', () {
      final next = joined.copyWith(groupState: SyncGroupState.paused);
      expect(next.groupState, SyncGroupState.paused);
      expect(next.groupId, 'g1');
      expect(next.members, ['alice', 'bob']);
      expect(next.connection, SyncPlayConnection.connected);
    });

    test('clearGroup wipes every group field and wins over explicit values', () {
      // clearGroup must beat an explicitly-passed groupId/groupState in the same call.
      final left = joined.copyWith(clearGroup: true, groupId: 'ignored', groupState: SyncGroupState.playing);
      expect(left.inGroup, false);
      expect(left.groupId, isNull);
      expect(left.groupName, isNull);
      expect(left.members, isEmpty);
      expect(left.groupState, SyncGroupState.idle);
      expect(left.chat, isEmpty);
      // connection + lastError are NOT group fields — they survive clearGroup.
      expect(left.connection, SyncPlayConnection.connected);
      expect(left.lastError, 'old error');
    });

    test('clearError nulls the error and wins over an explicit lastError', () {
      final next = joined.copyWith(clearError: true, lastError: 'ignored');
      expect(next.lastError, isNull);
      expect(next.inGroup, true); // unrelated fields untouched
    });
  });

  group('SyncPlayState equality', () {
    test('value-equal states compare equal (members by value)', () {
      const a = SyncPlayState(inGroup: true, groupId: 'g', members: ['x', 'y']);
      const b = SyncPlayState(inGroup: true, groupId: 'g', members: ['x', 'y']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('chat is compared by identity, not value (deliberate perf shortcut)', () {
      // Two equal-but-distinct chat lists make the states UNequal by design —
      // the notifier reuses the same list instance when chat is unchanged.
      final msg = [const SyncChatMessage(sender: 'a', text: 'hi', mine: false)];
      final s1 = const SyncPlayState().copyWith(chat: msg);
      final s2 = const SyncPlayState().copyWith(chat: List.of(msg));
      // Equal content, different list instance -> NOT equal (identity check).
      expect(s1 == s2, false);
      // Reusing the same chat instance keeps states equal and preserves the ref.
      final shared = s1.copyWith(connection: SyncPlayConnection.connected);
      expect(identical(shared.chat, s1.chat), true);
      expect(s1 == const SyncPlayState().copyWith(chat: msg), true);
    });
  });
}
