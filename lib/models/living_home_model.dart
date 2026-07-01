import 'package:driftfin/models/recommended_model.dart';

class LivingHomeModel {
  final bool loading;
  final List<RecommendedModel> rails;
  final DateTime? lastFetched;

  const LivingHomeModel({
    this.loading = false,
    this.rails = const [],
    this.lastFetched,
  });

  LivingHomeModel copyWith({
    bool? loading,
    List<RecommendedModel>? rails,
    DateTime? Function()? lastFetched,
  }) {
    return LivingHomeModel(
      loading: loading ?? this.loading,
      rails: rails ?? this.rails,
      lastFetched: lastFetched != null ? lastFetched() : this.lastFetched,
    );
  }
}
