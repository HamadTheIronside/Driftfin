import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:driftfin/models/playback/audio_prefetch_buffer.dart';
import 'package:driftfin/models/playback/audio_url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ItemBaseModel _item(String id) => ItemBaseModel(
      name: id,
      id: id,
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

/// A resolver whose [resolve] never touches its [Ref], recording calls and
/// returning a deterministic, controllable URL per item.
class _FakeAudioUrlResolver extends AudioUrlResolver {
  _FakeAudioUrlResolver(super.ref, {this.urlFor});

  final String Function(String id)? urlFor;
  final List<String> resolvedIds = [];

  @override
  Future<String> resolve(ItemBaseModel item) async {
    resolvedIds.add(item.id);
    return urlFor?.call(item.id) ?? 'url://${item.id}';
  }
}

_FakeAudioUrlResolver _resolver({String Function(String id)? urlFor}) {
  final container = ProviderContainer();
  final refProvider = Provider<Ref>((ref) => ref);
  final ref = container.read(refProvider);
  return _FakeAudioUrlResolver(ref, urlFor: urlFor);
}

void main() {
  group('AudioPrefetchBuffer.prefetch', () {
    test('resolves and caches each item once', () async {
      final buffer = AudioPrefetchBuffer();
      final resolver = _resolver();
      final items = [_item('a'), _item('b')];

      buffer.prefetch(items, resolver);

      expect(await buffer.getUrl('a'), 'url://a');
      expect(await buffer.getUrl('b'), 'url://b');
      expect(resolver.resolvedIds, ['a', 'b']);
    });

    test('does not re-resolve an already-cached item', () async {
      final buffer = AudioPrefetchBuffer();
      final resolver = _resolver();
      final items = [_item('a')];

      buffer.prefetch(items, resolver);
      buffer.prefetch(items, resolver);

      expect(resolver.resolvedIds, ['a'], reason: 'putIfAbsent must skip the second prefetch call');
    });

    test('only prefetches up to bufferSize items', () async {
      final buffer = AudioPrefetchBuffer(bufferSize: 2);
      final resolver = _resolver();
      final items = [_item('a'), _item('b'), _item('c')];

      buffer.prefetch(items, resolver);

      expect(resolver.resolvedIds, ['a', 'b']);
      expect(await buffer.getUrl('c'), isNull);
    });

    test('getUrl returns null for an unknown id', () async {
      final buffer = AudioPrefetchBuffer();
      expect(await buffer.getUrl('missing'), isNull);
    });

    test('invalidate clears the cache so subsequent prefetch re-resolves', () async {
      final buffer = AudioPrefetchBuffer();
      final resolver = _resolver();
      final items = [_item('a')];

      buffer.prefetch(items, resolver);
      buffer.invalidate();
      expect(await buffer.getUrl('a'), isNull);

      buffer.prefetch(items, resolver);
      expect(resolver.resolvedIds, ['a', 'a'], reason: 'after invalidate, prefetch must resolve again');
    });

    test('prefetch with an empty list is a no-op', () async {
      final buffer = AudioPrefetchBuffer();
      final resolver = _resolver();

      buffer.prefetch(const [], resolver);

      expect(resolver.resolvedIds, isEmpty);
    });
  });
}
