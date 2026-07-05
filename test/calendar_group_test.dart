import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:driftfin/models/items/episode_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/calendar_provider.dart';

final _refCaptureProvider = Provider<Ref>((ref) => ref);

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
  group('calendarEpisodeImage', () {
    late ProviderContainer container;
    late Ref ref;

    setUp(() {
      container = ProviderContainer(
        overrides: [serverUrlProvider.overrideWith((ref) => 'http://server')],
      );
      ref = container.read(_refCaptureProvider);
    });

    tearDown(() => container.dispose());

    EpisodeModel episode(dto.BaseItemDto item) => EpisodeModel.fromBaseDto(item, ref);

    test("prefers the episode's own primary still when it has one", () {
      final image = calendarEpisodeImage(
        episode(const dto.BaseItemDto(
          id: 'ep1',
          imageTags: {'Primary': 'ptag'},
          seriesId: 's1',
          seriesPrimaryImageTag: 'stag',
        )),
        ref,
      );
      expect(image?.path, contains('/Items/ep1/Images/Primary'));
    });

    test('falls back to the series poster when the episode has no still', () {
      final image = calendarEpisodeImage(
        episode(const dto.BaseItemDto(id: 'ep1', seriesId: 's1', seriesPrimaryImageTag: 'stag')),
        ref,
      );
      expect(image?.path, contains('/Items/s1/Images/Primary'));
    });

    test('builds the series poster directly when seriesPrimaryImageTag is absent', () {
      final image = calendarEpisodeImage(
        episode(const dto.BaseItemDto(id: 'ep1', seriesId: 's1')),
        ref,
      );
      expect(image, isNotNull);
      expect(image?.path, contains('/Items/s1/Images/Primary'));
    });

    test('null when there is no own image and no series/parent to fall back to', () {
      final image = calendarEpisodeImage(
        episode(const dto.BaseItemDto(id: 'ep1')),
        ref,
      );
      expect(image, isNull);
    });
  });

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
