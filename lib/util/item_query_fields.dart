import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';

/// Canonical field set for item queries that feed posters/cards. Centralised so
/// every poster surface returns the same data (notably MediaStreams, which the
/// quality/HDR badges need) — preventing the "some cards have badges, some
/// don't" inconsistency.
const List<ItemFields> posterItemFields = [
  ItemFields.parentid,
  ItemFields.primaryimageaspectratio,
  ItemFields.overview,
  ItemFields.mediastreams,
  ItemFields.mediasources,
  ItemFields.candelete,
  ItemFields.candownload,
];
