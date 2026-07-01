import 'package:driftfin/models/items/item_shared_models.dart';

class TastePassportModel {
  final bool loading;
  final List<MapEntry<String, int>> topGenres;
  final List<MapEntry<Studio, int>> topStudios;
  final List<MapEntry<Person, int>> topDirectors;
  final List<MapEntry<Person, int>> topActors;
  final Duration totalWatchTime;
  final int itemsWatched;
  final DateTime? generatedAt;

  const TastePassportModel({
    this.loading = false,
    this.topGenres = const [],
    this.topStudios = const [],
    this.topDirectors = const [],
    this.topActors = const [],
    this.totalWatchTime = Duration.zero,
    this.itemsWatched = 0,
    this.generatedAt,
  });

  bool get hasData => itemsWatched > 0;

  TastePassportModel copyWith({
    bool? loading,
    List<MapEntry<String, int>>? topGenres,
    List<MapEntry<Studio, int>>? topStudios,
    List<MapEntry<Person, int>>? topDirectors,
    List<MapEntry<Person, int>>? topActors,
    Duration? totalWatchTime,
    int? itemsWatched,
    DateTime? generatedAt,
  }) {
    return TastePassportModel(
      loading: loading ?? this.loading,
      topGenres: topGenres ?? this.topGenres,
      topStudios: topStudios ?? this.topStudios,
      topDirectors: topDirectors ?? this.topDirectors,
      topActors: topActors ?? this.topActors,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
      itemsWatched: itemsWatched ?? this.itemsWatched,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
