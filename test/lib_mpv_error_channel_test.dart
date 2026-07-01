// Covers the error-channel wiring added to LibMPV's retry loop (issue #42
// Phase 0): a load failure must surface a PlayerError instead of the retry
// loop silently swallowing it. `_player` stays null throughout (no native
// libmpv available in the test sandbox), which is fine here - the retry
// timer and its error reporting run independently of whether the underlying
// mpv.Player exists yet.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/wrappers/players/lib_mpv.dart';
import 'package:driftfin/wrappers/players/player_states.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibMPV retry loop error reporting', () {
    test('reports a non-fatal PlayerError when the load retry timer fires', () {
      fakeAsync((async) {
        final player = LibMPV();

        player.loadVideo('https://example.com/video.mp4', true);
        expect(player.lastState.error, isNull);

        // The retry timer fires after `_currentRetryDuration` (5s) plus the
        // internal 150ms grace delay before deciding whether to retry.
        async.elapse(const Duration(seconds: 6));

        expect(player.lastState.error, isNotNull);
        expect(player.lastState.error, const PlayerError('Failed to load video, retrying', fatal: false));
      });
    });

    test('clearError resets a previously reported error on the live player', () {
      final player = LibMPV();
      player.setState(player.lastState.update(error: const PlayerError('boom')));
      expect(player.lastState.error, isNotNull);

      player.setState(player.lastState.clearError());

      expect(player.lastState.error, isNull);
    });
  });
}
