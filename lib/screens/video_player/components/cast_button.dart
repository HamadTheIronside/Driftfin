import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/providers/cast_provider.dart';
import 'package:driftfin/util/localization_helper.dart';
import 'package:driftfin/widgets/shared/modal_bottom_sheet.dart';

/// Cast button for the player controls bar. Tap to open the device picker /
/// cast controls. Reflects the current cast state (connected vs idle).
class CastButton extends ConsumerWidget {
  const CastButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casting = ref.watch(castProvider.select((s) => s.isCasting));
    return IconButton(
      tooltip: context.localized.castTo,
      onPressed: () {
        if (!casting) ref.read(castProvider.notifier).discover();
        _showCastSheet(context, ref);
      },
      icon: Icon(casting ? Icons.cast_connected_rounded : Icons.cast_rounded),
    );
  }
}

void _showCastSheet(BuildContext context, WidgetRef ref) {
  showBottomSheetPill(
    context: context,
    content: (context, scrollController) => _CastSheet(scrollController: scrollController),
  );
}

class _CastSheet extends ConsumerWidget {
  final ScrollController scrollController;
  const _CastSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(castProvider);
    final notifier = ref.read(castProvider.notifier);
    final theme = Theme.of(context);

    if (state.isCasting) {
      return _CastControls(state: state, notifier: notifier);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.localized.castTo, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (state.status == CastStatus.connecting)
            ListTile(
              leading: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              title: Text(context.localized.castConnecting),
            )
          else if (state.devices.isEmpty)
            ListTile(
              leading: state.status == CastStatus.discovering
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cast_rounded),
              title: Text(state.status == CastStatus.discovering
                  ? context.localized.castSearching
                  : context.localized.castNoDevices),
            )
          else
            ...state.devices.map(
              (device) => ListTile(
                leading: const Icon(Icons.tv_rounded),
                title: Text(device.name),
                onTap: () {
                  notifier.connect(device);
                  Navigator.of(context).pop();
                },
              ),
            ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(context.localized.castFailed,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _CastControls extends StatelessWidget {
  final CastState state;
  final CastController notifier;
  const _CastControls({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = state.duration.inSeconds.toDouble();
    final value = state.position.inSeconds.toDouble().clamp(0, max == 0 ? 1 : max);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.cast_connected_rounded),
            title: Text(context.localized.castCastingTo(state.device?.name ?? '')),
          ),
          Slider(
            min: 0,
            max: max == 0 ? 1 : max,
            value: value.toDouble(),
            onChanged: max == 0 ? null : (v) => notifier.seek(Duration(seconds: v.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                icon: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                onPressed: () => state.playing ? notifier.pause() : notifier.play(),
              ),
              const SizedBox(width: 24),
              TextButton.icon(
                icon: const Icon(Icons.stop_rounded),
                label: Text(context.localized.castStop),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: () {
                  notifier.disconnect();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
