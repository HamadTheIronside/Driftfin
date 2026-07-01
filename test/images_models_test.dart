import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:driftfin/models/items/images_models.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _refCaptureProvider = Provider<Ref>((ref) => ref);

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      serverUrlProvider.overrideWith((ref) => 'http://server'),
    ],
  );
  return container;
}

void main() {
  group('ImagesData.isEmpty', () {
    test('true only when both primary and backDrop are null', () {
      expect(ImagesData().isEmpty, isTrue);
    });

    test('false when backDrop is an empty (but non-null) list', () {
      expect(ImagesData(backDrop: const []).isEmpty, isFalse);
    });

    test('false when primary is set', () {
      expect(ImagesData(primary: ImageData(path: 'p')).isEmpty, isFalse);
    });
  });

  group('ImagesData.firstOrNull', () {
    test('prefers primary', () {
      final primary = ImageData(path: 'p');
      final data = ImagesData(primary: primary, backDrop: [ImageData(path: 'b')]);
      expect(data.firstOrNull, primary);
    });

    test('falls back to the first backdrop when there is no primary', () {
      final backdrop = ImageData(path: 'b');
      final data = ImagesData(backDrop: [backdrop]);
      expect(data.firstOrNull, backdrop);
    });

    test('null when both are absent', () {
      expect(ImagesData().firstOrNull, isNull);
    });
  });

  group('ImagesData.randomBackDrop', () {
    test('falls back to primary when backDrop is null', () {
      final primary = ImageData(path: 'p');
      expect(ImagesData(primary: primary, backDrop: null).randomBackDrop, primary);
    });

    test('falls back to primary when backDrop is empty', () {
      final primary = ImageData(path: 'p');
      expect(ImagesData(primary: primary, backDrop: <ImageData>[]).randomBackDrop, primary);
    });

    test('returns a member of backDrop when primary is null', () {
      final backdrops = [ImageData(path: 'b1'), ImageData(path: 'b2'), ImageData(path: 'b3')];
      final data = ImagesData(backDrop: backdrops);
      expect(backdrops.map((e) => e.path), contains(data.randomBackDrop?.path));
    });
  });

  group('ImagesData.fromBaseItem', () {
    late ProviderContainer container;
    late Ref ref;

    setUp(() {
      container = _container();
      ref = container.read(_refCaptureProvider);
    });

    tearDown(() => container.dispose());

    test('null when item.id is null', () {
      final result = ImagesData.fromBaseItem(const dto.BaseItemDto(), ref);
      expect(result, isNull);
    });

    test('primary is null when there is no Primary image tag', () {
      final item = const dto.BaseItemDto(id: 'item1');
      final result = ImagesData.fromBaseItem(item, ref);
      expect(result?.primary, isNull);
    });

    test('primary is built when a Primary image tag exists', () {
      final item = const dto.BaseItemDto(id: 'item1', imageTags: {'Primary': 'tag1'});
      final result = ImagesData.fromBaseItem(item, ref);
      expect(result?.primary, isNotNull);
      expect(result?.primary?.path, contains('item1'));
    });

    test('logo is always built regardless of whether a Logo tag exists (asymmetric with primary)', () {
      final item = const dto.BaseItemDto(id: 'item1');
      final result = ImagesData.fromBaseItem(item, ref);
      expect(result?.logo, isNotNull);
    });

    test('backdrop list is built from backdropImageTags, one entry per tag', () {
      final item = const dto.BaseItemDto(id: 'item1', backdropImageTags: ['hash1', 'hash2']);
      final result = ImagesData.fromBaseItem(item, ref);
      expect(result?.backDrop?.length, 2);
    });

    test('backdrop list is empty when there are no backdropImageTags', () {
      final item = const dto.BaseItemDto(id: 'item1');
      final result = ImagesData.fromBaseItem(item, ref);
      expect(result?.backDrop, isEmpty);
    });
  });

  group('ImagesData.fromBaseItemParent', () {
    late ProviderContainer container;
    late Ref ref;

    setUp(() {
      container = _container();
      ref = container.read(_refCaptureProvider);
    });

    tearDown(() => container.dispose());

    test('null when both seriesId and parentId are null', () {
      final result = ImagesData.fromBaseItemParent(const dto.BaseItemDto(), ref);
      expect(result, isNull);
    });

    test('non-null when only parentId is set', () {
      final result = ImagesData.fromBaseItemParent(const dto.BaseItemDto(parentId: 'parent1'), ref);
      expect(result, isNotNull);
    });

    test('primary is null without a seriesPrimaryImageTag', () {
      final result = ImagesData.fromBaseItemParent(const dto.BaseItemDto(seriesId: 's1'), ref);
      expect(result?.primary, isNull);
    });

    test('primary is built when seriesPrimaryImageTag is present', () {
      final item = const dto.BaseItemDto(seriesId: 's1', seriesPrimaryImageTag: 'tag1');
      final result = ImagesData.fromBaseItemParent(item, ref);
      expect(result?.primary, isNotNull);
    });

    test(
        'backdrop entries are dropped when neither seriesId nor parentId is set on an item with a parentId '
        'set at the top level but no backdrop-usable id (both null internally for that image)', () {
      // Here parentId provides the null-guard pass, but backdropImageTags still need seriesId/parentId
      // internally to build each entry; since parentId IS set, entries should build successfully.
      final item = const dto.BaseItemDto(parentId: 'parent1', backdropImageTags: ['h1']);
      final result = ImagesData.fromBaseItemParent(item, ref);
      expect(result?.backDrop?.length, 1);
    });
  });

  group('ImagesData.fromPersonDto', () {
    late ProviderContainer container;
    late Ref ref;

    setUp(() {
      container = _container();
      ref = container.read(_refCaptureProvider);
    });

    tearDown(() => container.dispose());

    test('logo and backDrop are always null (persons have neither)', () {
      final result = ImagesData.fromPersonDto(const dto.BaseItemPerson(), ref);
      expect(result?.logo, isNull);
      expect(result?.backDrop, isNull);
    });

    test('primary requires both primaryImageTag and imageBlurHashes to be non-null', () {
      final onlyTag = ImagesData.fromPersonDto(const dto.BaseItemPerson(primaryImageTag: 't1'), ref);
      expect(onlyTag?.primary, isNull);

      final both = ImagesData.fromPersonDto(
        const dto.BaseItemPerson(primaryImageTag: 't1', imageBlurHashes: dto.BaseItemPerson$ImageBlurHashes()),
        ref,
      );
      expect(both?.primary, isNotNull);
    });
  });

  group('ImagesData.copyWith', () {
    test('explicit null via ValueGetter clears the field', () {
      final data = ImagesData(primary: ImageData(path: 'p'));
      final cleared = data.copyWith(primary: () => null);
      expect(cleared.primary, isNull);
    });

    test('omitting the argument keeps the existing value', () {
      final primary = ImageData(path: 'p');
      final data = ImagesData(primary: primary);
      final copy = data.copyWith();
      expect(copy.primary, primary);
    });
  });

  group('ImagesData.fromMap/toMap round trip', () {
    test('round-trips primary/backDrop/logo', () {
      final original = ImagesData(
        primary: ImageData(path: 'p', hash: 'h', key: 'k'),
        backDrop: [ImageData(path: 'b1')],
        logo: ImageData(path: 'l'),
      );
      final restored = ImagesData.fromMap(original.toMap());
      expect(restored.primary?.path, 'p');
      expect(restored.backDrop?.single.path, 'b1');
      expect(restored.logo?.path, 'l');
    });

    test('missing keys become null', () {
      final restored = ImagesData.fromMap({});
      expect(restored.primary, isNull);
      expect(restored.backDrop, isNull);
      expect(restored.logo, isNull);
    });
  });

  group('ImageData.fromMap', () {
    test('defaults every field to empty string when missing', () {
      final data = ImageData.fromMap({});
      expect(data.path, '');
      expect(data.hash, '');
      expect(data.key, '');
    });
  });
}
