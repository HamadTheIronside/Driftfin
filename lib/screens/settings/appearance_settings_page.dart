import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/screens/settings/client_sections/client_settings_theme.dart';
import 'package:driftfin/screens/settings/client_sections/client_settings_visual.dart';
import 'package:driftfin/screens/settings/settings_scaffold.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Theme + Visual, promoted to their own destination (issue #50 Phase 2 —
/// these used to be buried in the dissolved "Client" page).
@RoutePage()
class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends ConsumerState<AppearanceSettingsPage> {
  late final nextUpDaysEditor = TextEditingController(
      text: ref.read(clientSettingsProvider.select((value) => value.nextUpDateCutoff?.inDays ?? 14)).toString());

  late final libraryPageSizeController = TextEditingController(
      text: ref.read(clientSettingsProvider.select((value) => value.libraryPageSize))?.toString() ?? "");

  @override
  void dispose() {
    nextUpDaysEditor.dispose();
    libraryPageSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      label: context.localized.settingsAppearanceTitle,
      items: [
        ...buildClientSettingsTheme(context, ref),
        const SizedBox(height: 12),
        ...buildClientSettingsVisual(context, ref, nextUpDaysEditor, libraryPageSizeController),
      ],
    );
  }
}
