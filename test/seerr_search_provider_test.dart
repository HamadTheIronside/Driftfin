import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/seerr_search_provider.dart';
import 'package:driftfin/seerr/seerr_models.dart';

SeerrGenre _genre(int id, [String name = 'Genre']) => SeerrGenre(id: id, name: name);

SeerrWatchProvider _watchProvider(int id, [String name = 'Provider']) =>
    SeerrWatchProvider(providerId: id, providerName: name);

SeerrCertification _cert(String certification, {int order = 0}) =>
    SeerrCertification(certification: certification, meaning: certification, order: order);

void main() {
  group('SeerrSearchModel.canLoadMore', () {
    test('false while loading', () {
      final model = SeerrSearchModel(isLoading: true, currentPage: 1, totalPages: 3);
      expect(model.canLoadMore, false);
    });

    test('false while loading more', () {
      final model = SeerrSearchModel(isLoadingMore: true, currentPage: 1, totalPages: 3);
      expect(model.canLoadMore, false);
    });

    test('false when totalPages is null', () {
      final model = SeerrSearchModel(currentPage: 1);
      expect(model.canLoadMore, false);
    });

    test('false when currentPage reached totalPages', () {
      final model = SeerrSearchModel(currentPage: 3, totalPages: 3);
      expect(model.canLoadMore, false);
    });

    test('true when there are more pages and not loading', () {
      final model = SeerrSearchModel(currentPage: 1, totalPages: 3);
      expect(model.canLoadMore, true);
    });
  });

  group('SeerrSearchModel.hasFilters', () {
    test('false for default filters', () {
      final model = SeerrSearchModel();
      expect(model.hasFilters, false);
    });

    test('true when a genre is selected', () {
      final model = SeerrSearchModel(
        filters: SeerrFilterModel(genres: {_genre(1): true}),
      );
      expect(model.hasFilters, true);
    });

    test('true when a watch provider is selected', () {
      final model = SeerrSearchModel(
        filters: SeerrFilterModel(watchProviders: {_watchProvider(1): true}),
      );
      expect(model.hasFilters, true);
    });

    test('true when a certification is selected', () {
      final model = SeerrSearchModel(
        filters: SeerrFilterModel(certifications: {_cert('PG-13'): true}),
      );
      expect(model.hasFilters, true);
    });

    test('true when year range is set', () {
      expect(SeerrSearchModel(filters: const SeerrFilterModel(yearGte: 2000)).hasFilters, true);
      expect(SeerrSearchModel(filters: const SeerrFilterModel(yearLte: 2020)).hasFilters, true);
    });

    test('true when vote average range is set', () {
      expect(SeerrSearchModel(filters: const SeerrFilterModel(voteAverageGte: 5)).hasFilters, true);
      expect(SeerrSearchModel(filters: const SeerrFilterModel(voteAverageLte: 8)).hasFilters, true);
    });

    test('true when runtime range is set', () {
      expect(SeerrSearchModel(filters: const SeerrFilterModel(runtimeGte: 30)).hasFilters, true);
      expect(SeerrSearchModel(filters: const SeerrFilterModel(runtimeLte: 180)).hasFilters, true);
    });

    test('true when studio is set', () {
      final model = SeerrSearchModel(
        filters: SeerrFilterModel(studio: SeerrCompany(id: 1, name: 'Studio')),
      );
      expect(model.hasFilters, true);
    });

    test('false when filters exist but all disabled', () {
      final model = SeerrSearchModel(
        filters: SeerrFilterModel(
          genres: {_genre(1): false},
          watchProviders: {_watchProvider(1): false},
          certifications: {_cert('PG'): false},
        ),
      );
      expect(model.hasFilters, false);
    });
  });

  group('SeerrSearch notifier synchronous setters', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('setQuery updates the query', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setQuery('batman');
      expect(container.read(seerrSearchProvider).query, 'batman');
    });

    test('setGenres updates genres and filters.genres', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      final genres = {_genre(1): true};
      notifier.setGenres(genres);
      final state = container.read(seerrSearchProvider);
      expect(state.genres, genres);
      expect(state.filters.genres, genres);
    });

    test('setYearRangeWithoutSubmit updates filters year range', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setYearRangeWithoutSubmit(minYear: 1990, maxYear: 1999);
      final state = container.read(seerrSearchProvider);
      expect(state.filters.yearGte, 1990);
      expect(state.filters.yearLte, 1999);
    });

    test('setWatchProviders updates filters.watchProviders', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      final providers = {_watchProvider(2): true};
      notifier.setWatchProviders(providers);
      expect(container.read(seerrSearchProvider).filters.watchProviders, providers);
    });

    test('setCertifications updates filters.certifications', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      final certs = {_cert('R'): true};
      notifier.setCertifications(certs);
      expect(container.read(seerrSearchProvider).filters.certifications, certs);
    });

    test('setStudio updates filters.studio', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      final studio = SeerrCompany(id: 5, name: 'Studio 5');
      notifier.setStudio(studio);
      expect(container.read(seerrSearchProvider).filters.studio, studio);
      notifier.setStudio(null);
      expect(container.read(seerrSearchProvider).filters.studio, null);
    });

    test('setVoteAverageRange updates filters vote average range', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setVoteAverageRange(2.5, 9.0);
      final state = container.read(seerrSearchProvider);
      expect(state.filters.voteAverageGte, 2.5);
      expect(state.filters.voteAverageLte, 9.0);
    });

    test('setRuntimeRange updates filters runtime range', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setRuntimeRange(60, 120);
      final state = container.read(seerrSearchProvider);
      expect(state.filters.runtimeGte, 60);
      expect(state.filters.runtimeLte, 120);
    });

    test('setSortBy updates filters.sortBy', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setSortBy(SeerrSortBy.titleAsc);
      expect(container.read(seerrSearchProvider).filters.sortBy, SeerrSortBy.titleAsc);
    });

    test('clearFilters resets genres, watch providers, certifications and studio', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setGenres({_genre(1): true, _genre(2): false});
      notifier.setWatchProviders({_watchProvider(1): true});
      notifier.setCertifications({_cert('PG'): true});
      notifier.setStudio(SeerrCompany(id: 9, name: 'Studio'));

      notifier.clearFilters();

      final state = container.read(seerrSearchProvider);
      expect(state.genres.values.any((v) => v), false);
      expect(state.watchProviders.values.any((v) => v), false);
      expect(state.certifications.values.any((v) => v), false);
      expect(state.filters.studio, null);
      expect(state.hasFilters, false);
      // Keys are preserved, only values are cleared.
      expect(state.genres.keys, containsAll([_genre(1), _genre(2)]));
    });

    test('clearFilters preserves the current watch region', () {
      final notifier = container.read(seerrSearchProvider.notifier);
      notifier.setWatchRegionWithoutSubmit('DE');
      notifier.clearFilters();
      expect(container.read(seerrSearchProvider).filters.watchRegion, 'DE');
    });
  });
}
