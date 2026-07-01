import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/util/people_extension.dart';

void main() {
  group('PeopleExtension', () {
    Person person(String id, PersonKind? type) => Person(id: id, name: id, type: type);

    test('guestActors returns only guest stars', () {
      final people = [
        person('1', PersonKind.actor),
        person('2', PersonKind.gueststar),
        person('3', PersonKind.director),
        person('4', PersonKind.gueststar),
      ];
      expect(people.guestActors.map((p) => p.id), ['2', '4']);
    });

    test('mainCast returns everyone except guest stars', () {
      final people = [
        person('1', PersonKind.actor),
        person('2', PersonKind.gueststar),
        person('3', PersonKind.director),
      ];
      expect(people.mainCast.map((p) => p.id), ['1', '3']);
    });

    test('mainCast includes people with null type', () {
      final people = [person('1', null), person('2', PersonKind.gueststar)];
      expect(people.mainCast.map((p) => p.id), ['1']);
    });

    test('empty list returns empty for both getters', () {
      final people = <Person>[];
      expect(people.guestActors, isEmpty);
      expect(people.mainCast, isEmpty);
    });

    test('all guest stars: mainCast empty, guestActors full', () {
      final people = [person('1', PersonKind.gueststar), person('2', PersonKind.gueststar)];
      expect(people.mainCast, isEmpty);
      expect(people.guestActors.length, 2);
    });
  });
}
