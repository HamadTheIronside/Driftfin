import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/models/view_model.dart';
import 'package:driftfin/models/views_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/dashboard_provider.dart';
import 'package:driftfin/providers/service_provider.dart';
import 'package:driftfin/providers/tonight_provider.dart';
import 'package:driftfin/providers/views_provider.dart';
import 'package:driftfin/util/tonight_picker.dart';

Response<T> _ok<T>(T body) => Response<T>(http.Response('', 200), body);

/// Canned Jellyfin responses for [TonightNotifier.fetchTonightPicks], so its
/// fan-out logic can be exercised without a live server.
class _FakeTonightJellyService extends JellyService {
  _FakeTonightJellyService(
    Ref ref, {
    this.recommendations = const [],
    this.nextUp = const [],
    this.similarByItemId = const {},
  }) : super(ref, JellyfinOpenApi.create());

  final List<RecommendationDto> recommendations;
  final List<BaseItemDto> nextUp;
  final Map<String, List<BaseItemDto>> similarByItemId;

  int moviesRecommendationsCalls = 0;
  int showsNextUpCalls = 0;
  final List<String?> similarItemIdsRequested = [];

  @override
  Future<Response<List<RecommendationDto>>> moviesRecommendationsGet({
    String? parentId,
    List<ItemFields>? fields,
    int? categoryLimit,
    int? itemLimit,
  }) async {
    moviesRecommendationsCalls++;
    return _ok(recommendations);
  }

  @override
  Future<Response<BaseItemDtoQueryResult>> showsNextUpGet({
    int? startIndex,
    int? limit,
    String? parentId,
    DateTime? nextUpDateCutoff,
    List<ItemFields>? fields,
    bool? enableUserData,
    List<ImageType>? enableImageTypes,
    int? imageTypeLimit,
  }) async {
    showsNextUpCalls++;
    return _ok(BaseItemDtoQueryResult(items: nextUp, totalRecordCount: nextUp.length, startIndex: 0));
  }

  @override
  Future<Response<BaseItemDtoQueryResult>> itemsItemIdSimilarGet({String? itemId, int? limit}) async {
    similarItemIdsRequested.add(itemId);
    final items = similarByItemId[itemId] ?? const <BaseItemDto>[];
    return _ok(BaseItemDtoQueryResult(items: items, totalRecordCount: items.length, startIndex: 0));
  }
}

class _FakeJellyApi extends JellyApi {
  _FakeJellyApi({
    this.recommendations = const [],
    this.nextUp = const [],
    this.similarByItemId = const {},
  });

  final List<RecommendationDto> recommendations;
  final List<BaseItemDto> nextUp;
  final Map<String, List<BaseItemDto>> similarByItemId;

  late final _FakeTonightJellyService service;

  @override
  JellyService build() {
    service = _FakeTonightJellyService(
      ref,
      recommendations: recommendations,
      nextUp: nextUp,
      similarByItemId: similarByItemId,
    );
    return service;
  }
}

ViewModel _movieView() => ViewModel(
      name: 'Movies',
      id: 'movies-view',
      serverId: 'server',
      dateCreated: DateTime(2024),
      canDelete: false,
      canDownload: false,
      parentId: '',
      collectionType: CollectionType.movies,
      playAccess: PlayAccess.full,
      recentlyAdded: const [],
      imageData: null,
      childCount: 0,
      path: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith({
    _FakeJellyApi? fakeApi,
    List<ViewModel> dashboardViews = const [],
    List<BaseItemDto> resumeVideo = const [],
  }) {
    return ProviderContainer(
      overrides: [
        if (fakeApi != null) jellyApiProvider.overrideWith(() => fakeApi),
        viewsProvider.overrideWith((ref) => ViewsNotifier(ref)..state = ViewsModel(dashboardViews: dashboardViews)),
        dashboardProvider.overrideWith((ref) {
          final notifier = DashboardNotifier(ref);
          notifier.state = notifier.state.copyWith(
            resumeVideo: resumeVideo.map((e) => ItemBaseModel.fromBaseDto(e, ref)).toList(),
          );
          return notifier;
        }),
      ],
    );
  }

  test('fans out to recommendations, next-up and similar-item endpoints for a movies library', () async {
    final fakeApi = _FakeJellyApi(
      recommendations: [
        const RecommendationDto(baselineItemName: 'Because you liked X', items: [
          BaseItemDto(id: 'rec-1', name: 'Recommended Movie', type: BaseItemKind.movie, communityRating: 8),
        ]),
      ],
      nextUp: [const BaseItemDto(id: 'nextup-1', name: 'Next Up Episode', type: BaseItemKind.episode)],
    );
    final container = containerWith(fakeApi: fakeApi, dashboardViews: [_movieView()]);
    addTearDown(container.dispose);

    await container.read(tonightProvider.notifier).fetchTonightPicks(timeAvailable: const Duration(hours: 2));

    expect(fakeApi.service.moviesRecommendationsCalls, 1);
    expect(fakeApi.service.showsNextUpCalls, 1);
    final state = container.read(tonightProvider);
    expect(state.loading, isFalse);
    expect(state.picks.map((e) => e.id), containsAll(['rec-1', 'nextup-1']));
    expect(state.generatedAt, isNotNull);
    expect(state.timeAvailable, const Duration(hours: 2));
  });

  test('seeds similar-item lookups from up to 3 resume-video items', () async {
    final fakeApi = _FakeJellyApi(
      similarByItemId: {
        'resume-1': [const BaseItemDto(id: 'similar-1', name: 'Similar Movie', type: BaseItemKind.movie)],
      },
    );
    final container = containerWith(
      fakeApi: fakeApi,
      dashboardViews: [_movieView()],
      resumeVideo: [const BaseItemDto(id: 'resume-1', name: 'Resume Movie', type: BaseItemKind.movie)],
    );
    addTearDown(container.dispose);

    await container.read(tonightProvider.notifier).fetchTonightPicks();

    expect(fakeApi.service.similarItemIdsRequested, contains('resume-1'));
    final state = container.read(tonightProvider);
    expect(state.picks.map((e) => e.id), contains('similar-1'));
  });

  test('does not call the movies-recommendations endpoint when there is no movies library', () async {
    // No dashboard views at all means the api field is never even touched;
    // this should complete cleanly with no picks rather than throwing.
    final container = containerWith(dashboardViews: const []);
    addTearDown(container.dispose);

    await container.read(tonightProvider.notifier).fetchTonightPicks();

    expect(container.read(tonightProvider).picks, isEmpty);
    expect(container.read(tonightProvider).loading, isFalse);
  });

  test('is a no-op re-entrancy guard while already loading', () async {
    final fakeApi = _FakeJellyApi();
    final container = containerWith(fakeApi: fakeApi, dashboardViews: [_movieView()]);
    addTearDown(container.dispose);

    final notifier = container.read(tonightProvider.notifier);
    final first = notifier.fetchTonightPicks();
    final second = notifier.fetchTonightPicks();
    await Future.wait([first, second]);

    expect(fakeApi.service.moviesRecommendationsCalls, 1);
  });

  test('setTimeAvailable and setMood update state without fetching', () {
    final container = containerWith();
    addTearDown(container.dispose);
    final notifier = container.read(tonightProvider.notifier);

    notifier.setTimeAvailable(const Duration(minutes: 30));
    notifier.setMood(TonightMood.cozy);

    final state = container.read(tonightProvider);
    expect(state.timeAvailable, const Duration(minutes: 30));
    expect(state.mood, TonightMood.cozy);
  });

  test('clear resets to the default model', () {
    final container = containerWith();
    addTearDown(container.dispose);
    final notifier = container.read(tonightProvider.notifier);

    notifier.setMood(TonightMood.funny);
    notifier.clear();

    expect(container.read(tonightProvider).mood, TonightMood.any);
  });
}
