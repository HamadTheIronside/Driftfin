import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/update_checker.dart';

void main() {
  group('compareVersions', () {
    test('orders normal semver', () {
      expect(compareVersions('0.10.5', '0.10.4'), greaterThan(0));
      expect(compareVersions('0.10.4', '0.10.5'), lessThan(0));
      expect(compareVersions('0.10.4', '0.10.4'), 0);
      expect(compareVersions('1.0.0', '0.99.99'), greaterThan(0));
    });

    test('nightly tag counts as newer than the older base (the bug)', () {
      // Previously "5-nightly" parsed to 0, making this compare as older.
      expect(compareVersions('0.10.5-nightly.20260628.2', '0.10.4'), greaterThan(0));
    });

    test('nightly orders after its own base version', () {
      expect(compareVersions('0.10.5-nightly.20260628.2', '0.10.5'), greaterThan(0));
    });

    test('nightlies order by date then counter', () {
      expect(
        compareVersions('0.10.5-nightly.20260628.2', '0.10.5-nightly.20260628.1'),
        greaterThan(0),
      );
      expect(
        compareVersions('0.10.5-nightly.20260629.1', '0.10.5-nightly.20260628.9'),
        greaterThan(0),
      );
    });

    test('a stable release is not newer than itself-as-base from a nightly', () {
      // 0.10.4 should be older than any 0.10.5 nightly.
      expect(compareVersions('0.10.4', '0.10.5-nightly.20260628.1'), lessThan(0));
    });
  });
}
