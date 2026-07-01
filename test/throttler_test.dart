import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/throttler.dart';

void main() {
  group('Throttler', () {
    test('canRun is true on first call', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 50));
      expect(throttler.canRun(), isTrue);
    });

    test('canRun is false immediately after a successful run', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 200));
      expect(throttler.canRun(), isTrue);
      expect(throttler.canRun(), isFalse);
    });

    test('canRun becomes true again after duration elapses', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 30));
      expect(throttler.canRun(), isTrue);
      expect(throttler.canRun(), isFalse);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(throttler.canRun(), isTrue);
    });

    test('run executes action only when not throttled', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 30));
      var count = 0;
      throttler.run(() => count++);
      throttler.run(() => count++);
      expect(count, 1);
      await Future.delayed(const Duration(milliseconds: 50));
      throttler.run(() => count++);
      expect(count, 2);
    });
  });
}
