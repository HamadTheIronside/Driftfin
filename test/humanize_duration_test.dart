import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/humanize_duration.dart';

void main() {
  group('humanize', () {
    test('null duration returns null', () {
      Duration? duration;
      expect(duration.humanize, isNull);
    });

    test('zero duration returns null (empty result)', () {
      expect(Duration.zero.humanize, isNull);
    });

    test('hours and minutes both included', () {
      expect(const Duration(hours: 1, minutes: 30).humanize, '1h 30m');
    });

    test('minutes only when under an hour', () {
      expect(const Duration(minutes: 45).humanize, '45m');
    });

    test('seconds shown only when under 10 minutes', () {
      // Minute/second segments are zero-padded to 3 chars (e.g. "5m" -> "05m").
      expect(const Duration(minutes: 5, seconds: 30).humanize, '05m 30s');
    });

    test('seconds omitted at or above 10 minutes', () {
      expect(const Duration(minutes: 10, seconds: 30).humanize, '10m');
    });

    test('seconds only when under a minute', () {
      expect(const Duration(seconds: 45).humanize, '45s');
    });

    test('hours with no remaining minutes omits minutes', () {
      expect(const Duration(hours: 2).humanize, '2h');
    });

    test('hours suppress seconds since minutes >= 10 check depends on inMinutes', () {
      // inMinutes for 1h is 60, so seconds are omitted regardless of hours.
      expect(const Duration(hours: 1, seconds: 5).humanize, '1h');
    });
  });

  group('humanizeSmall', () {
    test('null duration returns null', () {
      Duration? duration;
      expect(duration.humanizeSmall, isNull);
    });

    test('formats hours minutes and no seconds when hours present', () {
      expect(const Duration(hours: 1, minutes: 5, seconds: 30).humanizeSmall, '1:05');
    });

    test('formats minutes and seconds when no hours', () {
      expect(const Duration(minutes: 5, seconds: 9).humanizeSmall, '05:09');
    });

    test('zero duration formats as 00:00', () {
      expect(Duration.zero.humanizeSmall, '00:00');
    });

    test('pads minutes and seconds to two digits', () {
      expect(const Duration(minutes: 1, seconds: 1).humanizeSmall, '01:01');
    });
  });

  group('simpleTime', () {
    test('formats duration and pads to at least 8 characters', () {
      expect(const Duration(hours: 1, minutes: 2, seconds: 3).simpleTime, '1:02:03'.padLeft(8, '0'));
    });

    test('zero duration formatted with padding', () {
      expect(Duration.zero.simpleTime, '00:00:00');
    });

    test('drops fractional microseconds portion', () {
      final result = const Duration(hours: 1, minutes: 1, seconds: 1, milliseconds: 500).simpleTime;
      expect(result.contains('.'), isFalse);
    });
  });
}
