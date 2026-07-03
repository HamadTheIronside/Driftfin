import 'package:auto_route/auto_route.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';

/// Stable id for every searchable/syncable setting. Values are persisted
/// nowhere (routes/keys are looked up by route path, not by this enum), so
/// renaming or reordering is safe — but removing one that
/// `syncedSettingIds` (see config_sync_provider.dart) still references would
/// be a compile error, which is the point: the two can't silently drift.
enum SettingId {
  // Client › Downloads
  downloadsPath,
  downloadsSyncedData,
  downloadsRequireWifi,
  downloadsVideoQuality,
  downloadsMusicQuality,
  downloadsMaxConcurrent,
  // Client › Lockscreen
  appLockTimeout,
  // Client › Shortcuts
  keyboardShortcuts,
  // Client › Dashboard
  homeBanner,
  homeBannerInformation,
  homeNextUp,
  showAllCollectionTypes,
  managePinnedCollections,
  // Client › Visual
  displayLanguage,
  blurredPlaceholders,
  blurEffects,
  blurUpcomingEpisodes,
  osMediaControls,
  tvExpandedLayout,
  backgroundPosters,
  usePostersForLibraryIcons,
  nextUpCutoffDays,
  libraryPageSize,
  posterSize,
  // Client › Theme
  themeMode,
  themeColor,
  schemeVariant,
  amoledBlack,
  deriveColorsFromItem,
  reduceAnimations,
  // Client › Controls
  mouseDragSupport,
  // Client › Advanced
  crashReporting,
  layoutSizes,
  layoutModes,
  useSystemIME,
  externalPlayerEnabled,
  externalPlayerPath,
  externalPlayerArgs,
  // Client › Advanced › Integrations
  sonarrIntegration,
  radarrIntegration,
  traktIntegration,
  // Player
  videoScalingFillScreen,
  pictureInPictureAuto,
  videoScaling,
  homeStreamingQuality,
  internetStreamingQuality,
  skipBackLength,
  skipForwardLength,
  doubleTapSeek,
  edgeGestures,
  reverseEdgeGestures,
  speedBoost,
  rememberAudioSelections,
  rememberSubtitleSelections,
  playerBackend,
  videoHWAccel,
  nativeLibassAccel,
  mediaTunneling,
  screensaver,
  customSubtitles,
  playPauseFade,
  bufferSize,
  autoNext,
  replayGain,
  replayGainLevel,
  smartDownmix,
  dialogueBoost,
  crossfade,
  advancedVideoOptions,
  orientation,
  // Profile & Security
  appLockEnabled,
  openAuthAtLaunch,
  password,
  subtitleLanguage,
  subtitleMode,
  updateCheckInterval,
  showNewItemNotification,
  includeHiddenItems,
  seerrIntegration,
  seerrRequestNotifications,
}

/// One row in the searchable-settings index: a [SettingId], its localized
/// label/synonyms, and the route that owns it. Search matches label or any
/// synonym case-insensitively; selecting a result navigates to [route].
class SettingsEntry {
  final SettingId id;
  final String Function(AppLocalizations l10n) label;
  final List<String> Function(AppLocalizations l10n)? synonyms;
  final PageRouteInfo Function() route;

  const SettingsEntry({
    required this.id,
    required this.label,
    this.synonyms,
    required this.route,
  });

  bool matches(String query, AppLocalizations l10n) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    if (label(l10n).toLowerCase().contains(trimmed)) return true;
    return (synonyms?.call(l10n) ?? const []).any((synonym) => synonym.toLowerCase().contains(trimmed));
  }
}
