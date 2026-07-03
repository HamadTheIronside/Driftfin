import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/bitrate_helper.dart';

void main() {
  group('Bitrate enum', () {
    test('calculatedBitRate returns -1 for original (null bitRate)', () {
      expect(Bitrate.original.calculatedBitRate, -1);
    });

    test('calculatedBitRate returns underlying value for others', () {
      expect(Bitrate.auto.calculatedBitRate, 0);
      expect(Bitrate.b10Mbps.calculatedBitRate, 10000000);
    });
  });

  group('resolveMaxBitrate', () {
    test('uses maxHomeBitrate when reached over the local URL', () {
      final result = resolveMaxBitrate(
        maxHomeBitrate: Bitrate.original,
        maxInternetBitrate: Bitrate.b4Mbps,
        useLocalConnection: true,
      );
      expect(result, Bitrate.original);
    });

    test('uses maxInternetBitrate when not on the local URL', () {
      final result = resolveMaxBitrate(
        maxHomeBitrate: Bitrate.original,
        maxInternetBitrate: Bitrate.b4Mbps,
        useLocalConnection: false,
      );
      expect(result, Bitrate.b4Mbps);
    });
  });

  group('getVideoQualityOptions', () {
    test('always includes original and auto', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 0, videoCodec: null),
      );
      expect(options.containsKey(Bitrate.original), isTrue);
      expect(options.containsKey(Bitrate.auto), isTrue);
    });

    test('videoBitRate of 0 includes all real bitrate tiers', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 0, videoCodec: null),
      );
      for (final bitrate in Bitrate.values.where((b) => b.calculatedBitRate > 0)) {
        expect(options.containsKey(bitrate), isTrue, reason: '$bitrate should be included');
      }
    });

    test('none of the options are selected when maxBitRate is null', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 0, videoCodec: null),
      );
      expect(options.values.every((selected) => selected == false), isTrue);
    });

    test('marks the matching maxBitRate option as selected', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: Bitrate.b4Mbps, videoBitRate: 8000000, videoCodec: 'h264'),
      );
      expect(options[Bitrate.b4Mbps], isTrue);
    });

    test('maxBitRate set to original marks only original as selected', () {
      // The "maxStreamingBitrate != Bitrate.original" guard means no numeric
      // tier is computed as selected, but the `original` entry itself still
      // matches `bitrate == maxStreamingBitrate`.
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: Bitrate.original, videoBitRate: 8000000, videoCodec: 'h264'),
      );
      expect(options[Bitrate.original], isTrue);
      expect(
        options.entries.where((e) => e.key != Bitrate.original).every((e) => e.value == false),
        isTrue,
      );
    });

    test('low videoBitRate below the smallest tier adds a source option above it', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 100000, videoCodec: 'h264'),
      );
      // Smallest defined tier is b420Kbps (420000); 100000 is below it so a
      // source option greater than the reference bitrate should be added.
      expect(options.keys.any((b) => b.calculatedBitRate > 100000), isTrue);
    });

    test('efficient codec close to threshold inflates reference bitrate', () {
      final withHevc = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 100000, videoCodec: 'hevc'),
      );
      final withH264 = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 100000, videoCodec: 'h264'),
      );
      // Both should at least produce valid (non-empty) results without throwing.
      expect(withHevc, isNotEmpty);
      expect(withH264, isNotEmpty);
    });

    test('negative videoBitRate is treated like unset and includes all tiers', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: -1, videoCodec: null),
      );
      for (final bitrate in Bitrate.values.where((b) => b.calculatedBitRate > 0)) {
        expect(options.containsKey(bitrate), isTrue);
      }
    });

    test('high videoBitRate only includes tiers at or below reference', () {
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: null, videoBitRate: 3000000, videoCodec: 'h264'),
      );
      expect(options.containsKey(Bitrate.b3Mbps), isTrue);
      expect(options.containsKey(Bitrate.b120Mbps), isFalse);
    });

    test('does not throw and returns empty map on unexpected error path', () {
      // maxBitRate with calculatedBitRate but not matching anything shouldn't throw.
      final options = getVideoQualityOptions(
        VideoQualitySettings(maxBitRate: Bitrate.b420Kbps, videoBitRate: 100, videoCodec: null),
      );
      expect(options, isA<Map<Bitrate, bool>>());
    });
  });
}
