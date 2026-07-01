import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/util/grouping.dart';

void main() {
  ItemBaseModel item(String name) => ItemBaseModel(
        name: name,
        id: name,
        overview: const OverviewModel(),
        parentId: null,
        playlistId: null,
        images: null,
        childCount: null,
        primaryRatio: null,
        userData: const UserData(),
        canDownload: null,
        canDelete: null,
        jellyType: null,
      );

  group('groupByName', () {
    test('groups items by their uppercased first letter', () {
      final items = [item('Alpha'), item('Beta'), item('Avocado')];
      final result = groupByName(items);
      expect(result.keys.toSet(), {'A', 'B'});
      expect(result['A']?.map((e) => e.name), ['Alpha', 'Avocado']);
      expect(result['B']?.map((e) => e.name), ['Beta']);
    });

    test('strips a leading "The " before grouping', () {
      final items = [item('The Matrix'), item('Matrix Reloaded')];
      final result = groupByName(items);
      expect(result.keys.toSet(), {'M'});
      expect(result['M']?.length, 2);
    });

    test('empty list returns empty map', () {
      expect(groupByName([]), isEmpty);
    });

    test('single item returns single group', () {
      final result = groupByName([item('Zebra')]);
      expect(result.keys.toList(), ['Z']);
      expect(result['Z']?.map((e) => e.name).toList(), ['Zebra']);
    });

    test('lowercase names are grouped under the uppercased letter', () {
      final result = groupByName([item('apple')]);
      expect(result.keys.toSet(), {'A'});
    });

    test('numeric or symbol first characters are used as-is', () {
      final result = groupByName([item('1984'), item('9 Songs')]);
      expect(result.keys.toSet(), {'1', '9'});
    });
  });
}
