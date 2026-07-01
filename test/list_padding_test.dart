import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/list_padding.dart';

void main() {
  group('ListExtensions.addInBetween', () {
    test('inserts separator widget between elements, not after last', () {
      const sep = SizedBox(key: Key('sep'));
      final widgets = [
        const Text('a', key: Key('a')),
        const Text('b', key: Key('b')),
        const Text('c', key: Key('c')),
      ];
      final result = widgets.addInBetween(sep);
      expect(result.length, 5);
      expect(result[1], sep);
      expect(result[3], sep);
    });

    test('single element list returns itself unchanged', () {
      final widgets = [const Text('only')];
      final result = widgets.addInBetween(const SizedBox());
      expect(result.length, 1);
      expect(result.first, widgets.first);
    });

    test('empty list returns empty list', () {
      final result = <Widget>[].addInBetween(const SizedBox());
      expect(result, isEmpty);
    });
  });

  group('ListExtensions.addPadding', () {
    test('wraps plain widgets in Padding with zero at first/last edges', () {
      final widgets = [
        const Text('a', key: Key('a')),
        const Text('b', key: Key('b')),
        const Text('c', key: Key('c')),
      ];
      const padding = EdgeInsets.all(8);
      final result = widgets.addPadding(padding);
      expect(result.length, 3);

      final firstPadding = (result[0] as Padding).padding as EdgeInsets;
      expect(firstPadding.top, 0);
      expect(firstPadding.left, 0);
      expect(firstPadding.right, 8);

      final lastPadding = (result[2] as Padding).padding as EdgeInsets;
      expect(lastPadding.bottom, 0);
      expect(lastPadding.right, 0);
      expect(lastPadding.left, 8);

      final middlePadding = (result[1] as Padding).padding as EdgeInsets;
      expect(middlePadding.top, 8);
      expect(middlePadding.left, 8);
      expect(middlePadding.right, 8);
      expect(middlePadding.bottom, 8);
    });

    test('does not wrap Expanded, Spacer, or Flexible widgets', () {
      final widgets = <Widget>[
        const Expanded(child: Text('a')),
        const Spacer(),
        const Flexible(child: Text('b')),
      ];
      final result = widgets.addPadding(const EdgeInsets.all(4));
      expect(result[0], isA<Expanded>());
      expect(result[1], isA<Spacer>());
      expect(result[2], isA<Flexible>());
    });

    test('single element gets zero padding on all sides (both first and last)', () {
      final widgets = [const Text('only')];
      final result = widgets.addPadding(const EdgeInsets.all(10));
      final padding = (result[0] as Padding).padding as EdgeInsets;
      expect(padding.top, 0);
      expect(padding.left, 0);
      expect(padding.right, 0);
      expect(padding.bottom, 0);
    });
  });

  group('ListExtensions.addSize', () {
    test('wraps plain widgets in SizedBox with given dimensions', () {
      final widgets = [const Text('a'), const Text('b')];
      final result = widgets.addSize(width: 20, height: 30);
      for (final w in result) {
        final box = w as SizedBox;
        expect(box.width, 20);
        expect(box.height, 30);
      }
    });

    test('does not wrap Expanded, Spacer, or Flexible widgets', () {
      final widgets = <Widget>[const Spacer(), const Expanded(child: Text('a'))];
      final result = widgets.addSize(width: 5, height: 5);
      expect(result[0], isA<Spacer>());
      expect(result[1], isA<Expanded>());
    });

    test('empty list returns empty list', () {
      expect(<Widget>[].addSize(width: 1, height: 1), isEmpty);
    });
  });
}
