import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/util/tonight_picker.dart';

class TonightModel {
  final bool loading;
  final List<ItemBaseModel> picks;
  final Duration? timeAvailable;
  final TonightMood mood;
  final DateTime? generatedAt;

  const TonightModel({
    this.loading = false,
    this.picks = const [],
    this.timeAvailable,
    this.mood = TonightMood.any,
    this.generatedAt,
  });

  bool get hasPicks => picks.isNotEmpty;

  TonightModel copyWith({
    bool? loading,
    List<ItemBaseModel>? picks,
    Duration? Function()? timeAvailable,
    TonightMood? mood,
    DateTime? Function()? generatedAt,
  }) {
    return TonightModel(
      loading: loading ?? this.loading,
      picks: picks ?? this.picks,
      timeAvailable: timeAvailable != null ? timeAvailable() : this.timeAvailable,
      mood: mood ?? this.mood,
      generatedAt: generatedAt != null ? generatedAt() : this.generatedAt,
    );
  }
}
