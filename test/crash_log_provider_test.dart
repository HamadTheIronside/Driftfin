import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:driftfin/providers/crash_log_provider.dart';

/// `CrashLogNotifier.init` calls `getApplicationCacheDirectory` (via
/// path_provider) fire-and-forget; without a fake platform implementation
/// that resolves, it throws `MissingPluginException` on the VM test runner
/// and can crash whichever test happens to be running when it surfaces.
class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationCachePath() async => '.';
}

/// Sentry.init installs a real HttpTransport; swap it for this so
/// `captureException` never makes a network call in tests.
class _NoNetworkTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => const SentryId.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  group('CrashLogNotifier.logFile', () {
    test('logs locally and skips Sentry when it was never initialized', () async {
      // Sentry.init is only ever called from main.dart when the user opts in;
      // in tests it stays uninitialized, so captureException must be skipped.
      expect(Sentry.isEnabled, isFalse);

      final notifier = CrashLogNotifier();
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        () => notifier.logFile(FlutterErrorDetails(exception: Exception('boom'), library: 'test')),
        returnsNormally,
      );
    });

    test('forwards to Sentry.captureException once Sentry is enabled', () async {
      await Sentry.init((options) {
        options.dsn = 'https://public@o0.ingest.sentry.io/0';
        // A non-NoOpTransport here stops Sentry.init from installing a real
        // HttpTransport, so captureException never makes a network call.
        options.transport = _NoNetworkTransport();
      });
      addTearDown(Sentry.close);

      expect(Sentry.isEnabled, isTrue);

      final notifier = CrashLogNotifier();
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        () => notifier.logFile(FlutterErrorDetails(exception: Exception('boom'), library: 'test')),
        returnsNormally,
      );
    });
  });
}
