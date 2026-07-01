import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/item_editing_model.dart';
import 'package:driftfin/providers/edit_item_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late EditItemNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(editItemProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('EditItemNotifier - updateField', () {
    test('updates an existing key in editedJson', () async {
      notifier.state = notifier.state.copyWith(
        editedJson: () => {'Name': 'Old name'},
      );

      await notifier.updateField(const MapEntry('Name', 'New name'));

      expect(notifier.state.editedJson?['Name'], 'New name');
    });

    test('does nothing when editedJson is null (null-safe no-op)', () async {
      expect(notifier.state.editedJson, isNull);

      await notifier.updateField(const MapEntry('Name', 'New name'));

      // editedJson stays null: `editedJson?.update` short-circuits entirely,
      // and copyWith is called with the same (still null) reference.
      expect(notifier.state.editedJson, isNull);
    });

    test(
      'BUG: adding a brand-new key adds it with a null value instead of the intended value '
      'because ifAbsent calls addEntries (which mutates the map and returns void) rather than '
      'returning the field value',
      () async {
        notifier.state = notifier.state.copyWith(
          editedJson: () => {'Name': 'Old name'},
        );

        // `Map.update`'s `ifAbsent` callback here calls `editedJson.addEntries({field})`,
        // which as a side effect inserts the key with the correct value, but
        // `addEntries` returns `void`. Since the value type is `dynamic`, that `void`
        // result is accepted and used as the "ifAbsent" value, so `update` then
        // overwrites the just-inserted entry with `null`.
        await notifier.updateField(const MapEntry('NewField', 'value'));

        expect(notifier.state.editedJson?.containsKey('NewField'), isTrue);
        expect(notifier.state.editedJson?['NewField'], isNull);
      },
    );
  });

  group('EditItemNotifier - resetChanged', () {
    test('resets editedJson back to the original json', () async {
      notifier.state = notifier.state.copyWith(
        json: () => {'Name': 'Original'},
        editedJson: () => {'Name': 'Changed'},
      );

      await notifier.resetChanged();

      expect(notifier.state.editedJson, {'Name': 'Original'});
    });

    test('resets editedJson to null when json is null', () async {
      notifier.state = notifier.state.copyWith(
        editedJson: () => {'Name': 'Changed'},
      );

      await notifier.resetChanged();

      expect(notifier.state.editedJson, isNull);
    });
  });

  group('EditItemNotifier - selectImage', () {
    final image1 = EditingImageModel(providerName: 'p1', url: 'url1');
    final image2 = EditingImageModel(providerName: 'p2', url: 'url2');

    test('primary: selecting a new image sets it as selected', () {
      notifier.selectImage(ImageType.primary, image1);

      expect(notifier.state.primary.selected, image1);
    });

    test('primary: selecting the already-selected image toggles it off (sets null)', () {
      notifier.selectImage(ImageType.primary, image1);
      expect(notifier.state.primary.selected, image1);

      notifier.selectImage(ImageType.primary, image1);

      expect(notifier.state.primary.selected, isNull);
    });

    test('logo: selecting a new image sets it as selected', () {
      notifier.selectImage(ImageType.logo, image1);

      expect(notifier.state.logo.selected, image1);
    });

    test('logo: selecting the already-selected image toggles it off (sets null)', () {
      notifier.selectImage(ImageType.logo, image1);
      expect(notifier.state.logo.selected, image1);

      notifier.selectImage(ImageType.logo, image1);

      expect(notifier.state.logo.selected, isNull);
    });

    test('backdrop: selecting a new image adds it to the selection list', () {
      notifier.selectImage(ImageType.backdrop, image1);

      expect(notifier.state.backdrop.selection, [image1]);
    });

    test('backdrop: selecting an already-selected image removes it from the selection list', () {
      notifier.selectImage(ImageType.backdrop, image1);
      notifier.selectImage(ImageType.backdrop, image2);
      expect(notifier.state.backdrop.selection, [image1, image2]);

      notifier.selectImage(ImageType.backdrop, image1);

      expect(notifier.state.backdrop.selection, [image2]);
    });

    test('backdrop: selecting null image returns early and leaves state unchanged', () {
      final stateBefore = notifier.state;

      notifier.selectImage(ImageType.backdrop, null);

      expect(notifier.state, same(stateBefore));
      expect(notifier.state.backdrop.selection, isEmpty);
    });

    test('backdrop is also the default branch for any non-primary/logo type', () {
      // ImageType only has primary/backdrop/logo/thumb/etc in the swagger enum;
      // `art` for example should fall into the default (backdrop-like) branch.
      notifier.selectImage(ImageType.art, image1);

      expect(notifier.state.backdrop.selection, [image1]);
    });
  });

  group('EditItemNotifier - setIncludeImages', () {
    test('sets includeAllImages to true', () {
      expect(notifier.state.includeAllImages, isFalse);

      notifier.setIncludeImages(true);

      expect(notifier.state.includeAllImages, isTrue);
    });

    test('sets includeAllImages to false', () {
      notifier.setIncludeImages(true);
      notifier.setIncludeImages(false);

      expect(notifier.state.includeAllImages, isFalse);
    });
  });

  group('EditItemNotifier - addCustomImages', () {
    final image1 = EditingImageModel(providerName: 'p1', url: 'url1');
    final image2 = EditingImageModel(providerName: 'p2', url: 'url2');

    test('primary: appends to customImages and selects the first of the new list', () {
      notifier.addCustomImages(ImageType.primary, [image1, image2]);

      expect(notifier.state.primary.customImages, [image1, image2]);
      expect(notifier.state.primary.selected, image1);
    });

    test('primary: appends to any existing customImages rather than replacing them', () {
      notifier.addCustomImages(ImageType.primary, [image1]);
      notifier.addCustomImages(ImageType.primary, [image2]);

      expect(notifier.state.primary.customImages, [image1, image2]);
      expect(notifier.state.primary.selected, image2);
    });

    test('logo: appends to customImages and selects the first of the new list', () {
      notifier.addCustomImages(ImageType.logo, [image1, image2]);

      expect(notifier.state.logo.customImages, [image1, image2]);
      expect(notifier.state.logo.selected, image1);
    });

    test('backdrop: appends to customImages and to the selection list (no "selected" field)', () {
      notifier.addCustomImages(ImageType.backdrop, [image1, image2]);

      expect(notifier.state.backdrop.customImages, [image1, image2]);
      expect(notifier.state.backdrop.selection, [image1, image2]);
      expect(notifier.state.backdrop.selected, isNull);
    });

    test('unhandled type (default branch) leaves state unchanged', () {
      final stateBefore = notifier.state;

      notifier.addCustomImages(ImageType.art, [image1]);

      expect(notifier.state, same(stateBefore));
      expect(notifier.state.primary.customImages, isEmpty);
      expect(notifier.state.logo.customImages, isEmpty);
      expect(notifier.state.backdrop.customImages, isEmpty);
    });

    test('empty list: customImages stays the same and selected becomes null (firstOrNull)', () {
      notifier.addCustomImages(ImageType.primary, [image1]);
      expect(notifier.state.primary.selected, image1);

      notifier.addCustomImages(ImageType.primary, <EditingImageModel>[]);

      expect(notifier.state.primary.customImages, [image1]);
      expect(notifier.state.primary.selected, isNull);
    });
  });

  group('EditItemNotifier - getFields / advancedFields', () {
    test('getFields returns an empty map when editedJson is null', () {
      expect(notifier.state.editedJson, isNull);

      expect(notifier.getFields, <String, dynamic>{});
    });

    test('advancedFields returns an empty map when editedJson is null', () {
      expect(notifier.state.editedJson, isNull);

      expect(notifier.advancedFields, <String, dynamic>{});
    });

    test('getFields delegates to editAbleFields and picks up simple string/int fields', () {
      notifier.state = notifier.state.copyWith(
        editedJson: () => {
          'Name': 'My Movie',
          'ProductionYear': 2020,
          'Overview': 'A movie about things.',
        },
      );

      final fields = notifier.getFields;

      expect(fields?['Name'], 'My Movie');
      expect(fields?['ProductionYear'], 2020);
      expect(fields?['Overview'], 'A movie about things.');
      // Null-valued keys (OriginalTitle, PremiereDate, DateCreated, Path) are removed.
      expect(fields?.containsKey('OriginalTitle'), isFalse);
    });

    test('advancedFields delegates to editAdvancedAbleFields when item is not a SeriesModel', () {
      notifier.state = notifier.state.copyWith(
        editedJson: () => {
          'CommunityRating': 7.5,
          'IndexNumber': 3,
          'Genres': ['Action', 'Comedy'],
        },
      );

      final fields = notifier.advancedFields;

      expect(fields?['CommunityRating'], 7.5);
      expect(fields?['IndexNumber'], 3);
      expect(fields?['Genres'], ['Action', 'Comedy']);
      // item is null (not a SeriesModel), so series-only keys are absent.
      expect(fields?.containsKey('DisplayOrder'), isFalse);
      expect(fields?.containsKey('Status'), isFalse);
    });
  });
}
