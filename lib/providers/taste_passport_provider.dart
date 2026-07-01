import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:driftfin/models/taste_passport_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/service_provider.dart';
import 'package:driftfin/util/taste_signals.dart';

/// Taste Passport - a privacy-first, on-device taste profile built purely
/// from the user's own watch history. Nothing here leaves the device; it
/// simply aggregates data Jellyfin already returned for played items.
final tastePassportProvider = StateNotifierProvider<TastePassportNotifier, TastePassportModel>((ref) {
  return TastePassportNotifier(ref);
});

class TastePassportNotifier extends StateNotifier<TastePassportModel> {
  TastePassportNotifier(this.ref) : super(const TastePassportModel());

  final Ref ref;

  late final JellyService api = ref.read(jellyApiProvider);

  Future<void> fetchProfile() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);

    final response = await api.itemsGet(
      recursive: true,
      filters: [ItemFilter.isplayed],
      includeItemTypes: [BaseItemKind.movie, BaseItemKind.episode],
      enableUserData: true,
      limit: 500,
      fields: [
        ItemFields.genres,
        ItemFields.people,
        ItemFields.studios,
      ],
    );

    final watched = response.body?.items ?? [];

    state = TastePassportModel(
      loading: false,
      topGenres: TasteSignals.topGenres(watched, limit: 8),
      topStudios: TasteSignals.topStudios(watched, limit: 8),
      topDirectors: TasteSignals.topDirectors(watched, limit: 8),
      topActors: TasteSignals.topActors(watched, limit: 8),
      totalWatchTime: TasteSignals.totalWatchTime(watched),
      itemsWatched: watched.length,
      generatedAt: DateTime.now(),
    );
  }

  void clear() => state = const TastePassportModel();
}
