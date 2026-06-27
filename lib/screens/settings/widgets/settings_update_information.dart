import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/widget/markdown.dart';

import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/providers/update_provider.dart';
import 'package:driftfin/screens/settings/settings_list_tile.dart';
import 'package:driftfin/screens/shared/media/external_urls.dart';
import 'package:driftfin/util/list_padding.dart';
import 'package:driftfin/util/localization_helper.dart';
import 'package:driftfin/util/theme_extensions.dart';
import 'package:driftfin/util/update_checker.dart';
import 'package:driftfin/util/windows_updater.dart';

class SettingsUpdateInformation extends ConsumerStatefulWidget {
  const SettingsUpdateInformation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsUpdateInformationState();
}

class _SettingsUpdateInformationState extends ConsumerState<SettingsUpdateInformation> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((value) {
      final latestRelease = ref.read(updateProvider.select((value) => value.latestRelease));
      if (latestRelease == null) return;
      final lastViewedUpdate = ref.read(clientSettingsProvider.select((value) => value.lastViewedUpdate));
      if (lastViewedUpdate != latestRelease.version) {
        ref
            .read(clientSettingsProvider.notifier)
            .update((value) => value.copyWith(lastViewedUpdate: latestRelease.version));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final updates = ref.watch(updateProvider);
    final latestRelease = updates.latestRelease;
    final otherReleases = updates.lastRelease;
    final checkForUpdate = ref.watch(clientSettingsProvider.select((value) => value.checkForUpdates));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const Divider(),
          SettingsListTile(
            label: Text(context.localized.latestReleases),
            subLabel: Text(context.localized.autoCheckForUpdates),
            onTap: () => ref
                .read(clientSettingsProvider.notifier)
                .update((value) => value.copyWith(checkForUpdates: !checkForUpdate)),
            trailing: Switch(
              value: checkForUpdate,
              onChanged: (value) => ref
                  .read(clientSettingsProvider.notifier)
                  .update((value) => value.copyWith(checkForUpdates: !checkForUpdate)),
            ),
          ),
          if (latestRelease != null)
            UpdateInformation(
              releaseInfo: latestRelease,
              expanded: true,
            ),
          ...otherReleases.where((element) => element != latestRelease).map(
                (value) => UpdateInformation(releaseInfo: value),
              ),
        ],
      ),
    );
  }
}

class UpdateInformation extends StatefulWidget {
  final ReleaseInfo releaseInfo;
  final bool expanded;
  const UpdateInformation({
    required this.releaseInfo,
    this.expanded = false,
    super.key,
  });

  @override
  State<UpdateInformation> createState() => _UpdateInformationState();
}

class _UpdateInformationState extends State<UpdateInformation> {
  ReleaseInfo get releaseInfo => widget.releaseInfo;

  bool _installing = false;
  double _progress = 0;

  /// Whether the in-app installer can update to this release. Only the Windows
  /// portable build supports self-updating.
  bool get _canSelfInstall =>
      WindowsUpdater.isSupported && releaseInfo.downloadUrlFor('windows_portable') != null;

  Future<void> _installUpdate() async {
    final downloadUrl = releaseInfo.downloadUrlFor('windows_portable');
    if (downloadUrl == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.localized.installUpdateConfirmTitle(releaseInfo.version)),
            content: Text(context.localized.installUpdateConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.localized.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.localized.installUpdate),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() {
      _installing = true;
      _progress = 0;
    });

    try {
      await WindowsUpdater.downloadAndInstall(
        downloadUrl,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      // Hand off to the detached helper, which waits for us to exit before
      // overwriting the install directory and relaunching.
      exit(0);
    } catch (error) {
      if (!mounted) return;
      setState(() => _installing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.localized.updateInstallFailed(error.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      backgroundColor:
          releaseInfo.isNewerThanCurrent ? context.colors.primaryContainer : context.colors.surfaceContainer,
      collapsedBackgroundColor: releaseInfo.isNewerThanCurrent ? context.colors.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(releaseInfo.version),
      initiallyExpanded: widget.expanded,
      childrenPadding: const EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: MarkdownWidget(
              data: releaseInfo.changelog,
              shrinkWrap: true,
            ),
          ),
        ),
        if (_canSelfInstall)
          FilledButton.icon(
            onPressed: _installing ? null : _installUpdate,
            icon: _installing
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _progress == 0 ? null : _progress,
                    ),
                  )
                : const Icon(Icons.system_update_alt_rounded),
            label: Text(
              _installing ? context.localized.downloadingUpdate : context.localized.installUpdate,
            ),
          ),
        ...releaseInfo.preferredDownloads.entries.map(
          (entry) {
            return FilledButton(
              onPressed: () => launchUrl(context, entry.value),
              child: Text(
                entry.key.prettifyKey(),
              ),
            );
          },
        ),
        const Divider(),
        ...releaseInfo.otherDownloads.entries.map(
          (entry) {
            return ElevatedButton(
              onPressed: () => launchUrl(context, entry.value),
              child: Text(
                entry.key.prettifyKey(),
              ),
            );
          },
        )
      ].addInBetween(const SizedBox(height: 12)),
    );
  }
}
