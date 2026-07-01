import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:driftfin/models/items/media_segments_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaSegment.inRange', () {
    final segment = MediaSegment(
      type: MediaSegmentType.intro,
      start: const Duration(seconds: 10),
      end: const Duration(seconds: 20),
    );

    test('is inclusive of both start and end boundaries', () {
      expect(segment.inRange(const Duration(seconds: 10)), isTrue);
      expect(segment.inRange(const Duration(seconds: 20)), isTrue);
    });

    test('is true strictly inside the range', () {
      expect(segment.inRange(const Duration(seconds: 15)), isTrue);
    });

    test('is false outside the range', () {
      expect(segment.inRange(const Duration(seconds: 9)), isFalse);
      expect(segment.inRange(const Duration(seconds: 21)), isFalse);
    });
  });

  group('MediaSegment.visibility', () {
    final segment = MediaSegment(
      type: MediaSegmentType.intro,
      start: const Duration(seconds: 30),
      end: const Duration(seconds: 60),
    );

    test('force always returns visible regardless of position', () {
      expect(segment.visibility(const Duration(minutes: 5), force: true), SegmentVisibility.visible);
    });

    test('hidden once more than 90s past start', () {
      final position = segment.start + const Duration(minutes: 1, seconds: 31);
      expect(segment.visibility(position), SegmentVisibility.hidden);
    });

    test('at exactly the start position is visible (difference zero < clamp)', () {
      expect(segment.visibility(segment.start), SegmentVisibility.visible);
    });

    test('within the 20%-of-length clamp window is visible', () {
      // segment length 30s, 20% = 6s, clamped to <= 1 minute -> 6s window.
      final position = segment.start + const Duration(seconds: 5);
      expect(segment.visibility(position), SegmentVisibility.visible);
    });

    test('past the clamp window but before hidden threshold is partially visible', () {
      final position = segment.start + const Duration(seconds: 10);
      expect(segment.visibility(position), SegmentVisibility.partially);
    });

    test('clamp is capped at one minute for very long segments', () {
      final longSegment = MediaSegment(
        type: MediaSegmentType.intro,
        start: Duration.zero,
        end: const Duration(minutes: 30),
      );
      // 20% of 30 minutes is 6 minutes, clamped down to 1 minute.
      expect(longSegment.visibility(const Duration(seconds: 59)), SegmentVisibility.visible);
      expect(longSegment.visibility(const Duration(minutes: 1, seconds: 1)), SegmentVisibility.partially);
    });

    test('position before start yields a negative difference, still visible', () {
      final position = segment.start - const Duration(seconds: 5);
      expect(segment.visibility(position), SegmentVisibility.visible);
    });
  });

  group('MediaSegmentsModel', () {
    final intro = MediaSegment(
      type: MediaSegmentType.intro,
      start: const Duration(seconds: 0),
      end: const Duration(seconds: 10),
    );
    final outro = MediaSegment(
      type: MediaSegmentType.outro,
      start: const Duration(minutes: 40),
      end: const Duration(minutes: 41),
    );
    final model = MediaSegmentsModel(segments: [intro, outro]);

    test('atPosition finds the segment containing the given position', () {
      expect(model.atPosition(const Duration(seconds: 5)), intro);
      expect(model.atPosition(const Duration(minutes: 40, seconds: 30)), outro);
    });

    test('atPosition returns null when no segment matches', () {
      expect(model.atPosition(const Duration(minutes: 20)), isNull);
    });

    test('intro/outro getters find by type', () {
      expect(model.intro, intro);
      expect(model.outro, outro);
    });

    test('intro/outro are null when absent', () {
      final empty = MediaSegmentsModel(segments: []);
      expect(empty.intro, isNull);
      expect(empty.outro, isNull);
    });

    test('default segments list is empty', () {
      expect(MediaSegmentsModel().segments, isEmpty);
    });
  });

  group('MediaSegmentType.fromDto', () {
    test('maps every known dto value 1:1', () {
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.unknown), MediaSegmentType.unknown);
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.commercial), MediaSegmentType.commercial);
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.preview), MediaSegmentType.preview);
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.recap), MediaSegmentType.recap);
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.outro), MediaSegmentType.outro);
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.intro), MediaSegmentType.intro);
    });

    test('garbage/generated-unknown and null both fall back to unknown', () {
      expect(MediaSegmentType.fromDto(dto.MediaSegmentType.swaggerGeneratedUnknown), MediaSegmentType.unknown);
      expect(MediaSegmentType.fromDto(null), MediaSegmentType.unknown);
    });
  });

  group('MediaSegmentExtension.toSegment', () {
    test('converts ticks (100ns units) to milliseconds via truncating division', () {
      final dtoSegment = const dto.MediaSegmentDto(
        type: dto.MediaSegmentType.intro,
        startTicks: 100000000, // 10,000,000 ticks per second -> 10s
        endTicks: 200000000, // 20s
      );
      final segment = dtoSegment.toSegment;
      expect(segment.type, MediaSegmentType.intro);
      expect(segment.start, const Duration(seconds: 10));
      expect(segment.end, const Duration(seconds: 20));
    });

    test('missing ticks default to zero', () {
      final dtoSegment = const dto.MediaSegmentDto(type: dto.MediaSegmentType.outro);
      final segment = dtoSegment.toSegment;
      expect(segment.start, Duration.zero);
      expect(segment.end, Duration.zero);
    });
  });

  group('defaultSegmentSkipValues', () {
    test('every skippable type defaults to askToSkip', () {
      for (final type in [
        MediaSegmentType.commercial,
        MediaSegmentType.preview,
        MediaSegmentType.recap,
        MediaSegmentType.outro,
        MediaSegmentType.intro,
      ]) {
        expect(defaultSegmentSkipValues[type], SegmentSkip.askToSkip);
      }
    });

    test('unknown type has no default entry', () {
      expect(defaultSegmentSkipValues.containsKey(MediaSegmentType.unknown), isFalse);
    });
  });
}
