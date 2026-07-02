import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/settings/settings_entry.dart';
import 'package:driftfin/routes/auto_router.gr.dart';

/// The searchable-settings index: one [SettingsEntry] per setting the app
/// exposes today. Adding a new setting elsewhere means adding a row here —
/// nothing else discovers entries automatically (see issue #50 Phase 1).
List<SettingsEntry> buildSettingsRegistry() {
  return [
    // Downloads & Offline
    SettingsEntry(
      id: SettingId.downloadsPath,
      label: (l10n) => l10n.downloadsPath,
      route: () => const DownloadsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.downloadsSyncedData,
      label: (l10n) => l10n.downloadsSyncedData,
      route: () => const DownloadsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.downloadsRequireWifi,
      label: (l10n) => l10n.clientSettingsRequireWifiTitle,
      synonyms: (l10n) => [l10n.clientSettingsRequireWifiDesc, 'wifi'],
      route: () => const DownloadsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.downloadsVideoQuality,
      label: (l10n) => l10n.downloadsVideoQualityTitle,
      synonyms: (_) => ['downloads', 'video quality', 'transcode'],
      route: () => const DownloadsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.downloadsMusicQuality,
      label: (l10n) => l10n.downloadsMusicQualityTitle,
      synonyms: (_) => ['downloads', 'audio quality', 'transcode'],
      route: () => const DownloadsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.downloadsMaxConcurrent,
      label: (l10n) => l10n.maxConcurrentDownloadsTitle,
      synonyms: (l10n) => [l10n.maxConcurrentDownloadsDesc],
      route: () => const DownloadsSettingsRoute(),
    ),
    // Account & Device › Device
    SettingsEntry(
      id: SettingId.appLockTimeout,
      label: (l10n) => l10n.timeOut,
      synonyms: (_) => ['lockscreen', 'app lock'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.keyboardShortcuts,
      label: (l10n) => l10n.shortCuts,
      synonyms: (_) => ['keyboard', 'hotkeys'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    // Home & Library
    SettingsEntry(
      id: SettingId.homeBanner,
      label: (l10n) => l10n.settingsHomeBannerTitle,
      synonyms: (l10n) => [l10n.settingsHomeBannerDescription, l10n.dashboard],
      route: () => const HomeLibrarySettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.homeBannerInformation,
      label: (l10n) => l10n.settingsHomeBannerInformationTitle,
      synonyms: (l10n) => [l10n.settingsHomeBannerInformationDesc],
      route: () => const HomeLibrarySettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.homeNextUp,
      label: (l10n) => l10n.settingsHomeNextUpTitle,
      synonyms: (l10n) => [l10n.settingsHomeNextUpDesc],
      route: () => const HomeLibrarySettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.showAllCollectionTypes,
      label: (l10n) => l10n.clientSettingsShowAllCollectionsTitle,
      synonyms: (l10n) => [l10n.clientSettingsShowAllCollectionsDesc, l10n.dashboard],
      route: () => const HomeLibrarySettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.managePinnedCollections,
      label: (l10n) => l10n.managePinnedCollections,
      synonyms: (l10n) => [l10n.managePinnedCollectionsDesc],
      route: () => const HomeLibrarySettingsRoute(),
    ),
    // Appearance (Theme + Visual)
    SettingsEntry(
      id: SettingId.displayLanguage,
      label: (l10n) => l10n.displayLanguage,
      synonyms: (_) => ['locale', 'language'],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.blurredPlaceholders,
      label: (l10n) => l10n.settingsBlurredPlaceholderTitle,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.blurEffects,
      label: (l10n) => l10n.settingsBlurEffectsTitle,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.blurUpcomingEpisodes,
      label: (l10n) => l10n.settingsBlurEpisodesTitle,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.osMediaControls,
      label: (l10n) => l10n.settingsEnableOsMediaControls,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.tvExpandedLayout,
      label: (l10n) => l10n.enableNewTVLayout,
      synonyms: (_) => ['tv'],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.backgroundPosters,
      label: (l10n) => l10n.enableBackgroundPostersTitle,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.usePostersForLibraryIcons,
      label: (l10n) => l10n.usePostersForLibraryIconsTitle,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.nextUpCutoffDays,
      label: (l10n) => l10n.settingsNextUpCutoffDays,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.libraryPageSize,
      label: (l10n) => l10n.libraryPageSizeTitle,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.posterSize,
      label: (l10n) => l10n.settingsPosterSize,
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.themeMode,
      label: (l10n) => '${l10n.theme} ${l10n.mode}',
      synonyms: (_) => ['dark mode', 'light mode', 'system theme'],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.themeColor,
      label: (l10n) => '${l10n.theme} ${l10n.color}',
      synonyms: (_) => ['accent color'],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.schemeVariant,
      label: (l10n) => l10n.clientSettingsSchemeVariantTitle,
      synonyms: (_) => ['material you', 'dynamic color'],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.amoledBlack,
      label: (l10n) => l10n.amoledBlack,
      synonyms: (_) => ['oled', 'pure black'],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.deriveColorsFromItem,
      label: (l10n) => l10n.itemColorsTitle,
      synonyms: (l10n) => [l10n.itemColorsDesc],
      route: () => const AppearanceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.reduceAnimations,
      label: (l10n) => l10n.reduceAnimationsTitle,
      synonyms: (l10n) => [l10n.reduceAnimationsDesc, 'low end', 'performance'],
      route: () => const AppearanceSettingsRoute(),
    ),
    // Account & Device › Device (Controls, Advanced)
    SettingsEntry(
      id: SettingId.mouseDragSupport,
      label: (l10n) => l10n.mouseDragSupport,
      synonyms: (_) => ['mouse', 'controls'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.layoutSizes,
      label: (l10n) => l10n.settingsLayoutSizesTitle,
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.layoutModes,
      label: (l10n) => l10n.settingsLayoutModesTitle,
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.useSystemIME,
      label: (l10n) => l10n.clientSettingsUseSystemIMETitle,
      synonyms: (_) => ['keyboard input', 'tv'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    // Account & Device › Sync & Backup
    SettingsEntry(
      id: SettingId.syncSettingsToServer,
      label: (l10n) => l10n.syncSettingsTitle,
      synonyms: (l10n) => [l10n.syncSettingsDesc],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.crashReporting,
      label: (l10n) => l10n.crashReportingTitle,
      synonyms: (_) => ['sentry', 'crash reports'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    // Playback › Advanced (external player)
    SettingsEntry(
      id: SettingId.externalPlayerEnabled,
      label: (l10n) => l10n.externalPlayerTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.externalPlayerPath,
      label: (l10n) => l10n.externalPlayerPath,
      synonyms: (_) => ['external player'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.externalPlayerArgs,
      label: (l10n) => l10n.externalPlayerArgs,
      synonyms: (_) => ['external player'],
      route: () => const PlayerSettingsRoute(),
    ),
    // Integrations
    SettingsEntry(
      id: SettingId.sonarrIntegration,
      label: (l10n) => l10n.sonarrIntegrationTitle,
      synonyms: (_) => ['integrations', 'tv shows'],
      route: () => const IntegrationsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.radarrIntegration,
      label: (l10n) => l10n.radarrIntegrationTitle,
      synonyms: (_) => ['integrations', 'movies'],
      route: () => const IntegrationsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.traktIntegration,
      label: (l10n) => l10n.traktTitle,
      synonyms: (_) => ['integrations', 'scrobble'],
      route: () => const IntegrationsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.seerrIntegration,
      label: (l10n) => l10n.seerr,
      synonyms: (_) => ['jellyseerr', 'overseerr', 'requests', 'integrations'],
      route: () => const IntegrationsSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.seerrRequestNotifications,
      label: (l10n) => l10n.seerrRequestNotifications,
      route: () => const IntegrationsSettingsRoute(),
    ),
    // Playback (Primary)
    SettingsEntry(
      id: SettingId.videoScalingFillScreen,
      label: (l10n) => l10n.videoScalingFillScreenTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.pictureInPictureAuto,
      label: (l10n) => l10n.pictureInPictureAutoTitle,
      synonyms: (_) => ['pip'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.videoScaling,
      label: (l10n) => l10n.videoScaling,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.homeStreamingQuality,
      label: (l10n) => l10n.homeStreamingQualityTitle,
      synonyms: (_) => ['wifi', 'bitrate'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.internetStreamingQuality,
      label: (l10n) => l10n.internetStreamingQualityTitle,
      synonyms: (_) => ['cellular', 'mobile data', 'bitrate'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.skipBackLength,
      label: (l10n) => l10n.skipBackLength,
      synonyms: (_) => ['rewind'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.skipForwardLength,
      label: (l10n) => l10n.skipForwardLength,
      synonyms: (_) => ['fast forward'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.doubleTapSeek,
      label: (l10n) => l10n.enableDoubleTapSeekTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.edgeGestures,
      label: (l10n) => l10n.enableEdgeGesturesTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.reverseEdgeGestures,
      label: (l10n) => l10n.reverseEdgeGesturesTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.speedBoost,
      label: (l10n) => l10n.enableSpeedBoostTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.rememberAudioSelections,
      label: (l10n) => l10n.rememberAudioSelections,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.rememberSubtitleSelections,
      label: (l10n) => l10n.rememberSubtitleSelections,
      route: () => const PlayerSettingsRoute(),
    ),
    // Playback › Advanced
    SettingsEntry(
      id: SettingId.playerBackend,
      label: (l10n) => l10n.playerSettingsBackendTitle,
      synonyms: (_) => ['mpv', 'mdk', 'video engine'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.videoHWAccel,
      label: (l10n) => l10n.settingsPlayerVideoHWAccelTitle,
      synonyms: (_) => ['hardware acceleration'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.nativeLibassAccel,
      label: (l10n) => l10n.settingsPlayerNativeLibassAccelTitle,
      synonyms: (_) => ['subtitles rendering'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.mediaTunneling,
      label: (l10n) => l10n.mediaTunnelingTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.screensaver,
      label: (l10n) => l10n.playerSettingsScreensaverTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.customSubtitles,
      label: (l10n) => l10n.settingsPlayerCustomSubtitlesTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.playPauseFade,
      label: (l10n) => l10n.settingsPlayerPlayPauseFadeTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.bufferSize,
      label: (l10n) => l10n.settingsPlayerBufferSizeTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.autoNext,
      label: (l10n) => l10n.settingsAutoNextTitle,
      synonyms: (_) => ['auto play', 'next episode'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.replayGain,
      label: (l10n) => l10n.playerSettingsReplayGainTitle,
      synonyms: (_) => ['audio normalization'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.replayGainLevel,
      label: (l10n) => l10n.playerSettingsReplayGainLevelTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.smartDownmix,
      label: (l10n) => l10n.playerSettingsSmartDownmixTitle,
      synonyms: (_) => ['surround sound', 'stereo'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.dialogueBoost,
      label: (l10n) => l10n.playerSettingsDialogueBoostTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.crossfade,
      label: (l10n) => l10n.settingsPlayerCrossfadeTitle,
      synonyms: (_) => ['music', 'audio transition'],
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.advancedVideoOptions,
      label: (l10n) => l10n.advancedVideoOptionsTitle,
      route: () => const PlayerSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.orientation,
      label: (l10n) => l10n.playerSettingsOrientationTitle,
      synonyms: (_) => ['rotation', 'landscape', 'portrait'],
      route: () => const PlayerSettingsRoute(),
    ),
    // Account & Device › Account
    SettingsEntry(
      id: SettingId.appLockEnabled,
      label: (l10n) => l10n.settingSecurityApplockTitle,
      synonyms: (_) => ['biometrics', 'pin', 'security'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.openAuthAtLaunch,
      label: (l10n) => l10n.profileSettingsOpenAuthAtLaunch,
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.password,
      label: (l10n) => l10n.password,
      synonyms: (_) => ['change password', 'account'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.subtitleLanguage,
      label: (l10n) => l10n.settingsProfileSubtitleLanguage,
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.subtitleMode,
      label: (l10n) => l10n.settingsProfileSubtitleMode,
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.updateCheckInterval,
      label: (l10n) => l10n.updateCheckInterval,
      synonyms: (_) => ['app updates'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.showNewItemNotification,
      label: (l10n) => l10n.showNewItemNotificationTitle,
      synonyms: (_) => ['notifications'],
      route: () => const AccountDeviceSettingsRoute(),
    ),
    SettingsEntry(
      id: SettingId.includeHiddenItems,
      label: (l10n) => l10n.includeHiddenItems,
      route: () => const AccountDeviceSettingsRoute(),
    ),
  ];
}

/// Entries in [registry] whose [SettingsEntry.label] or synonyms match
/// [query] (case-insensitive substring match). Empty query returns nothing —
/// callers should show their normal (non-search) content in that case.
List<SettingsEntry> searchSettingsRegistry(
  List<SettingsEntry> registry,
  String query,
  AppLocalizations l10n,
) {
  return registry.where((entry) => entry.matches(query, l10n)).toList();
}
