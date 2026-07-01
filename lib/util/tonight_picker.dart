import 'package:driftfin/models/item_base_model.dart';

/// A loose mood tuning knob for [TonightPicker]. Maps to a small set of
/// Jellyfin genre strings used purely as a scoring boost, never a hard filter -
/// so a thin library still returns picks even if none of the mood's usual
/// genres are present.
enum TonightMood {
  any,
  cozy,
  thrilling,
  funny,
  uplifting;

  Set<String> get genreKeywords => switch (this) {
        TonightMood.any => const {},
        TonightMood.cozy => const {'romance', 'family', 'drama'},
        TonightMood.thrilling => const {'thriller', 'action', 'crime', 'mystery', 'horror'},
        TonightMood.funny => const {'comedy'},
        TonightMood.uplifting => const {'family', 'animation', 'music', 'adventure'},
      };
}

/// Collapses a pool of candidate items down to 3-5 decision-ready picks.
///
/// Runtime / "time-fit" filtering happens here, client-side, because
/// Jellyfin's `/Items` endpoint has no runtime query parameter.
class TonightPicker {
  const TonightPicker._();

  static const int minPicks = 3;
  static const int maxPicks = 5;

  static List<ItemBaseModel> pick(
    List<ItemBaseModel> candidates, {
    Duration? timeAvailable,
    TonightMood mood = TonightMood.any,
  }) {
    final deduped = <String, ItemBaseModel>{};
    for (final item in candidates) {
      deduped.putIfAbsent(item.id, () => item);
    }
    var pool = deduped.values.toList();

    if (timeAvailable != null) {
      final fitsTime = pool.where((item) => _fitsTimeBudget(item, timeAvailable)).toList();
      // Only relax the time budget if honoring it would leave us with too
      // few decision-ready picks - we'd rather show a slightly-too-long
      // movie than an empty screen.
      pool = fitsTime.length >= minPicks ? fitsTime : pool;
    }

    pool.sort((a, b) => _score(b, mood).compareTo(_score(a, mood)));

    return pool.take(maxPicks).toList();
  }

  static bool _fitsTimeBudget(ItemBaseModel item, Duration timeAvailable) {
    final runTime = item.overview.runTime;
    if (runTime == null) return true;
    return runTime <= timeAvailable;
  }

  static double _score(ItemBaseModel item, TonightMood mood) {
    double score = item.overview.communityRating ?? 5.0;
    if (item.userData.played) score -= 4;
    if (item.userData.progress > 0) score += 1;
    final genres = item.overview.genres.map((e) => e.toLowerCase()).toSet();
    if (mood.genreKeywords.any(genres.contains)) score += 3;
    return score;
  }
}
