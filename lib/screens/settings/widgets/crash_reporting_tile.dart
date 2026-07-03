import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/settings/settings_entry.dart';
import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/screens/settings/settings_list_tile.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Extracted so it can be unit-tested independently of the full Account &
/// Device page (see settings/account_device_settings_page.dart).
Widget buildCrashReportingTile(BuildContext context, WidgetRef ref) {
  return SettingsListTile(
    id: SettingId.crashReporting,
    label: Text(context.localized.crashReportingTitle),
    subLabel: Text(context.localized.crashReportingDesc),
    onTap: () => ref
        .read(clientSettingsProvider.notifier)
        .setEnableCrashReporting(!ref.read(clientSettingsProvider.select((value) => value.enableCrashReporting))),
    trailing: Switch(
      value: ref.watch(clientSettingsProvider.select((value) => value.enableCrashReporting)),
      onChanged: (value) => ref.read(clientSettingsProvider.notifier).setEnableCrashReporting(value),
    ),
  );
}
