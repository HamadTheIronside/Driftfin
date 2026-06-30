import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transient subtitle timing offset applied to the active player.
///
/// Positive values delay the subtitles (show them later), negative values
/// show them earlier. This is a per-session sync adjustment and is
/// intentionally NOT persisted: it is re-applied to the player whenever it
/// changes and on every new video load, and reset via the subtitle controls.
final subtitleDelayProvider = StateProvider<Duration>((ref) => Duration.zero);
