import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  group('ClientSettingsNotifier.setEnableCrashReporting', () {
    test('is off by default', () {
      expect(container.read(clientSettingsProvider).enableCrashReporting, isFalse);
    });

    test('turns the flag on and off', () {
      final notifier = container.read(clientSettingsProvider.notifier);

      notifier.setEnableCrashReporting(true);
      expect(container.read(clientSettingsProvider).enableCrashReporting, isTrue);

      notifier.setEnableCrashReporting(false);
      expect(container.read(clientSettingsProvider).enableCrashReporting, isFalse);
    });
  });
}
