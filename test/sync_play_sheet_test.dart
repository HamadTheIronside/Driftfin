// Widget-level coverage for the Watch Together sheet's issue #5 additions:
// quick emoji reactions, the recent-reactions strip, and the typing/buffering
// presence lines. The controller is faked so no real socket/API/player is
// ever touched — see SyncPlayController's own test file for why the real
// class is otherwise hard to drive from a widget test.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/syncplay/sync_play_state.dart';
import 'package:driftfin/providers/syncplay/sync_play_controller.dart';
import 'package:driftfin/screens/video_player/components/sync_play_sheet.dart';

class _FakeSyncPlayController extends SyncPlayController {
  _FakeSyncPlayController(super.ref);

  int reactionSentCount = 0;
  String? lastReactionEmoji;
  bool? lastTyping;
  final List<String> chatSentTexts = [];

  void emit(SyncPlayState next) => state = next;

  @override
  Future<void> sendReaction(String emoji) async {
    reactionSentCount++;
    lastReactionEmoji = emoji;
  }

  @override
  Future<void> setTyping(bool typing) async {
    lastTyping = typing;
  }

  @override
  Future<void> sendChat(String text) async {
    chatSentTexts.add(text);
  }

  @override
  Future<void> leaveGroup() async {}

  @override
  Future<List<GroupInfoDto>> listGroups() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_FakeSyncPlayController> pumpSheet(WidgetTester tester, {required SyncPlayState state}) async {
    final container = ProviderContainer(
      overrides: [
        syncPlayControllerProvider.overrideWith((ref) => _FakeSyncPlayController(ref)),
      ],
    );
    addTearDown(container.dispose);

    final fake = container.read(syncPlayControllerProvider.notifier) as _FakeSyncPlayController;
    fake.emit(state);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SyncPlaySheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  const inGroup = SyncPlayState(inGroup: true, groupId: 'g1', groupName: 'Movie night', members: ['Alice', 'Bob']);

  group('quick reactions', () {
    testWidgets('renders every quick-reaction emoji and tapping one sends it', (tester) async {
      final fake = await pumpSheet(tester, state: inGroup);

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);

      await tester.tap(find.text('👍'));
      await tester.pump();

      expect(fake.reactionSentCount, 1);
      expect(fake.lastReactionEmoji, '👍');
    });

    testWidgets('recent reactions are rendered in addition to the quick-pick row', (tester) async {
      final withReaction = inGroup.copyWith(reactions: [
        SyncReactionEvent(sender: 'Bob', emoji: '😮', at: DateTime.fromMillisecondsSinceEpoch(0), mine: false),
      ]);
      await pumpSheet(tester, state: withReaction);

      // 😮 is both a quick-pick button and the lone recent reaction: expect 2.
      expect(find.text('😮'), findsNWidgets(2));
    });

    testWidgets('no recent-reactions strip when there are none yet', (tester) async {
      await pumpSheet(tester, state: inGroup);
      // Every quick-reaction emoji appears exactly once (no recent duplicate).
      for (final emoji in ['👍', '❤️', '😂', '😮', '👏', '🎉']) {
        expect(find.text(emoji), findsOneWidget);
      }
    });
  });

  group('typing presence', () {
    testWidgets('shows nobody typing by default', (tester) async {
      await pumpSheet(tester, state: inGroup);
      expect(find.textContaining('typing'), findsNothing);
    });

    testWidgets('shows a member as typing from relayed presence', (tester) async {
      final typing = inGroup.copyWith(presence: {'Alice': const SyncPresenceInfo(typing: true)});
      await pumpSheet(tester, state: typing);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.textContaining('typing'), findsOneWidget);
    });

    testWidgets('clearing the chat text back to empty reports typing stopped', (tester) async {
      final fake = await pumpSheet(tester, state: inGroup);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(fake.lastTyping, true);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(fake.lastTyping, false);
    });

    testWidgets('entering chat text reports typing to the controller', (tester) async {
      final fake = await pumpSheet(tester, state: inGroup);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(fake.lastTyping, true);
    });

    testWidgets('submitting chat clears typing and sends the message', (tester) async {
      final fake = await pumpSheet(tester, state: inGroup);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(fake.lastTyping, true);

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(fake.lastTyping, false);
      expect(fake.chatSentTexts, ['hello']);
    });
  });

  group('buffering presence', () {
    testWidgets('shows nobody buffering by default', (tester) async {
      await pumpSheet(tester, state: inGroup);
      expect(find.textContaining('buffering'), findsNothing);
    });

    testWidgets('shows a member as buffering from relayed presence', (tester) async {
      final buffering = inGroup.copyWith(presence: {'Bob': const SyncPresenceInfo(buffering: true)});
      await pumpSheet(tester, state: buffering);
      expect(find.textContaining('buffering'), findsOneWidget);
    });
  });
}
