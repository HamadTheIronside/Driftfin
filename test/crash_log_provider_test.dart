import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:driftfin/providers/crash_log_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashLogNotifier.logFile', () {
    test('logs locally and skips Sentry when it was never initialized', () {
      // Sentry.init is only ever called from main.dart when the user opts in;
      // in tests it stays uninitialized, so captureException must be skipped.
      expect(Sentry.isEnabled, isFalse);

      final notifier = CrashLogNotifier();
      addTearDown(notifier.dispose);

      expect(
        () => notifier.logFile(FlutterErrorDetails(exception: Exception('boom'), library: 'test')),
        returnsNormally,
      );
    });
  });
}
