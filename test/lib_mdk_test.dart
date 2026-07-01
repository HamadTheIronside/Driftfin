// Exercises LibMDK.updateState's pure state-mapping logic without a live
// video_player/FVP controller: with no controller loaded yet, every field
// falls back to its documented default via optional chaining.
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/wrappers/players/lib_mdk.dart';

void main() {
  group('LibMDK.updateState', () {
    test('falls back to sensible defaults, including failed=false, when there is no controller yet', () {
      final player = LibMDK();

      player.updateState();

      expect(player.lastState.playing, isFalse);
      expect(player.lastState.completed, isFalse);
      expect(player.lastState.position, Duration.zero);
      expect(player.lastState.duration, Duration.zero);
      expect(player.lastState.buffering, isTrue);
      expect(player.lastState.failed, isFalse);
    });
  });
}
