import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:driftfin/util/extensions/day_of_week_extensions.dart';

void main() {
  group('DayOfWeekLocalization', () {
    test('isUnknown is true only for swaggerGeneratedUnknown', () {
      expect(DayOfWeek.swaggerGeneratedUnknown.isUnknown, isTrue);
      expect(DayOfWeek.monday.isUnknown, isFalse);
    });

    test('isoWeekday maps days to ISO weekday numbers', () {
      expect(DayOfWeek.monday.isoWeekday, 1);
      expect(DayOfWeek.tuesday.isoWeekday, 2);
      expect(DayOfWeek.wednesday.isoWeekday, 3);
      expect(DayOfWeek.thursday.isoWeekday, 4);
      expect(DayOfWeek.friday.isoWeekday, 5);
      expect(DayOfWeek.saturday.isoWeekday, 6);
      expect(DayOfWeek.sunday.isoWeekday, 7);
    });

    test('isoWeekday defaults to 1 for unknown', () {
      expect(DayOfWeek.swaggerGeneratedUnknown.isoWeekday, 1);
    });
  });

  group('DynamicDayOfWeekLocalization', () {
    test('isUnknown is true only for swaggerGeneratedUnknown', () {
      expect(DynamicDayOfWeek.swaggerGeneratedUnknown.isUnknown, isTrue);
      expect(DynamicDayOfWeek.sunday.isUnknown, isFalse);
    });

    test('isoWeekday maps days to ISO weekday numbers', () {
      expect(DynamicDayOfWeek.monday.isoWeekday, 1);
      expect(DynamicDayOfWeek.tuesday.isoWeekday, 2);
      expect(DynamicDayOfWeek.wednesday.isoWeekday, 3);
      expect(DynamicDayOfWeek.thursday.isoWeekday, 4);
      expect(DynamicDayOfWeek.friday.isoWeekday, 5);
      expect(DynamicDayOfWeek.saturday.isoWeekday, 6);
      expect(DynamicDayOfWeek.sunday.isoWeekday, 7);
    });

    test('isoWeekday defaults to 1 for unknown', () {
      expect(DynamicDayOfWeek.swaggerGeneratedUnknown.isoWeekday, 1);
    });
  });

  // label() requires a BuildContext for localization/date formatting; the
  // pure isUnknown/isoWeekday logic above is what's unit-testable here.
}
