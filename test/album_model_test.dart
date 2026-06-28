import 'package:driftfin/models/items/album_model.dart';
import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/models/items/overview_model.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel _album({
  String albumArtist = '',
  List<String> albumArtistIds = const [],
  List<String> artistIds = const [],
}) =>
    AlbumModel(
      albumArtist: albumArtist,
      albumArtistIds: albumArtistIds,
      artistIds: artistIds,
      name: 'Album',
      id: 'album-1',
      overview: const OverviewModel(),
      parentId: null,
      playlistId: null,
      images: null,
      childCount: null,
      primaryRatio: null,
      userData: const UserData(),
    );

void main() {
  group('AlbumModel.artistLabel', () {
    test('prefers the explicit album-artist name', () {
      expect(_album(albumArtist: 'Radiohead', artistIds: ['x']).artistLabel, 'Radiohead');
    });

    test('includes album-artist ids when present (regression: dropped label)', () {
      // Previously a dead statement discarded albumArtistIds, yielding an empty
      // or artist-id-only label. Both id sources must now contribute.
      expect(_album(albumArtistIds: ['aa1'], artistIds: ['a1']).artistLabel, 'aa1, a1');
    });

    test('falls back to album-artist ids alone', () {
      expect(_album(albumArtistIds: ['aa1', 'aa2']).artistLabel, 'aa1, aa2');
    });

    test('is empty when there is nothing to show', () {
      expect(_album().artistLabel, isEmpty);
    });
  });
}
