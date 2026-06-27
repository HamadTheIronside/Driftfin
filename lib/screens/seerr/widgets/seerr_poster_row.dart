import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/seerr/seerr_dashboard_model.dart';
import 'package:driftfin/providers/arguments_provider.dart';
import 'package:driftfin/screens/seerr/widgets/seerr_poster_card.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout.dart';
import 'package:driftfin/util/focus_provider.dart';
import 'package:driftfin/widgets/shared/ensure_visible.dart';
import 'package:driftfin/widgets/shared/horizontal_list.dart';

class SeerrPosterRow extends ConsumerWidget {
  final List<SeerrDashboardPosterModel> posters;
  final String label;
  final EdgeInsets contentPadding;
  final void Function(SeerrDashboardPosterModel focused)? onFocused;

  final void Function()? onLabelClick;

  const SeerrPosterRow({
    required this.posters,
    required this.label,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.onFocused,
    this.onLabelClick,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominantRatio = AdaptiveLayout.poster(context).ratio;

    return HorizontalList<SeerrDashboardPosterModel>(
      contentPadding: contentPadding,
      label: label,
      autoFocus: ref.read(argumentsStateProvider).htpcMode ? FocusProvider.autoFocusOf(context) : false,
      onLabelClick: onLabelClick,
      dominantRatio: dominantRatio,
      items: posters,
      onFocused: (index) {
        if (onFocused != null) {
          onFocused?.call(posters[index]);
        } else {
          context.ensureVisible();
        }
      },
      itemBuilder: (context, index) {
        final poster = posters[index];
        return SeerrPosterCard(
          key: Key(poster.id),
          poster: poster,
          aspectRatio: dominantRatio,
        );
      },
    );
  }
}
