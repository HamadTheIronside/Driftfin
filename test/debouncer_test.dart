import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('runs action after the duration elapses', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 30));
      var called = false;
      debouncer.run(() => called = true);
      expect(called, isFalse);
      await Future.delayed(const Duration(milliseconds: 60));
      expect(called, isTrue);
    });

    test('rapid successive calls cancel the previous timer, only last one fires', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 30));
      var callCount = 0;
      int? lastValue;
      for (var i = 0; i < 5; i++) {
        debouncer.run(() {
          callCount++;
          lastValue = i;
        });
        await Future.delayed(const Duration(milliseconds: 5));
      }
      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);
      expect(lastValue, 4);
    });

    test('separate debounced calls after the delay both fire', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 20));
      var count = 0;
      debouncer.run(() => count++);
      await Future.delayed(const Duration(milliseconds: 40));
      expect(count, 1);
      debouncer.run(() => count++);
      await Future.delayed(const Duration(milliseconds: 40));
      expect(count, 2);
    });
  });
}
