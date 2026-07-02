import 'package:flutter/material.dart';

/// A single icon action rendered inline by [AdaptiveActionBar], or as a
/// list entry in its overflow menu when it doesn't fit.
class PlayerBarAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const PlayerBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
}

/// Splits [actions] into the ones that fit inline within [maxWidth] and the
/// rest, which the caller renders behind an overflow control. Reserves a
/// slot for that overflow control whenever not everything fits.
///
/// Pure function so the collapsing logic can be unit tested without pumping
/// a widget tree.
List<PlayerBarAction> visibleBarActions(
  List<PlayerBarAction> actions,
  double maxWidth, {
  double itemExtent = 48,
}) {
  if (actions.isEmpty) return const [];
  if (!maxWidth.isFinite || itemExtent <= 0) return actions;

  final maxVisible = (maxWidth / itemExtent).floor();
  if (maxVisible >= actions.length) return actions;

  final visibleCount = (maxVisible - 1).clamp(0, actions.length);
  return actions.take(visibleCount).toList();
}

/// Renders as many [actions] as fit in the available width as plain icon
/// buttons, collapsing whatever doesn't fit into a single "more" overflow
/// menu instead of letting the row scroll or overflow.
///
/// Replaces the previous pattern of packing every secondary control (chapters,
/// screenshot, PiP, subtitle/audio quick toggles, ...) into a horizontally
/// scrolling row that only grew as features were added.
class AdaptiveActionBar extends StatelessWidget {
  final List<PlayerBarAction> actions;
  final double itemExtent;

  const AdaptiveActionBar({
    super.key,
    required this.actions,
    this.itemExtent = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Not even room for a single icon (let alone the overflow control
        // that would be needed to reach the rest) - degrade to nothing
        // rather than forcing a RenderFlex overflow.
        if (constraints.maxWidth.isFinite && constraints.maxWidth < itemExtent) {
          return const SizedBox.shrink();
        }

        final visible = visibleBarActions(actions, constraints.maxWidth, itemExtent: itemExtent);
        final overflow = actions.sublist(visible.length);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in visible)
              IconButton(
                tooltip: action.tooltip,
                onPressed: action.onPressed,
                icon: Icon(action.icon),
              ),
            if (overflow.isNotEmpty)
              PopupMenuButton<PlayerBarAction>(
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                icon: const Icon(Icons.more_horiz_rounded),
                itemBuilder: (context) => [
                  for (final action in overflow)
                    PopupMenuItem<PlayerBarAction>(
                      value: action,
                      enabled: action.onPressed != null,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(action.icon),
                        title: Text(action.tooltip),
                      ),
                    ),
                ],
                onSelected: (action) => action.onPressed?.call(),
              ),
          ],
        );
      },
    );
  }
}
