import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/boxset_model.dart';
import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/settings/home_settings_provider.dart';

/// Fetches the collections (boxsets) the user pinned to the dashboard via the
/// "Add to homepage" action, each populated with its items so the dashboard can
/// render them as [PosterRow]s. Returns them in the order they were pinned.
final homeCollectionsProvider = FutureProvider.autoDispose<List<BoxSetModel>>((ref) async {
  final pinnedIds = ref.watch(homeSettingsProvider.select((value) => value.pinnedCollectionIds));
  if (pinnedIds.isEmpty) return [];

  final api = ref.read(jellyApiProvider);

  final collectionsResponse = await api.usersUserIdItemsGet(
    recursive: true,
    includeItemTypes: [BaseItemKind.boxset],
  );

  final pinned = (collectionsResponse.body?.items ?? [])
      .map((e) => BoxSetModel.fromBaseDto(e, ref))
      .where((boxset) => pinnedIds.contains(boxset.id))
      .toList()
    ..sort((a, b) => pinnedIds.indexOf(a.id).compareTo(pinnedIds.indexOf(b.id)));

  return Future.wait(pinned.map((boxset) async {
    final itemsResponse = await api.usersUserIdItemsGet(
      parentId: boxset.id,
      limit: 24,
    );
    final items = (itemsResponse.body?.items ?? []).map((e) => ItemBaseModel.fromBaseDto(e, ref)).toList();
    return boxset.copyWith(items: items);
  }));
});
