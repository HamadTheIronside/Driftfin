import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/media_playback_model.dart';
import 'package:driftfin/models/playback/playback_queue_state.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('PlaybackQueueState.nextItem', () {
    final e1 = _item('e1');
    final e2 = _item('e2');
    final e3 = _item('e3');
    final episodes = [e1, e2, e3];

    test('advances e1 -> e2 -> e3 across the loadNewVideo transition chain', () {
      var state = PlaybackQueueState.fromQueue(episodes, initialItemId: e1.id);
      var current = e1;

      final next1 = state.nextItem(current.id);
      expect(next1?.id, e2.id);
      state = state.advanceFromCurrentTo(current.id, next1!.id);
      current = next1;

      final next2 = state.nextItem(current.id);
      expect(next2?.id, e3.id, reason: 'after watching e2, next must be e3 — not the current episode');
      state = state.advanceFromCurrentTo(current.id, next2!.id);
      current = next2;

      expect(state.nextItem(current.id), isNull, reason: 'e3 is the last episode');
    });

    test('next is relative to the actually-playing item even if the anchor lags behind', () {
      // Reproduces the reported bug: the main-queue anchor still points at e1
      // while playback has already moved to e2. "Next" must be e3, not e2.
      final state = PlaybackQueueState.fromQueue(episodes, initialItemId: e1.id);
      expect(state.mainQueueCurrentId, e1.id);

      expect(
        state.nextItem(e2.id)?.id,
        e3.id,
        reason: 'next must follow the live playing id (e2 -> e3), not the stale anchor (e1 -> e2)',
      );
    });

    test('repeat-all wraps from the last episode back to the first', () {
      final state = PlaybackQueueState.fromQueue(
        episodes,
        initialItemId: e3.id,
        repeatMode: AudioRepeatMode.all,
      );
      expect(state.nextItem(e3.id)?.id, e1.id);
    });

    test('reorderSection maps display indices onto the full queue when playing from Next Up', () {
      final n1 = _item('n1'); // currently playing from Next Up (hidden in display)
      final n2 = _item('n2'); // display index 0
      final n3 = _item('n3'); // display index 1
      final state = PlaybackQueueState(
        queue: episodes,
        originalQueue: episodes,
        nextUpQueue: [n1, n2, n3],
        mainQueueCurrentId: e1.id,
        playingFromNextUp: true,
      );

      // User drags display item 0 (n2) below display item 1 (n3).
      final reordered = state.reorderSection(AudioQueueSection.nextUp, 0, 2);

      // n1 (currently playing) must stay put; only the displayed items swap.
      expect(reordered.nextUpQueue.map((e) => e.id).toList(), ['n1', 'n3', 'n2']);
    });

    test('falls back to the main anchor when playing an item outside the main queue', () {
      // Simulates playing from the Next Up list: the current id is not in the
      // main queue, so next resumes the main queue after the tracked anchor.
      const playingFromNextUpId = 'nextUpItem';
      final state = PlaybackQueueState(
        queue: episodes,
        originalQueue: episodes,
        mainQueueCurrentId: e1.id,
        playingFromNextUp: true,
      );
      expect(state.nextItem(playingFromNextUpId)?.id, e2.id);
    });
  });
}
