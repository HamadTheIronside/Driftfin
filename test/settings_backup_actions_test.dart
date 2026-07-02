import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/account_model.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/providers/user_provider.dart';
import 'package:driftfin/screens/settings/settings_list_tile.dart';
import 'package:driftfin/screens/settings/widgets/settings_backup_actions.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout_model.dart';
import 'package:driftfin/screens/home_screen.dart';
import 'package:driftfin/util/poster_defaults.dart';

const _adaptiveModel = AdaptiveLayoutModel(
  viewSize: ViewSize.phone,
  layoutMode: LayoutMode.single,
  inputDevice: InputDevice.touch,
  platform: TargetPlatform.android,
  isDesktop: false,
  posterDefaults: PosterDefaults(size: 100, ratio: 0.66),
  controller: <HomeTabs, ScrollController>{},
  sideBarWidth: 0,
  topBarHeight: 0,
);

/// Returns null from the picker so `_export`/`_import` take their "user
/// cancelled" early-return paths without needing a real platform plugin.
class _FakeFilePicker extends FilePicker with MockPlatformInterfaceMixin {
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      null;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      null;
}

class _FakeUser extends User {
  _FakeUser(this._initial);
  final AccountModel? _initial;

  @override
  AccountModel? build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // No real platform plugin is registered under `flutter test`, so install a
    // fake for the whole file (each test file runs in its own isolate).
    FilePicker.platform = _FakeFilePicker();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userProvider.overrideWith(() => _FakeUser(null)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdaptiveLayout(
            data: _adaptiveModel,
            child: Scaffold(body: SettingsBackupActions()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(SettingsBackupActions)));
  }

  testWidgets('renders export, import and reset tiles', (tester) async {
    await pump(tester);
    expect(find.text(l10n.settingsExportSettingsTitle), findsOneWidget);
    expect(find.text(l10n.settingsImportSettingsTitle), findsOneWidget);
    expect(find.text(l10n.clearAllSettings), findsOneWidget);
  });

  testWidgets('export and import take the cancelled path without throwing', (tester) async {
    await pump(tester);

    final tiles = tester.widgetList<SettingsListTile>(find.byType(SettingsListTile)).toList();
    final exportTile = tiles.firstWhere((t) => (t.label as Text).data == l10n.settingsExportSettingsTitle);
    final importTile = tiles.firstWhere((t) => (t.label as Text).data == l10n.settingsImportSettingsTitle);

    await exportTile.onTap!();
    await tester.pumpAndSettle();
    await importTile.onTap!();
    await tester.pumpAndSettle();

    // No exception => the FilePicker-returns-null early returns were taken.
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset shows a confirmation dialog that can be cancelled', (tester) async {
    await pump(tester);

    final tiles = tester.widgetList<SettingsListTile>(find.byType(SettingsListTile)).toList();
    final resetTile = tiles.firstWhere((t) => (t.label as Text).data == l10n.clearAllSettings);

    resetTile.onTap!();
    await tester.pumpAndSettle();

    expect(find.text(l10n.clearAllSettingsQuestion), findsOneWidget);
    expect(find.text(l10n.unableToReverseAction), findsOneWidget);

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.clearAllSettingsQuestion), findsNothing);
  });
}
