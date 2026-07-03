import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/screens/settings/client_sections/client_settings_download.dart';
import 'package:driftfin/screens/settings/settings_scaffold.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Downloads, promoted to its own destination (issue #50 Phase 2 — used to be
/// buried in the dissolved "Client" page). Reserved slot for Smart Downloads
/// (#43).
@RoutePage()
class DownloadsSettingsPage extends ConsumerStatefulWidget {
  const DownloadsSettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DownloadsSettingsPageState();
}

class _DownloadsSettingsPageState extends ConsumerState<DownloadsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      label: context.localized.settingsDownloadsOfflineTitle,
      items: buildClientSettingsDownload(context, ref, setState),
    );
  }
}
