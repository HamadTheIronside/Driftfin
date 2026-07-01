import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/size_formatting.dart';

void main() {
  group('byteFormat', () {
    test('null returns null', () {
      int? bytes;
      expect(bytes.byteFormat, isNull);
    });

    test('zero returns "- bytes"', () {
      expect(0.byteFormat, '- bytes');
    });

    test('small values formatted as Bytes', () {
      expect(1.byteFormat, '1 Bytes');
      expect(1023.byteFormat, '1023 Bytes');
    });

    test('KB threshold formats as KB', () {
      expect(1024.byteFormat, '1.00 KB');
      expect((1024 * 1.5).round().byteFormat, '1.50 KB');
    });

    test('MB threshold formats as MB', () {
      expect((1024 * 1024).byteFormat, '1.00 MB');
    });

    test('GB threshold formats as GB', () {
      expect((1024 * 1024 * 1024).byteFormat, '1.00 GB');
    });

    test('just below a threshold uses the lower unit', () {
      expect((1024 * 1024 - 1).byteFormat, '1024.00 KB');
    });

    test('large values format with two decimal places', () {
      expect((5 * 1024 * 1024 * 1024).byteFormat, '5.00 GB');
    });

    test('negative bytes fall through to Bytes branch', () {
      expect((-5).byteFormat, '-5 Bytes');
    });
  });
}
