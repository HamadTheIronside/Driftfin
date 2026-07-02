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

    test('reactions are compared by identity too, same rationale as chat', () {
      final reaction = [SyncReactionEvent(sender: 'a', emoji: '👍', at: DateTime(2024), mine: false)];
      final s1 = const SyncPlayState().copyWith(reactions: reaction);
      final s2 = const SyncPlayState().copyWith(reactions: List.of(reaction));
      expect(s1 == s2, false);
      expect(s1 == const SyncPlayState().copyWith(reactions: reaction), true);
    });

    test('presence is compared by value (a small, low-churn map)', () {
      const a = SyncPlayState(presence: {'alice': SyncPresenceInfo(typing: true)});
      const b = SyncPlayState(presence: {'alice': SyncPresenceInfo(typing: true)});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      const c = SyncPlayState(presence: {'alice': SyncPresenceInfo(typing: false)});
      expect(a == c, false);
    });
  });

  group('SyncPresenceInfo', () {
    test('defaults to neither typing nor buffering', () {
      const info = SyncPresenceInfo();
      expect(info.typing, false);
      expect(info.buffering, false);
    });

    test('copyWith overrides only the named field', () {
      const info = SyncPresenceInfo(typing: true, buffering: false);
      final next = info.copyWith(buffering: true);
      expect(next.typing, true);
      expect(next.buffering, true);
    });

    test('value equality', () {
      expect(const SyncPresenceInfo(typing: true), const SyncPresenceInfo(typing: true));
      expect(const SyncPresenceInfo(typing: true), isNot(const SyncPresenceInfo(typing: false)));
    });
  });

  group('SyncPlayState.typingMembers / bufferingMembers', () {
    test('derives the member lists from presence flags', () {
      const s = SyncPlayState(presence: {
        'alice': SyncPresenceInfo(typing: true),
        'bob': SyncPresenceInfo(buffering: true),
        'carol': SyncPresenceInfo(typing: true, buffering: true),
        'dave': SyncPresenceInfo(),
      });
      expect(s.typingMembers, unorderedEquals(['alice', 'carol']));
      expect(s.bufferingMembers, unorderedEquals(['bob', 'carol']));
    });

    test('empty presence yields empty lists', () {
      expect(const SyncPlayState().typingMembers, isEmpty);
      expect(const SyncPlayState().bufferingMembers, isEmpty);
    });
  });

  group('clearGroup also resets reactions and presence', () {
    test('wipes reactions/presence along with the rest of the group fields', () {
      final joined = SyncPlayState(
        inGroup: true,
        groupId: 'g1',
        reactions: [SyncReactionEvent(sender: 'a', emoji: '🎉', at: DateTime(2024), mine: true)],
        presence: const {'alice': SyncPresenceInfo(typing: true)},
      );
      final left = joined.copyWith(clearGroup: true);
      expect(left.reactions, isEmpty);
      expect(left.presence, isEmpty);
    });
  });
}
