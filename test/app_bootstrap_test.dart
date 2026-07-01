import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/bootstrap/app_bootstrap.dart';
import 'package:driftfin/util/fladder_config.dart';

void main() {
  tearDown(() => FladderConfig.sentryDsn = null);

  group('resolvedSentryDsn', () {
    // `flutter test` always runs on the VM (kIsWeb == false), so the
    // config.json-backed DSN is never preferred here — this pins that guard:
    // FladderConfig.sentryDsn must never leak into non-Web builds.
    test('ignores FladderConfig.sentryDsn outside Web and falls back to the compile-time value', () {
      FladderConfig.sentryDsn = 'https://runtime-only-dsn';

      expect(resolvedSentryDsn, sentryDsn);
      expect(resolvedSentryDsn, isNot('https://runtime-only-dsn'));
    });

    test('compile-time sentryDsn is empty unless --dart-define=SENTRY_DSN is passed', () {
      // Documents the default: without a build-time DSN, resolvedSentryDsn is
      // empty on every non-Web platform regardless of any other setting.
      expect(sentryDsn, isEmpty);
      expect(resolvedSentryDsn, isEmpty);
    });
  });
}
