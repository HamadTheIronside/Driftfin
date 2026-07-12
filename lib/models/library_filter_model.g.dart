// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_filter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibraryFilterModel _$LibraryFilterModelFromJson(Map<String, dynamic> json) => _LibraryFilterModel(
      genres: (json['genres'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      itemFilters: (json['itemFilters'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry($enumDecode(_$ItemFilterEnumMap, k), e as bool),
          ) ??
          const {ItemFilter.isplayed: false, ItemFilter.isunplayed: false, ItemFilter.isresumable: false},
      studios: json['studios'] == null ? const {} : const StudioEncoder().fromJson(json['studios'] as String),
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      years: (json['years'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), e as bool),
          ) ??
          const {},
      officialRatings: (json['officialRatings'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      types: (json['types'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry($enumDecode(_$DriftfinItemTypeEnumMap, k), e as bool),
          ) ??
          const {
            DriftfinItemType.audio: false,
            DriftfinItemType.boxset: false,
            DriftfinItemType.book: false,
            DriftfinItemType.collectionFolder: false,
            DriftfinItemType.episode: false,
            DriftfinItemType.folder: false,
            DriftfinItemType.movie: false,
            DriftfinItemType.musicAlbum: false,
            DriftfinItemType.musicVideo: false,
            DriftfinItemType.photo: false,
            DriftfinItemType.person: false,
            DriftfinItemType.photoAlbum: false,
            DriftfinItemType.series: false,
            DriftfinItemType.video: false
          },
      sortingOption: $enumDecodeNullable(_$SortingOptionsEnumMap, json['sortingOption']) ?? SortingOptions.sortName,
      sortOrder: $enumDecodeNullable(_$SortingOrderEnumMap, json['sortOrder']) ?? SortingOrder.ascending,
      favourites: json['favourites'] as bool? ?? false,
      hideEmptyShows: json['hideEmptyShows'] as bool? ?? true,
      recursive: json['recursive'] as bool? ?? true,
      groupBy: $enumDecodeNullable(_$GroupByEnumMap, json['groupBy']) ?? GroupBy.none,
    );

Map<String, dynamic> _$LibraryFilterModelToJson(_LibraryFilterModel instance) => <String, dynamic>{
      'genres': instance.genres,
      'itemFilters': instance.itemFilters.map((k, e) => MapEntry(_$ItemFilterEnumMap[k], e)),
      'studios': const StudioEncoder().toJson(instance.studios),
      'tags': instance.tags,
      'years': instance.years.map((k, e) => MapEntry(k.toString(), e)),
      'officialRatings': instance.officialRatings,
      'types': instance.types.map((k, e) => MapEntry(_$DriftfinItemTypeEnumMap[k]!, e)),
      'sortingOption': _$SortingOptionsEnumMap[instance.sortingOption]!,
      'sortOrder': _$SortingOrderEnumMap[instance.sortOrder]!,
      'favourites': instance.favourites,
      'hideEmptyShows': instance.hideEmptyShows,
      'recursive': instance.recursive,
      'groupBy': _$GroupByEnumMap[instance.groupBy]!,
    };

const _$ItemFilterEnumMap = {
  ItemFilter.swaggerGeneratedUnknown: null,
  ItemFilter.isfolder: 'IsFolder',
  ItemFilter.isnotfolder: 'IsNotFolder',
  ItemFilter.isunplayed: 'IsUnplayed',
  ItemFilter.isplayed: 'IsPlayed',
  ItemFilter.isfavorite: 'IsFavorite',
  ItemFilter.isresumable: 'IsResumable',
  ItemFilter.likes: 'Likes',
  ItemFilter.dislikes: 'Dislikes',
  ItemFilter.isfavoriteorlikes: 'IsFavoriteOrLikes',
};

const _$DriftfinItemTypeEnumMap = {
  DriftfinItemType.baseType: 'baseType',
  DriftfinItemType.audio: 'audio',
  DriftfinItemType.musicAlbum: 'musicAlbum',
  DriftfinItemType.musicArtist: 'musicArtist',
  DriftfinItemType.musicVideo: 'musicVideo',
  DriftfinItemType.collectionFolder: 'collectionFolder',
  DriftfinItemType.video: 'video',
  DriftfinItemType.movie: 'movie',
  DriftfinItemType.series: 'series',
  DriftfinItemType.season: 'season',
  DriftfinItemType.episode: 'episode',
  DriftfinItemType.photo: 'photo',
  DriftfinItemType.person: 'person',
  DriftfinItemType.photoAlbum: 'photoAlbum',
  DriftfinItemType.folder: 'folder',
  DriftfinItemType.boxset: 'boxset',
  DriftfinItemType.playlist: 'playlist',
  DriftfinItemType.book: 'book',
  DriftfinItemType.tvchannel: 'tvchannel',
};

const _$SortingOptionsEnumMap = {
  SortingOptions.sortName: 'sortName',
  SortingOptions.communityRating: 'communityRating',
  SortingOptions.parentalRating: 'parentalRating',
  SortingOptions.dateAdded: 'dateAdded',
  SortingOptions.dateLastContentAdded: 'dateLastContentAdded',
  SortingOptions.favorite: 'favorite',
  SortingOptions.datePlayed: 'datePlayed',
  SortingOptions.folders: 'folders',
  SortingOptions.playCount: 'playCount',
  SortingOptions.releaseDate: 'releaseDate',
  SortingOptions.runTime: 'runTime',
  SortingOptions.random: 'random',
};

const _$SortingOrderEnumMap = {
  SortingOrder.ascending: 'ascending',
  SortingOrder.descending: 'descending',
};

const _$GroupByEnumMap = {
  GroupBy.none: 'none',
  GroupBy.name: 'name',
  GroupBy.genres: 'genres',
  GroupBy.dateAdded: 'dateAdded',
  GroupBy.tags: 'tags',
  GroupBy.releaseDate: 'releaseDate',
  GroupBy.rating: 'rating',
  GroupBy.type: 'type',
};
