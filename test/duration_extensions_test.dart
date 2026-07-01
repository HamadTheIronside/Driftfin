import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:driftfin/util/duration_extensions.dart';

void main() {
  group('toRuntimeTicks', () {
    test('converts milliseconds to ticks (x10000)', () {
      expect(const Duration(milliseconds: 1).toRuntimeTicks, 10000);
      expect(const Duration(seconds: 1).toRuntimeTicks, 10000000);
    });

    test('zero duration is zero ticks', () {
      expect(Duration.zero.toRuntimeTicks, 0);
    });

    test('negative duration produces negative ticks', () {
      expect(const Duration(milliseconds: -1).toRuntimeTicks, -10000);
    });
  });

  group('readAbleDuration', () {
    test('formats with hours when present', () {
      expect(const Duration(hours: 1, minutes: 2, seconds: 3).readAbleDuration, '01:02:03');
    });

    test('omits hours segment when zero', () {
      expect(const Duration(minutes: 5, seconds: 9).readAbleDuration, '05:09');
    });

    test('zero duration', () {
      expect(Duration.zero.readAbleDuration, '00:00');
    });

    test('pads single digit minutes and seconds', () {
      expect(const Duration(minutes: 1, seconds: 1).readAbleDuration, '01:01');
    });

    test('handles durations over an hour with double digit hours', () {
      expect(const Duration(hours: 12, minutes: 30, seconds: 0).readAbleDuration, '12:30:00');
    });

    test('minutes rolls over correctly after 60 minutes', () {
      expect(const Duration(minutes: 61, seconds: 5).readAbleDuration, '01:01:05');
    });
  });

  group('IntExtension fromRuntimeTicks', () {
    test('converts ticks to Duration in milliseconds', () {
      expect(10000.fromRuntimeTicks, const Duration(milliseconds: 1));
      expect(10000000.fromRuntimeTicks, const Duration(seconds: 1));
    });

    test('zero ticks gives zero duration', () {
      expect(0.fromRuntimeTicks, Duration.zero);
    });

    test('truncates remainder via integer division', () {
      expect(15000.fromRuntimeTicks, const Duration(milliseconds: 1));
    });
  });

  group('BaseItemDtoExtension runTimeDuration', () {
    test('returns null when runTimeTicks is null', () {
      const item = dto.BaseItemDto();
      expect(item.runTimeDuration, isNull);
    });

    test('converts runTimeTicks to a Duration', () {
      const item = dto.BaseItemDto(runTimeTicks: 10000000);
      expect(item.runTimeDuration, const Duration(seconds: 1));
    });

    test('zero ticks converts to zero duration', () {
      const item = dto.BaseItemDto(runTimeTicks: 0);
      expect(item.runTimeDuration, Duration.zero);
    });
  });
}
