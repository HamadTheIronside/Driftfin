import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/tonight_model.dart';
import 'package:driftfin/util/tonight_picker.dart';

void main() {
  group('TonightModel', () {
    test('hasPicks reflects whether picks is empty', () {
      expect(const TonightModel().hasPicks, isFalse);
      expect(const TonightModel(picks: []).hasPicks, isFalse);
    });

    test('copyWith leaves fields unchanged when not passed', () {
      const model = TonightModel(loading: true, mood: TonightMood.cozy);
      final copy = model.copyWith();
      expect(copy.loading, isTrue);
      expect(copy.mood, TonightMood.cozy);
    });

    test('copyWith can explicitly clear timeAvailable back to null', () {
      const model = TonightModel(timeAvailable: Duration(minutes: 30));
      final copy = model.copyWith(timeAvailable: () => null);
      expect(copy.timeAvailable, isNull);
    });

    test('copyWith can set a new timeAvailable', () {
      const model = TonightModel();
      final copy = model.copyWith(timeAvailable: () => const Duration(hours: 1));
      expect(copy.timeAvailable, const Duration(hours: 1));
    });
  });
}
