import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/item_editing_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/items/series_model.dart';

final _refCaptureProvider = Provider<Ref>((ref) => ref);

SeriesModel _series({String id = 's1'}) => SeriesModel(
      originalTitle: id,
      sortName: id,
      status: '',
      name: id,
      id: id,
      overview: const OverviewModel(),
      parentId: null,
      playlistId: null,
      images: null,
      childCount: null,
      primaryRatio: null,
      userData: const UserData(),
    );

void main() {
  group('EditingImageModel.ratio', () {
    test('is 1.0 when both width and height are 0', () {
      final image = EditingImageModel(providerName: 'p');
      expect(image.ratio, 1.0);
    });

    test('computes a normal ratio', () {
      final image = EditingImageModel(providerName: 'p', width: 16, height: 9);
      expect(image.ratio, closeTo(16 / 9, 0.0001));
    });

    test('clamps an extremely wide ratio to 5', () {
      final image = EditingImageModel(providerName: 'p', width: 1000, height: 1);
      expect(image.ratio, 5);
    });

    test('clamps an extremely tall ratio to 0.1', () {
      final image = EditingImageModel(providerName: 'p', width: 1, height: 1000);
      expect(image.ratio, 0.1);
    });
  });

  group('EditingImageModel.copyWith / equality', () {
    test('copyWith overrides only the given fields', () {
      final image = EditingImageModel(providerName: 'p', width: 10, height: 20);
      final copy = image.copyWith(width: 30);
      expect(copy.width, 30);
      expect(copy.height, 20);
      expect(copy.providerName, 'p');
    });

    test('equal when all fields match, unequal when one differs', () {
      final a = EditingImageModel(providerName: 'p', width: 10, height: 20);
      final b = EditingImageModel(providerName: 'p', width: 10, height: 20);
      final c = EditingImageModel(providerName: 'p', width: 11, height: 20);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('EditItemsProvider.copyWith', () {
    test('overrides only the given fields, keeps others', () {
      const provider = EditItemsProvider(images: [], customImages: []);
      final selected = EditingImageModel(providerName: 'sel');
      final copy = provider.copyWith(selected: () => selected);
      expect(copy.selected, selected);
      expect(copy.images, isEmpty);
    });

    test('selected can be explicitly cleared to null via ValueGetter', () {
      final selected = EditingImageModel(providerName: 'sel');
      final provider = EditItemsProvider(selected: selected);
      final copy = provider.copyWith(selected: () => null);
      expect(copy.selected, isNull);
    });
  });

  group('ItemEditingModel.editAbleFields', () {
    test('null editedJson returns an empty map', () {
      final model = ItemEditingModel();
      expect(model.editAbleFields(), {});
    });

    test('maps each known key and drops nulls', () {
      final model = ItemEditingModel(editedJson: {
        'Name': 'The Name',
        'OriginalTitle': 'Original',
        'PremiereDate': '2020-01-15T00:00:00.000Z',
        'DateCreated': '2019-05-01T00:00:00.000Z',
        'ProductionYear': 2020,
        'Path': '/media/movie.mkv',
        'Overview': 'A summary',
      });
      final fields = model.editAbleFields();
      expect(fields?['Name'], 'The Name');
      expect(fields?['OriginalTitle'], 'Original');
      expect(fields?['PremiereDate'], DateTime.tryParse('2020-01-15T00:00:00.000Z'));
      expect(fields?['DateCreated'], DateTime.tryParse('2019-05-01T00:00:00.000Z'));
      expect(fields?['ProductionYear'], 2020);
      expect(fields?['Path'], '/media/movie.mkv');
      expect(fields?['Overview'], 'A summary');
    });

    test('Overview defaults to empty string when missing', () {
      final model = ItemEditingModel(editedJson: {'Name': 'X'});
      expect(model.editAbleFields()?['Overview'], '');
    });

    test('null-valued entries are removed from the resulting map', () {
      final model = ItemEditingModel(editedJson: {'Name': null});
      final fields = model.editAbleFields();
      expect(fields?.containsKey('Name'), isFalse);
      // Overview always has a non-null default so it stays.
      expect(fields?.containsKey('Overview'), isTrue);
    });

    test('unparsable date strings fall back to null and get removed', () {
      final model = ItemEditingModel(editedJson: {'PremiereDate': 'not-a-date'});
      final fields = model.editAbleFields();
      expect(fields?.containsKey('PremiereDate'), isFalse);
    });
  });

  group('ItemEditingModel.editAdvancedAbleFields', () {
    late ProviderContainer container;
    late Ref ref;

    setUp(() {
      container = ProviderContainer();
      ref = container.read(_refCaptureProvider);
    });

    tearDown(() => container.dispose());

    test('null editedJson returns an empty map', () {
      final model = ItemEditingModel();
      expect(model.editAdvancedAbleFields(ref), {});
    });

    test('RunTimeTicks is converted from ticks to a Duration in milliseconds', () {
      final model = ItemEditingModel(editedJson: {'RunTimeTicks': 10000 * 5000});
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?['RunTimeTicks'], const Duration(milliseconds: 5000));
    });

    test('RunTimeTicks missing is removed from the map', () {
      final model = ItemEditingModel(editedJson: {'Name': 'x'});
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?.containsKey('RunTimeTicks'), isFalse);
    });

    test('Genres and Tags are converted to List<String>', () {
      final model = ItemEditingModel(editedJson: {
        'Genres': ['Action', 'Drama'],
        'Tags': ['HDR'],
      });
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?['Genres'], ['Action', 'Drama']);
      expect(fields?['Tags'], ['HDR']);
    });

    test('CommunityRating parses from a numeric value', () {
      final model = ItemEditingModel(editedJson: {'CommunityRating': 8});
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?['CommunityRating'], 8.0);
    });

    test('LockData defaults to false when missing', () {
      final model = ItemEditingModel(editedJson: {'Name': 'x'});
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?['LockData'], false);
    });

    test('LockedFields is built only when LockData is explicitly false', () {
      final model = ItemEditingModel(editedJson: {
        'LockData': false,
        'LockedFields': ['Name', 'Genres'],
      });
      final fields = model.editAdvancedAbleFields(ref);
      final locked = fields?['LockedFields'] as Map<EditorLockedFields, bool>;
      expect(locked[EditorLockedFields.name], isTrue);
      expect(locked[EditorLockedFields.genres], isTrue);
      expect(locked[EditorLockedFields.tags], isFalse);
    });

    test('LockedFields is absent (removed) when LockData is true', () {
      final model = ItemEditingModel(editedJson: {'LockData': true});
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?.containsKey('LockedFields'), isFalse);
    });

    test(
        'LockedFields is absent (removed) when LockData is missing (defaults to false via ?? but the '
        'LockedFields condition checks the raw value which is null, not false)', () {
      final model = ItemEditingModel(editedJson: {'Name': 'x'});
      final fields = model.editAdvancedAbleFields(ref);
      // editedJson?["LockData"] is null here, so `== false` is false -> LockedFields stays null -> removed.
      expect(fields?.containsKey('LockedFields'), isFalse);
    });

    test('null-valued entries are removed from the resulting map', () {
      final model = ItemEditingModel(editedJson: {'SeriesName': null});
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?.containsKey('SeriesName'), isFalse);
    });

    test('SeriesModel-only fields (DisplayOrder/Status) are included when item is a SeriesModel', () {
      final model = ItemEditingModel(
        item: _series(),
        editedJson: {
          'DisplayOrder': 'absolute',
          'Status': 'Ended',
        },
      );
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?['DisplayOrder'], DisplayOrder.absolute);
      expect(fields?['Status'], ShowStatus.ended);
    });

    test('SeriesModel-only fields are omitted entirely for a non-series item', () {
      final model = ItemEditingModel(editedJson: {
        'DisplayOrder': 'absolute',
        'Status': 'Ended',
      });
      final fields = model.editAdvancedAbleFields(ref);
      expect(fields?.containsKey('DisplayOrder'), isFalse);
      expect(fields?.containsKey('Status'), isFalse);
    });
  });
}
