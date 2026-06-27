import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import 'package:driftfin/providers/config_sync_provider.dart';
import 'package:driftfin/providers/settings/client_settings_provider.dart';
import 'package:driftfin/providers/settings/home_settings_provider.dart';
import 'package:driftfin/providers/sonarr_provider.dart';
import 'package:driftfin/providers/user_provider.dart';
import 'package:driftfin/screens/settings/settings_list_tile.dart';
import 'package:driftfin/screens/settings/widgets/settings_label_divider.dart';
import 'package:driftfin/screens/settings/widgets/settings_list_group.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout.dart';
import 'package:driftfin/util/localization_helper.dart';
import 'package:driftfin/util/option_dialogue.dart';

List<Widget> buildClientSettingsAdvanced(BuildContext context, WidgetRef ref) {
  return settingsListGroup(
    context,
    SettingsLabelDivider(label: context.localized.advanced),
    [
      SettingsListTile(
        label: Text(context.localized.syncSettingsTitle),
        subLabel: Text(context.localized.syncSettingsDesc),
        onTap: () => ref.read(syncSettingsEnabledProvider.notifier).set(!ref.read(syncSettingsEnabledProvider)),
        trailing: Switch(
          value: ref.watch(syncSettingsEnabledProvider),
          onChanged: (value) => ref.read(syncSettingsEnabledProvider.notifier).set(value),
        ),
      ),
      if (ref.watch(syncSettingsEnabledProvider))
        SettingsListTile(
          label: Text(context.localized.syncNow),
          subLabel: Builder(builder: (context) {
            final syncedAt = ref.watch(userProvider.select((value) => value?.userSettings?.syncedAt));
            final parsed = syncedAt == null ? null : DateTime.tryParse(syncedAt);
            return Text(parsed == null
                ? context.localized.syncedNever
                : context.localized.syncedAtLabel(DateFormat.yMd().add_jm().format(parsed.toLocal())));
          }),
          onTap: () => ref.read(configSyncProvider).syncNow(),
          trailing: const Icon(Icons.cloud_sync_outlined),
        ),
      SettingsListTile(
        label: Text(context.localized.settingsLayoutSizesTitle),
        subLabel: Text(context.localized.settingsLayoutSizesDesc),
        onTap: () async {
          final newItems = await openMultiSelectOptions<ViewSize>(
            context,
            label: context.localized.settingsLayoutSizesTitle,
            items: ViewSize.values,
            allowMultiSelection: true,
            selected: ref.read(homeSettingsProvider.select((value) => value.layoutStates.toList())),
            itemBuilder: (type, selected, tap) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: selected,
              onChanged: (value) => tap(),
              title: Text(type.label(context)),
            ),
          );
          ref.read(homeSettingsProvider.notifier).setViewSize(newItems.toSet());
        },
        trailing: Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          shadowColor: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ViewSize.values.map((e) {
                final isCurrent = AdaptiveLayout.viewSizeOf(context) == e;
                return Row(
                  spacing: 4,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.label(context)),
                    if (isCurrent) const Icon(IconsaxPlusLinear.tick_circle, size: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      SettingsListTile(
        label: Text(context.localized.settingsLayoutModesTitle),
        subLabel: Text(context.localized.settingsLayoutModesDesc),
        onTap: () async {
          final newItems = await openMultiSelectOptions<LayoutMode>(
            context,
            label: context.localized.settingsLayoutModesTitle,
            items: LayoutMode.values,
            allowMultiSelection: true,
            selected: ref.read(homeSettingsProvider.select((value) => value.screenLayouts.toList())),
            itemBuilder: (type, selected, tap) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: selected,
              onChanged: (value) => tap(),
              title: Text(type.label(context)),
            ),
          );
          ref.read(homeSettingsProvider.notifier).setLayoutModes(newItems.toSet());
        },
        trailing: Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          shadowColor: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: LayoutMode.values.map((e) {
                final isCurrent = AdaptiveLayout.layoutModeOf(context) == e;
                return Row(
                  spacing: 4,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.label(context)),
                    if (isCurrent) const Icon(IconsaxPlusLinear.tick_circle, size: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      if (AdaptiveLayout.inputDeviceOf(context) == InputDevice.dPad)
        SettingsListTile(
          label: Text(context.localized.clientSettingsUseSystemIMETitle),
          subLabel: Text(context.localized.clientSettingsUseSystemIMEDesc),
          onTap: () => ref
              .read(clientSettingsProvider.notifier)
              .useSystemIME(!ref.read(clientSettingsProvider.select((value) => value.useSystemIME))),
          trailing: Switch(
            value: ref.watch(clientSettingsProvider.select((value) => value.useSystemIME)),
            onChanged: (value) => ref.read(clientSettingsProvider.notifier).useSystemIME(value),
          ),
        ),
      SettingsListTile(
        label: Text(context.localized.sonarrIntegrationTitle),
        subLabel: Text(context.localized.sonarrIntegrationDesc),
        onTap: () => ref.read(sonarrProvider.notifier).setEnabled(!ref.read(sonarrProvider).enabled),
        trailing: Switch(
          value: ref.watch(sonarrProvider.select((value) => value.enabled)),
          onChanged: (value) => ref.read(sonarrProvider.notifier).setEnabled(value),
        ),
      ),
      if (ref.watch(sonarrProvider.select((value) => value.enabled))) ...[
        SettingsListTile(
          label: Text(context.localized.sonarrUrlTitle),
          subLabel: Text(ref.watch(sonarrProvider.select((value) => value.baseUrl)).isEmpty
              ? '—'
              : ref.watch(sonarrProvider.select((value) => value.baseUrl))),
          onTap: () async {
            final value = await _promptText(context,
                title: context.localized.sonarrUrlTitle, initial: ref.read(sonarrProvider).baseUrl);
            if (value != null) ref.read(sonarrProvider.notifier).setBaseUrl(value);
          },
          trailing: const Icon(Icons.link),
        ),
        SettingsListTile(
          label: Text(context.localized.sonarrApiKeyTitle),
          subLabel: Text(ref.watch(sonarrProvider.select((value) => value.apiKey)).isEmpty ? '—' : '••••••••'),
          onTap: () async {
            final value = await _promptText(context,
                title: context.localized.sonarrApiKeyTitle, initial: ref.read(sonarrProvider).apiKey, obscure: true);
            if (value != null) ref.read(sonarrProvider.notifier).setApiKey(value);
          },
          trailing: const Icon(Icons.key),
        ),
      ],
    ],
  );
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String initial,
  bool obscure = false,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        obscureText: obscure,
        autofocus: true,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.localized.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: Text(context.localized.save)),
      ],
    ),
  );
}
