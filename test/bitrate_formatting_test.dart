import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/bitrate_formatting.dart';

void main() {
  group('audioBitrateFormat', () {
    test('null returns null', () {
      int? bitrate;
      expect(bitrate.audioBitrateFormat, isNull);
    });

    test('converts bits to rounded kbps', () {
      expect(128000.audioBitrateFormat, '128 kbps');
    });

    test('rounds down when remainder is under half', () {
      expect(128499.audioBitrateFormat, '128 kbps');
    });

    test('rounds up when remainder is half or more', () {
      expect(128500.audioBitrateFormat, '129 kbps');
    });

    test('zero bitrate formats as 0 kbps', () {
      expect(0.audioBitrateFormat, '0 kbps');
    });
  });

  group('videoBitrateFormat', () {
    test('null returns null', () {
      int? bitrate;
      expect(bitrate.videoBitrateFormat, isNull);
    });

    test('below high bitrate cutoff formats as rounded kbps', () {
      expect(5000000.videoBitrateFormat, '5000 kbps');
    });

    test('at or above cutoff formats as Mbps with one decimal', () {
      expect(10000000.videoBitrateFormat, '10.0 Mbps');
      expect(15000000.videoBitrateFormat, '15.0 Mbps');
    });

    test('just below cutoff uses kbps', () {
      expect(9999999.videoBitrateFormat, '10000 kbps');
    });

    test('zero bitrate formats as 0 kbps', () {
      expect(0.videoBitrateFormat, '0 kbps');
    });

    test('large bitrate formats with decimal precision', () {
      expect(123456789.videoBitrateFormat, '123.5 Mbps');
    });
  });
}
