import 'package:driftfin/models/items/chapters_model.dart';
import 'package:flutter_test/flutter_test.dart';

Chapter _chapter({String name = '', String imageUrl = '', int startMs = 0}) => Chapter(
      name: name,
      imageUrl: imageUrl,
      startPosition: Duration(milliseconds: startMs),
    );

void main() {
  group('Chapter.fromMap', () {
    test('defaults name/imageUrl to empty string when missing', () {
      final chapter = Chapter.fromMap({'startPosition': 1000});
      expect(chapter.name, '');
      expect(chapter.imageUrl, '');
      expect(chapter.startPosition, const Duration(milliseconds: 1000));
    });

    test('throws when startPosition is missing (not null-safe, unlike other fields)', () {
      expect(() => Chapter.fromMap({'name': 'Ch1'}), throwsA(anything));
    });

    test('round-trips through toMap/fromMap', () {
      final original = _chapter(name: 'Intro', imageUrl: 'http://x/img.jpg', startMs: 5000);
      final restored = Chapter.fromMap(original.toMap());
      expect(restored.name, original.name);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.startPosition, original.startPosition);
    });

    test('round-trips through toJson/fromJson', () {
      final original = _chapter(name: 'Ch2', imageUrl: '/local/path.jpg', startMs: 2500);
      final restored = Chapter.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.startPosition, original.startPosition);
    });
  });

  group('Chapter.copyWith', () {
    test('overrides only the given fields', () {
      final original = _chapter(name: 'A', imageUrl: 'a.jpg', startMs: 100);
      final copy = original.copyWith(name: 'B');
      expect(copy.name, 'B');
      expect(copy.imageUrl, 'a.jpg');
      expect(copy.startPosition, original.startPosition);
    });
  });

  group('ChapterExtension.getChapterFromDuration', () {
    final chapters = [
      _chapter(name: 'Ch1', startMs: 0),
      _chapter(name: 'Ch2', startMs: 10000),
      _chapter(name: 'Ch3', startMs: 20000),
    ];

    test('returns the last chapter whose start is strictly before the duration', () {
      final current = chapters.getChapterFromDuration(const Duration(milliseconds: 15000));
      expect(current?.name, 'Ch2');
    });

    test('excludes a chapter whose start exactly equals the duration', () {
      final current = chapters.getChapterFromDuration(const Duration(milliseconds: 10000));
      expect(current?.name, 'Ch1');
    });

    test('returns null when duration is before every chapter', () {
      final current = chapters.getChapterFromDuration(const Duration(milliseconds: -1));
      expect(current, isNull);
    });

    test('returns null for an empty chapter list', () {
      expect(<Chapter>[].getChapterFromDuration(const Duration(seconds: 1)), isNull);
    });

    test('returns the last chapter when duration is past all starts', () {
      final current = chapters.getChapterFromDuration(const Duration(hours: 1));
      expect(current?.name, 'Ch3');
    });
  });
}
