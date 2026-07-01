import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/util/item_query_fields.dart';

void main() {
  group('posterItemFields', () {
    test('contains the expected canonical fields', () {
      expect(
        posterItemFields,
        containsAll([
          ItemFields.parentid,
          ItemFields.primaryimageaspectratio,
          ItemFields.overview,
          ItemFields.mediastreams,
          ItemFields.mediasources,
          ItemFields.candelete,
          ItemFields.candownload,
        ]),
      );
    });

    test('has exactly 7 fields with no duplicates', () {
      expect(posterItemFields.length, 7);
      expect(posterItemFields.toSet().length, 7);
    });

    test('includes mediastreams needed for quality/HDR badges', () {
      expect(posterItemFields.contains(ItemFields.mediastreams), isTrue);
    });
  });
}
