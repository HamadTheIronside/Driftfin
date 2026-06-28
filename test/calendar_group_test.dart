import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/calendar_provider.dart';

CalendarEntry _entry(DateTime airDate, {String series = 'Show'}) => CalendarEntry(
      airDate: airDate,
      seriesTitle: series,
      season: 1,
      episode: 1,
      episodeTitle: 'Ep',
      hasFile: false,
      item: null,
      image: null,
    );

void main() {
  group('groupCalendarByDay', () {
    test('groups entries by calendar day ignoring time', () {
      final grouped = groupCalendarByDay([
        _entry(DateTime(2026, 6, 28, 20, 0), series: 'A'),
        _entry(DateTime(2026, 6, 28, 9, 0), series: 'B'),
        _entry(DateTime(2026, 6, 29, 10, 0), series: 'C'),
      ]);
      expect(grouped.keys.length, 2);
      expect(grouped[DateTime(2026, 6, 28)]!.length, 2);
      expect(grouped[DateTime(2026, 6, 29)]!.length, 1);
    });

    test('orders entries within a day by air time', () {
      final grouped = groupCalendarByDay([
        _entry(DateTime(2026, 6, 28, 20, 0), series: 'late'),
        _entry(DateTime(2026, 6, 28, 9, 0), series: 'early'),
      ]);
      final day = grouped[DateTime(2026, 6, 28)]!;
      expect(day.first.seriesTitle, 'early');
      expect(day.last.seriesTitle, 'late');
    });

    test('empty input yields empty map', () {
      expect(groupCalendarByDay([]), isEmpty);
    });
  });

  test('CalendarEntry code label + dedupe key', () {
    final e = _entry(DateTime(2026, 6, 28), series: 'Foo');
    expect(e.codeLabel, 'S1E1');
    expect(e.dedupeKey, 'foo|1|1');
  });
}
