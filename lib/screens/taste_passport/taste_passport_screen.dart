import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/providers/taste_passport_provider.dart';
import 'package:driftfin/util/adaptive_layout/adaptive_layout.dart';
import 'package:driftfin/util/humanize_duration.dart';
import 'package:driftfin/util/localization_helper.dart';

@RoutePage()
class TastePassportScreen extends ConsumerStatefulWidget {
  const TastePassportScreen({super.key});

  @override
  ConsumerState<TastePassportScreen> createState() => _TastePassportScreenState();
}

class _TastePassportScreenState extends ConsumerState<TastePassportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tastePassportProvider.notifier).fetchProfile();
    });
  }

  Widget _section(BuildContext context, String title, List<String> labels) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels.map((label) => Chip(label: Text(label))).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(tastePassportProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AdaptiveLayout.adaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BackButton(),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.localized.tastePassport,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              Text(
                context.localized.tastePassportSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: profile.loading
                    ? const Center(child: CircularProgressIndicator())
                    : !profile.hasData
                        ? Center(child: Text(context.localized.tastePassportEmpty))
                        : ListView(
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _stat(
                                        context,
                                        context.localized.tastePassportItemsWatched,
                                        profile.itemsWatched.toString(),
                                      ),
                                      _stat(
                                        context,
                                        context.localized.tastePassportTotalWatchTime,
                                        profile.totalWatchTime.toLogicalDuration(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _section(
                                context,
                                context.localized.tastePassportTopGenres,
                                profile.topGenres.map((e) => e.key).toList(),
                              ),
                              _section(
                                context,
                                context.localized.tastePassportTopDirectors,
                                profile.topDirectors.map((e) => e.key.name).toList(),
                              ),
                              _section(
                                context,
                                context.localized.tastePassportTopActors,
                                profile.topActors.map((e) => e.key.name).toList(),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
