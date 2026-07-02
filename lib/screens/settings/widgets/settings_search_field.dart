import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:driftfin/models/settings/settings_entry.dart';
import 'package:driftfin/providers/settings/settings_registry.dart';
import 'package:driftfin/screens/settings/settings_list_tile.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Persistent search field for the settings root (issue #50 Phase 1): filters
/// [buildSettingsRegistry] by [SettingsEntry.matches] as the user types and
/// deep-links to the owning page on tap.
class SettingsSearchField extends ConsumerStatefulWidget {
  const SettingsSearchField({super.key});

  @override
  ConsumerState<SettingsSearchField> createState() => _SettingsSearchFieldState();
}

class _SettingsSearchFieldState extends ConsumerState<SettingsSearchField> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localized;
    final results = _query.trim().isEmpty ? const <SettingsEntry>[] : searchSettingsRegistry(_registry, _query, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.search,
            isDense: true,
            prefixIcon: const Icon(IconsaxPlusLinear.search_normal, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clear,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (_query.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.noResults, textAlign: TextAlign.center),
            )
          else
            ...results.map(
              (entry) => SettingsListTile(
                id: entry.id,
                label: Text(entry.label(l10n)),
                onTap: () {
                  _clear();
                  FocusScope.of(context).unfocus();
                  context.tabsRouter.navigate(entry.route());
                },
              ),
            ),
          const Divider(),
        ],
      ],
    );
  }

  List<SettingsEntry> get _registry => buildSettingsRegistry();
}
