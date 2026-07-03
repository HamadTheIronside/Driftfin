import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/seerr/seerr_dashboard_model.dart';
import 'package:driftfin/providers/seerr_api_provider.dart';
import 'package:driftfin/providers/seerr_user_provider.dart';
import 'package:driftfin/seerr/seerr_models.dart';
import 'package:driftfin/util/timed_cache.dart';

/// One row in the requests manager: the request plus its resolved poster
/// (title/images/status), looked up once and cached.
class SeerrRequestEntry {
  final SeerrMediaRequest request;
  final SeerrDashboardPosterModel? poster;
  const SeerrRequestEntry(this.request, this.poster);
}

class SeerrRequestsState {
  final RequestFilter filter;
  final RequestSort sort;
  final SortDirection sortDirection;
  final bool mineOnly;
  final List<SeerrRequestEntry> entries;
  final int loadedPages;
  final int totalPages;
  final bool loading;
  final bool loadingMore;
  final bool processing;

  const SeerrRequestsState({
    this.filter = RequestFilter.all,
    this.sort = RequestSort.added,
    this.sortDirection = SortDirection.desc,
    this.mineOnly = false,
    this.entries = const [],
    this.loadedPages = 0,
    this.totalPages = 1,
    this.loading = false,
    this.loadingMore = false,
    this.processing = false,
  });

  bool get canLoadMore => loadedPages < totalPages;

  SeerrRequestsState copyWith({
    RequestFilter? filter,
    RequestSort? sort,
    SortDirection? sortDirection,
    bool? mineOnly,
    List<SeerrRequestEntry>? entries,
    int? loadedPages,
    int? totalPages,
    bool? loading,
    bool? loadingMore,
    bool? processing,
  }) =>
      SeerrRequestsState(
        filter: filter ?? this.filter,
        sort: sort ?? this.sort,
        sortDirection: sortDirection ?? this.sortDirection,
        mineOnly: mineOnly ?? this.mineOnly,
        entries: entries ?? this.entries,
        loadedPages: loadedPages ?? this.loadedPages,
        totalPages: totalPages ?? this.totalPages,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        processing: processing ?? this.processing,
      );
}

final seerrRequestsProvider = StateNotifierProvider.autoDispose<SeerrRequestsNotifier, SeerrRequestsState>((ref) {
  return SeerrRequestsNotifier(ref)..load();
});

class SeerrRequestsNotifier extends StateNotifier<SeerrRequestsState> {
  SeerrRequestsNotifier(this.ref) : super(const SeerrRequestsState());

  final Ref ref;
  static const int _pageSize = 20;

  // Incremented on every load() so a slow, stale response (e.g. from a filter
  // the user already switched away from) can be discarded instead of clobbering
  // the current results.
  int _loadGeneration = 0;

  // Posters are expensive (one lookup per request), so cache them across pages
  // and reloads to avoid re-hitting the server.
  static final TimedCache<String, SeerrDashboardPosterModel> _posterCache =
      TimedCache(ttl: const Duration(minutes: 10), maxEntries: 256);

  void setFilter(RequestFilter value) {
    if (value == state.filter) return;
    state = state.copyWith(filter: value);
    load();
  }

  void setSort(RequestSort value) {
    state = state.copyWith(sort: value);
    load();
  }

  void toggleSortDirection() {
    state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.desc ? SortDirection.asc : SortDirection.desc);
    load();
  }

  void setMineOnly(bool value) {
    if (value == state.mineOnly) return;
    state = state.copyWith(mineOnly: value);
    load();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(loading: true);
    final page = await _fetchPage(0);
    if (!mounted || generation != _loadGeneration) return;
    if (!page.ok) {
      state = state.copyWith(loading: false);
      return;
    }
    state = state.copyWith(
      entries: page.entries,
      totalPages: page.totalPages,
      loadedPages: 1,
      loading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.loading || !state.canLoadMore) return;
    final generation = _loadGeneration;
    state = state.copyWith(loadingMore: true);
    final page = await _fetchPage(state.loadedPages);
    if (!mounted || generation != _loadGeneration) return;
    if (!page.ok) {
      // Transient failure: keep loadedPages so we retry this same page next time.
      state = state.copyWith(loadingMore: false);
      return;
    }
    state = state.copyWith(
      entries: [...state.entries, ...page.entries],
      totalPages: page.totalPages,
      loadedPages: state.loadedPages + 1,
      loadingMore: false,
    );
  }

  Future<({List<SeerrRequestEntry> entries, int totalPages, bool ok})> _fetchPage(int page) async {
    final api = ref.read(seerrApiProvider);
    try {
      final currentUserId = ref.read(seerrUserProvider)?.id;
      final response = await api.listRequests(
        take: _pageSize,
        skip: page * _pageSize,
        filter: state.filter,
        sort: state.sort,
        sortDirection: state.sortDirection,
        requestedBy: state.mineOnly ? currentUserId : null,
      );
      final results = response.body?.results ?? const <SeerrMediaRequest>[];
      final totalPages = response.body?.pageInfo?.pages ?? 1;
      final entries =
          await Future.wait(results.map((request) async => SeerrRequestEntry(request, await _poster(request))));
      return (entries: entries, totalPages: totalPages, ok: true);
    } catch (_) {
      return (entries: const <SeerrRequestEntry>[], totalPages: state.totalPages, ok: false);
    }
  }

  Future<SeerrDashboardPosterModel?> _poster(SeerrMediaRequest request) async {
    final tmdbId = request.media?.tmdbId;
    final tvdbId = request.media?.tvdbId;
    if (tmdbId == null && tvdbId == null) return null;
    final key = '$tmdbId:$tvdbId';
    final cached = _posterCache.get(key);
    if (cached != null) return cached;
    final poster = await ref.read(seerrApiProvider).fetchDashboardPosterFromIds(tmdbId: tmdbId, tvdbId: tvdbId);
    if (poster != null) _posterCache.set(key, poster);
    return poster;
  }

  Future<void> approve(int requestId) async {
    await ref.read(seerrApiProvider).approveRequest(requestId: requestId);
    await load();
    _refreshPendingBadge();
  }

  /// Declines/removes a request (Seerr deletes the request for both).
  Future<void> decline(int requestId) async {
    await ref.read(seerrApiProvider).deleteRequest(requestId: requestId);
    await load();
    _refreshPendingBadge();
  }

  /// Recomputes the nav "Discover" pending badge after a request mutation so its
  /// count doesn't go stale until the screen is reopened.
  void _refreshPendingBadge() => ref.invalidate(pendingRequestsCountProvider);

  /// Bulk-approves every pending request currently loaded.
  Future<void> approveAllPending() async {
    final pendingIds = state.entries
        .where((e) => e.request.requestStatus == SeerrRequestStatus.pending)
        .map((e) => e.request.id)
        .whereType<int>()
        .toList();
    if (pendingIds.isEmpty) return;
    state = state.copyWith(processing: true);
    final api = ref.read(seerrApiProvider);
    for (final id in pendingIds) {
      try {
        await api.approveRequest(requestId: id);
      } catch (_) {/* best-effort */}
    }
    if (!mounted) return;
    state = state.copyWith(processing: false);
    await load();
    _refreshPendingBadge();
  }
}

/// Count of pending requests, for the nav badge. Refreshes when read.
final pendingRequestsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final response = await ref.read(seerrApiProvider).listRequests(filter: RequestFilter.pending, take: 1, skip: 0);
    return response.body?.pageInfo?.results ?? 0;
  } catch (_) {
    return 0;
  }
});
