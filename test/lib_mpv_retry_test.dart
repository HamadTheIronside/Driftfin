// Exercises LibMPV.loadVideo's retry-budget-exhausted path without a live
// mpv.Player: with no player initialized (LibMPV constructed but never
// `init()`ed), every mpv-touching call is a safe no-op via optional
// chaining, so the retry timer's pure bookkeeping (arm, expire, report a
// fatal PlayerError) can be driven deterministically with a fake clock.
//
// Note: LibMPV's budget check uses real `DateTime.now()`, not the `clock`
// package, so `fakeAsync`'s elapsed time only controls *when the timer
// fires* — the budget comparison itself still runs against real wall-clock
// time. `maxRetryDuration: Duration.zero` (exceeded almost immediately) and
// a very large `maxRetryDuration` (never exceeded within a test's runtime)
// sidestep that without depending on the two clocks lining up.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/wrappers/players/lib_mpv.dart';
import 'package:driftfin/wrappers/players/playback_retry_policy.dart';
import 'package:driftfin/wrappers/players/player_states.dart';

void main() {
  group('LibMPV.loadVideo retry budget', () {
    test('clears a stale error at the start of a fresh load', () {
      final player = LibMPV(
        retryPolicy: const PlaybackRetryPolicy(retryInterval: Duration(seconds: 1), maxRetryDuration: Duration.zero),
      );
      player.lastState.update(error: const PlayerError('stale', fatal: true));

      fakeAsync((async) {
        player.loadVideo('https://example.com/video.mp4', true);
        expect(player.lastState.error, isNull);
      });
    });

    test('reports a fatal error once the retry budget is exceeded', () {
      final player = LibMPV(
        retryPolicy: const PlaybackRetryPolicy(
          retryInterval: Duration(milliseconds: 10),
          maxRetryDuration: Duration.zero,
        ),
      );

      fakeAsync((async) {
        player.loadVideo('https://example.com/video.mp4', true);
        expect(player.lastState.error, isNull);

        async.elapse(const Duration(milliseconds: 200));

        expect(player.lastState.error?.fatal, isTrue);
      });
    });

    test('only reports non-fatal retry errors while still comfortably within the retry budget', () {
      final player = LibMPV(
        retryPolicy: const PlaybackRetryPolicy(
          retryInterval: Duration(milliseconds: 10),
          maxRetryDuration: Duration(days: 1),
        ),
      );

      fakeAsync((async) {
        player.loadVideo('https://example.com/video.mp4', true);
        async.elapse(const Duration(milliseconds: 200));
        expect(player.lastState.error?.fatal ?? false, isFalse);
      });
    });
  });
}
