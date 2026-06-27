import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/item_base_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/settings/home_settings_provider.dart';

/// A container (collection/boxset/folder/library) the user pinned to the home
/// screen, paired with its child items so it can render as a dashboard row.
class HomeCollection {
  final ItemBaseModel container;
  final List<ItemBaseModel> items;
  const HomeCollection({required this.container, required this.items});

  String get name => container.name;
}

/// Resolves the containers the user pinned via the "Add to homepage" action,
/// each populated with its children, preserving pin order. Works for any
/// browsable container type (boxset, folder, collection folder, library view).
final homeCollectionsProvider = FutureProvider.autoDispose<List<HomeCollection>>((ref) async {
  final pinnedIds = ref.watch(homeSettingsProvider.select((value) => value.pinnedCollectionIds));
  if (pinnedIds.isEmpty) return [];

  final api = ref.read(jellyApiProvider);

  final resolved = await Future.wait(pinnedIds.map((id) async {
    try {
      final containerResponse = await api.usersUserIdItemsItemIdGet(itemId: id);
      final container = containerResponse.body;
      if (container == null) return null;

      final itemsResponse = await api.usersUserIdItemsGet(parentId: id, limit: 24);
      final items = (itemsResponse.body?.items ?? []).map((e) => ItemBaseModel.fromBaseDto(e, ref)).toList();

      return HomeCollection(container: container, items: items);
    } catch (_) {
      return null;
    }
  }));

  return resolved.nonNulls.toList();
});
