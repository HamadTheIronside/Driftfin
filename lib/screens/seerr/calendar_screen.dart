import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:driftfin/providers/calendar_provider.dart';
import 'package:driftfin/util/fladder_image.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Agenda-style calendar of upcoming/airing episodes, grouped by day. Sourced
/// from Jellyfin "upcoming" + the Sonarr calendar (when configured).
@RoutePage()
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  String _dayLabel(BuildContext context, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return context.localized.calendarToday;
    if (diff == 1) return context.localized.calendarTomorrow;
    return DateFormat('EEEE, d MMM').format(day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.localized.calendarTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshCalendar();
          ref.invalidate(calendarProvider);
          await ref.read(calendarProvider.future);
        },
        child: calendar.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(children: [const SizedBox(height: 120), Center(child: Text(context.localized.calendarEmpty))]),
          data: (byDay) {
            if (byDay.isEmpty) {
              return ListView(children: [const SizedBox(height: 120), Center(child: Text(context.localized.calendarEmpty))]);
            }
            final days = byDay.keys.toList()..sort();
            return ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final entries = byDay[day]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        _dayLabel(context, day),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...entries.map((entry) => _CalendarTile(entry: entry)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CalendarTile extends StatelessWidget {
  final CalendarEntry entry;
  const _CalendarTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aired = entry.airDate.isBefore(DateTime.now());
    final statusColor = entry.hasFile ? Colors.green : (aired ? Colors.grey : theme.colorScheme.primary);
    final statusText = entry.hasFile
        ? '✓'
        : DateFormat.jm().format(entry.airDate);

    return InkWell(
      onTap: entry.item == null ? null : () => entry.item!.navigateTo(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          spacing: 12,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 64,
                height: 40,
                child: FladderImage(
                  image: entry.image,
                  placeHolder: Container(color: theme.colorScheme.surfaceContainer),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.seriesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    [entry.codeLabel, if (entry.episodeTitle.isNotEmpty) entry.episodeTitle].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
              child: Text(
                statusText,
                style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
