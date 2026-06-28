/// A tiny in-memory cache with per-entry TTL and a bounded size, so repeated
/// requests for the same data reuse a recent result instead of re-fetching.
/// The clock is injectable for testing.
class TimedCache<K, V> {
  TimedCache({required this.ttl, this.maxEntries = 64, DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _now;
  final Map<K, _CacheEntry<V>> _entries = {};

  /// Returns the cached value if present and not expired, else null (and drops
  /// the expired entry).
  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (!_now().isBefore(entry.expiry)) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  void set(K key, V value) {
    // Simple FIFO eviction once full (insertion order is preserved by Map).
    if (_entries.length >= maxEntries && !_entries.containsKey(key)) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = _CacheEntry(value, _now().add(ttl));
  }

  /// Returns the cached value or computes, stores, and returns it.
  Future<V> getOrFetch(K key, Future<V> Function() fetch) async {
    final cached = get(key);
    if (cached != null) return cached;
    final value = await fetch();
    set(key, value);
    return value;
  }

  void remove(K key) => _entries.remove(key);
  void clear() => _entries.clear();
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiry;
  _CacheEntry(this.value, this.expiry);
}
