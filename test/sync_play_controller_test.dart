import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/syncplay/sync_play_state.dart';
import 'package:driftfin/providers/syncplay/sync_play_controller.dart';

// These tests exercise only the small slice of SyncPlayController that is safe
// to reach without wiring a live JellyfinSocket/API/player:
//
//   - The guard clauses at the top of the public, player/network-facing
//     methods (userTogglePlayPause/sendChat/sendReaction/setTyping/userSeek)
//     return immediately when `state.inGroup` is false, *before* touching
//     `ref`, the Jellyfin API, the relay HTTP client, or the player wrapper.
//     A freshly constructed controller starts with `const SyncPlayState()`
//     (inGroup: false), so calling these is safe with a bare
//     ProviderContainer and never triggers `_ensureWired()` / a real socket
//     connection or HTTP request.
//
// Everything else of substance in this file is either:
//   - private top-level ticks<->Duration helpers and the private
//     _participants/_defaultGroupName/_onMessage/_onGroupUpdate/_onCommand/
//     _applyCommand/_onGeneralCommand/_onRelayMessage/_setPresence routing,
//     all unreachable from a test without either modifying lib/ visibility
//     (out of scope here) or driving them via _ensureWired(), which opens a
//     real WebSocket with no injection seam; or
//   - already covered by test/sync_play_state_test.dart (SyncPlayState /
//     copyWith / equality), test/sync_play_models_test.dart
//     (SyncGroupState.parse, SyncGroupUpdateType.parse,
//     SyncPlayGroupUpdate.fromJson, parseSyncCommand, SyncRelayMessage), and
//     test/sync_play_relay_test.dart (postSyncPlayRelayMessage).

/// A test-local provider so we can obtain a real `Ref` for
/// `SyncPlayController`'s constructor without pulling in the app's
/// `syncPlayControllerProvider` (same shape, kept local to this test file).
final _testControllerProvider = StateNotifierProvider<SyncPlayController, SyncPlayState>(
  (ref) => SyncPlayController(ref),
);

void main() {
  late ProviderContainer container;
  late SyncPlayController controller;

  setUp(() {
    container = ProviderContainer();
    // SyncPlayController only needs a Ref; reuse the real provider's factory
    // via a throwaway container-scoped provider to obtain one without
    // depending on any app-level provider overrides.
    controller = container.read(_testControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('SyncPlayController guard clauses (never wired, not in a group)', () {
    test('userTogglePlayPause no-ops without touching the API or player', () async {
      expect(controller.state.inGroup, false);
      await expectLater(controller.userTogglePlayPause(), completes);
      // State must be untouched: no group, no error recorded.
      expect(controller.state, const SyncPlayState());
    });

    test('userSeek no-ops without touching the API', () async {
      await expectLater(controller.userSeek(const Duration(seconds: 5)), completes);
      expect(controller.state, const SyncPlayState());
    });

    test('sendChat no-ops on an empty/whitespace message even conceptually in-group', () async {
      // Not in a group, so this returns before the trimmed-empty check even
      // matters, but a non-empty message should also be rejected while not
      // in a group without throwing or mutating chat.
      await expectLater(controller.sendChat('hello'), completes);
      expect(controller.state.chat, isEmpty);
      expect(controller.state, const SyncPlayState());
    });

    test('sendChat no-ops for a whitespace-only message', () async {
      await expectLater(controller.sendChat('   '), completes);
      expect(controller.state.chat, isEmpty);
    });

    test('sendReaction no-ops without touching the API or player', () async {
      await expectLater(controller.sendReaction('👍'), completes);
      expect(controller.state.reactions, isEmpty);
      expect(controller.state, const SyncPlayState());
    });

    test('sendReaction no-ops for a whitespace-only emoji', () async {
      await expectLater(controller.sendReaction('   '), completes);
      expect(controller.state.reactions, isEmpty);
    });

    test('setTyping no-ops without touching the API or player', () async {
      await expectLater(controller.setTyping(true), completes);
      expect(controller.state, const SyncPlayState());
    });
  });

  group('SyncPlayController construction', () {
    test('starts in the default disconnected/idle state', () {
      expect(controller.state, const SyncPlayState());
      expect(controller.state.connection, SyncPlayConnection.disconnected);
      expect(controller.state.inGroup, false);
      expect(controller.pendingItemId, isNull);
    });

    test('dispose is safe to call without ever wiring the socket', () {
      // Regression guard: SyncPlayController.dispose() cancels timers/
      // subscriptions and disposes the socket/time-sync services. None of
      // those are initialized unless _ensureWired() ran, so dispose() must
      // tolerate everything being null.
      //
      // Riverpod calls the notifier's dispose() itself when the container is
      // disposed; StateNotifier.dispose() is not safe to call a second time
      // (asserts the notifier is still mounted) and JellyfinSocket.dispose()
      // does not guard against being called twice either. So this exercises
      // dispose only via container.dispose(), matching how the app actually
      // tears the controller down, instead of calling controller.dispose()
      // directly and then disposing the (shared) container again in
      // tearDown.
      expect(controller.state.inGroup, false);
      expect(container.dispose, returnsNormally);
    });
  });
}
