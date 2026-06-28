import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/timed_cache.dart';

void main() {
  group('TimedCache', () {
    test('returns stored value before expiry, null after', () {
      var now = DateTime(2026);
      final cache = TimedCache<String, int>(ttl: const Duration(minutes: 5), clock: () => now);
      cache.set('a', 1);
      expect(cache.get('a'), 1);
      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(cache.get('a'), 1);
      now = now.add(const Duration(seconds: 2)); // past ttl
      expect(cache.get('a'), isNull);
    });

    test('getOrFetch caches and does not re-fetch within ttl', () async {
      var now = DateTime(2026);
      var fetches = 0;
      final cache = TimedCache<String, int>(ttl: const Duration(minutes: 5), clock: () => now);
      Future<int> fetch() async {
        fetches++;
        return 42;
      }

      expect(await cache.getOrFetch('k', fetch), 42);
      expect(await cache.getOrFetch('k', fetch), 42);
      expect(fetches, 1); // second call served from cache

      now = now.add(const Duration(minutes: 6));
      expect(await cache.getOrFetch('k', fetch), 42);
      expect(fetches, 2); // expired -> re-fetched
    });

    test('evicts oldest entry when full', () {
      final cache = TimedCache<int, int>(ttl: const Duration(hours: 1), maxEntries: 2);
      cache.set(1, 1);
      cache.set(2, 2);
      cache.set(3, 3); // evicts key 1
      expect(cache.get(1), isNull);
      expect(cache.get(2), 2);
      expect(cache.get(3), 3);
    });

    test('remove and clear', () {
      final cache = TimedCache<String, int>(ttl: const Duration(hours: 1));
      cache.set('a', 1);
      cache.set('b', 2);
      cache.remove('a');
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      cache.clear();
      expect(cache.get('b'), isNull);
    });
  });
}
