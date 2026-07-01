import 'dart:math' show Random;

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
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

List<String> _ids(List<ItemBaseModel> items) => items.map((e) => e.id).toList();

void main() {
  final a = _item('a');
  final b = _item('b');
  final c = _item('c');
  final base = [a, b, c];

  group('fromQueue', () {
    test('seeds the main anchor and preserves order when not shuffled', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'b');
      expect(_ids(state.queue), ['a', 'b', 'c']);
      expect(state.mainQueueCurrentId, 'b');
      expect(state.shuffleEnabled, isFalse);
    });

    test('empty input yields an empty queue', () {
      final state = PlaybackQueueState.fromQueue(const [], initialItemId: 'x');
      expect(state.queue, isEmpty);
      expect(state.nextItem('x'), isNull);
    });
  });

  group('previousItem', () {
    test('returns the prior queue item', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a');
      expect(state.previousItem('b')?.id, 'a');
    });

    test('returns null at the first item without repeat-all', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a');
      expect(state.previousItem('a'), isNull);
    });

    test('wraps to the last item with repeat-all', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a', repeatMode: AudioRepeatMode.all);
      expect(state.previousItem('a')?.id, 'c');
    });

    test('returns null while playing from Next Up', () {
      final state = PlaybackQueueState(queue: base, originalQueue: base, playingFromNextUp: true);
      expect(state.previousItem('b'), isNull);
    });
  });

  group('addToNextUp / clearNextUp', () {
    test('appends to the Next Up list and short-circuits empty input', () {
      final x = _item('x');
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').addToNextUp([x]);
      expect(_ids(state.nextUpQueue), ['x']);
      expect(identical(state.addToNextUp(const []), state), isTrue);
    });

    test('clearNextUp empties the list', () {
      final x = _item('x');
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').addToNextUp([x]).clearNextUp();
      expect(state.nextUpQueue, isEmpty);
    });
  });

  group('appendToQueue', () {
    test('appends new items and drops duplicates by id', () {
      final d = _item('d');
      final dupB = _item('b');
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').appendToQueue([d, dupB]);
      expect(_ids(state.queue), ['a', 'b', 'c', 'd'], reason: 'duplicate "b" must not be appended');
    });

    test('returns the same state when nothing new is added', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a');
      expect(identical(state.appendToQueue([a, b]), state), isTrue);
    });
  });

  group('removeItemById', () {
    test('removes from the main queue', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').removeItemById('b');
      expect(_ids(state.queue), ['a', 'c']);
    });

    test('removes from Next Up before the main queue', () {
      final dupA = _item('a');
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').addToNextUp([dupA]).removeItemById('a');
      expect(state.nextUpQueue, isEmpty, reason: 'the Next Up copy is removed first');
      expect(_ids(state.queue), ['a', 'b', 'c'], reason: 'the main-queue item is untouched');
    });

    test('is a no-op for an unknown id', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a');
      expect(_ids(state.removeItemById('zzz').queue), ['a', 'b', 'c']);
    });
  });

  group('removeSectionItem', () {
    test('ignores an out-of-range Next Up index', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a');
      expect(identical(state.removeSectionItem(AudioQueueSection.nextUp, 9), state), isTrue);
    });

    test('removes the indexed main-queue item for the existing section', () {
      final state =
          PlaybackQueueState.fromQueue(base, initialItemId: 'a').removeSectionItem(AudioQueueSection.existing, 1);
      expect(_ids(state.queue), ['a', 'c']);
    });
  });

  group('withShuffleEnabled', () {
    test('keeps the current item first and preserves the set when enabling', () {
      final big = [a, b, c, _item('d'), _item('e')];
      final state = PlaybackQueueState.fromQueue(big, initialItemId: 'c')
          .withShuffleEnabled(true, currentId: 'c', random: Random(42));
      expect(state.queue.first.id, 'c');
      expect(state.queue.map((e) => e.id).toSet(), {'a', 'b', 'c', 'd', 'e'});
      expect(state.originalQueue.map((e) => e.id).toList(), ['a', 'b', 'c', 'd', 'e']);
    });

    test('restores the original order when disabling', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a')
          .withShuffleEnabled(true, currentId: 'a', random: Random(1))
          .withShuffleEnabled(false);
      expect(_ids(state.queue), ['a', 'b', 'c']);
      expect(state.shuffleEnabled, isFalse);
    });
  });

  group('jumpToItem', () {
    test('jumping to a Next Up item starts playing from Next Up', () {
      final x = _item('x');
      final y = _item('y');
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').addToNextUp([x, y]).jumpToItem('y');
      expect(state.playingFromNextUp, isTrue);
      expect(_ids(state.nextUpQueue), ['y']);
    });

    test('jumping to a main-queue item updates the anchor', () {
      final state = PlaybackQueueState.fromQueue(base, initialItemId: 'a').jumpToItem('c');
      expect(state.playingFromNextUp, isFalse);
      expect(state.mainQueueCurrentId, 'c');
      expect(state.nextItem('c'), isNull, reason: 'c is last');
    });
  });
}
