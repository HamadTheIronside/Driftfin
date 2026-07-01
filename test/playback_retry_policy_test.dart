import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/wrappers/players/playback_retry_policy.dart';

void main() {
  group('PlaybackRetryPolicy', () {
    test('default retryInterval and maxRetryDuration', () {
      const policy = PlaybackRetryPolicy();
      expect(policy.retryInterval, const Duration(seconds: 5));
      expect(policy.maxRetryDuration, const Duration(minutes: 1));
    });

    test('hasExceededBudget is false before the max duration has elapsed', () {
      const policy = PlaybackRetryPolicy(maxRetryDuration: Duration(seconds: 30));
      final firstAttempt = DateTime(2026, 1, 1, 12, 0, 0);

      expect(
        policy.hasExceededBudget(firstAttempt: firstAttempt, now: firstAttempt.add(const Duration(seconds: 10))),
        isFalse,
      );
      expect(
        policy.hasExceededBudget(firstAttempt: firstAttempt, now: firstAttempt.add(const Duration(seconds: 30))),
        isFalse,
      );
    });

    test('hasExceededBudget is true once the max duration has elapsed', () {
      const policy = PlaybackRetryPolicy(maxRetryDuration: Duration(seconds: 30));
      final firstAttempt = DateTime(2026, 1, 1, 12, 0, 0);

      expect(
        policy.hasExceededBudget(firstAttempt: firstAttempt, now: firstAttempt.add(const Duration(seconds: 31))),
        isTrue,
      );
      expect(
        policy.hasExceededBudget(firstAttempt: firstAttempt, now: firstAttempt.add(const Duration(minutes: 5))),
        isTrue,
      );
    });

    test('custom retryInterval is honored', () {
      const policy = PlaybackRetryPolicy(retryInterval: Duration(seconds: 2));
      expect(policy.retryInterval, const Duration(seconds: 2));
    });
  });
}
