import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:driftfin/providers/calendar_provider.dart';
import 'package:driftfin/util/fladder_image.dart';
import 'package:driftfin/util/localization_helper.dart';

enum _CalFilter { all, tv, movies }

/// Calendar of upcoming/airing episodes (Sonarr + Jellyfin) and movie releases
/// (Radarr), grouped by day, with an agenda or month-grid view and a type filter.
@RoutePage()
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _monthView = false;
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  _CalFilter _filter = _CalFilter.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  Map<DateTime, List<CalendarEntry>> _applyFilter(Map<DateTime, List<CalendarEntry>> byDay) {
    if (_filter == _CalFilter.all) return byDay;
    final out = <DateTime, List<CalendarEntry>>{};
    byDay.forEach((day, list) {
      final filtered = list.where((e) => _filter == _CalFilter.movies ? e.isMovie : !e.isMovie).toList();
      if (filtered.isNotEmpty) out[day] = filtered;
    });
    return out;
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return context.localized.calendarToday;
    if (diff == 1) return context.localized.calendarTomorrow;
    return DateFormat('EEEE, d MMM').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final calendar = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.localized.calendarTitle),
        actions: [
          PopupMenuButton<_CalFilter>(
            icon: const Icon(Icons.filter_list),
            initialValue: _filter,
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (context) => [
              PopupMenuItem(value: _CalFilter.all, child: Text(context.localized.calendarFilterAll)),
              PopupMenuItem(value: _CalFilter.tv, child: Text(context.localized.calendarFilterTv)),
              PopupMenuItem(value: _CalFilter.movies, child: Text(context.localized.calendarFilterMovies)),
            ],
          ),
          IconButton(
            tooltip: _monthView ? 'Agenda' : 'Month',
            icon: Icon(_monthView ? Icons.view_agenda_outlined : Icons.calendar_view_month_outlined),
            onPressed: () => setState(() => _monthView = !_monthView),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshCalendar();
          ref.invalidate(calendarProvider);
          await ref.read(calendarProvider.future);
        },
        child: calendar.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _empty(context),
          data: (raw) {
            final byDay = _applyFilter(raw);
            if (byDay.isEmpty) return _empty(context);
            return _monthView ? _buildMonth(context, byDay) : _buildAgenda(context, byDay);
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) =>
      ListView(children: [const SizedBox(height: 120), Center(child: Text(context.localized.calendarEmpty))]);

  Widget _buildAgenda(BuildContext context, Map<DateTime, List<CalendarEntry>> byDay) {
    final days = byDay.keys.toList()..sort();
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(_dayLabel(context, day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ...byDay[day]!.map((entry) => _CalendarTile(entry: entry)),
          ],
        );
      },
    );
  }

  Widget _buildMonth(BuildContext context, Map<DateTime, List<CalendarEntry>> byDay) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday-first
    final cellCount = leadingBlanks + daysInMonth;
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedEntries = byDay[_selectedDay] ?? const [];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
              ),
              Expanded(
                child: Text(DateFormat('MMMM yyyy').format(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
              Expanded(
                child: Center(
                  child: Text(d, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: cellCount,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final dayNum = index - leadingBlanks + 1;
            final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            final count = byDay[day]?.length ?? 0;
            final isSelected = DateUtils.isSameDay(day, _selectedDay);
            final isToday = DateUtils.isSameDay(day, today);
            return InkWell(
              onTap: () => setState(() => _selectedDay = day),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum', style: theme.textTheme.bodyMedium),
                    if (count > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(_dayLabel(context, _selectedDay),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (selectedEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text(context.localized.calendarEmpty)),
          )
        else
          ...selectedEntries.map((entry) => _CalendarTile(entry: entry)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CalendarTile extends StatelessWidget {
  final CalendarEntry entry;
  const _CalendarTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = entry.hasFile ? Colors.green : theme.colorScheme.primary;
    final statusText = entry.hasFile ? '✓' : DateFormat.jm().format(entry.airDate);
    final subtitle = entry.isMovie
        ? context.localized.calendarFilterMovies
        : [entry.codeLabel, if (entry.episodeTitle.isNotEmpty) entry.episodeTitle].where((s) => s.isNotEmpty).join(' · ');

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
                  placeHolder: Icon(
                    entry.isMovie ? Icons.movie_outlined : Icons.live_tv_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.seriesTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
              child: Text(statusText, style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
