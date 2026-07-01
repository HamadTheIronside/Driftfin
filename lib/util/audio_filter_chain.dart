import 'package:flutter/widgets.dart';

import 'package:driftfin/util/localization_helper.dart';

/// Composable building blocks for an mpv `af` (audio filter) chain string.
///
/// mpv's `af` property is a single comma-joined filter-chain string, so any
/// feature that wants to layer its own DSP on top of what's already there
/// (ReplayGain fallback, Night-Mode Audio, ...) needs to compose into one
/// string rather than overwrite it. [AudioFilterChainBuilder] collects named
/// segments and skips anything null/empty, so callers can conditionally add
/// filters without null-checking at each call site.
class AudioFilterChainBuilder {
  final List<String> _filters = [];

  AudioFilterChainBuilder addFilter(String? filter) {
    if (filter != null && filter.isNotEmpty) _filters.add(filter);
    return this;
  }

  String build() => _filters.join(',');
}

/// Levels of dialogue-boost intensity, applied via mpv's `dynaudnorm` filter
/// to lift quiet passages (where dialogue usually sits) without pumping up
/// loud action/music the way a flat volume boost would.
enum DialogueBoostLevel {
  off,
  low,
  medium,
  high;

  const DialogueBoostLevel();

  String label(BuildContext context) => switch (this) {
        DialogueBoostLevel.off => context.localized.dialogueBoostOff,
        DialogueBoostLevel.low => context.localized.dialogueBoostLow,
        DialogueBoostLevel.medium => context.localized.dialogueBoostMedium,
        DialogueBoostLevel.high => context.localized.dialogueBoostHigh,
      };
}

/// `format=stereo` forces a stereo downmix before any further stereo-only filters run.
String stereoFormatFilter() => 'format=stereo';

/// A gain-only filter, in dB, e.g. for the ReplayGain `af`-fallback path.
String volumeGainFilter(double gainDb) => 'volume=${gainDb}dB';

/// Center-weighted 5.1/7.1→stereo downmix: boosts the center (dialogue)
/// channel relative to the front/rear channels instead of mpv's flat default
/// downmix, so dialogue doesn't get buried under effects/rear channels.
String? smartDownmixFilter({required bool enabled}) {
  if (!enabled) return null;
  return 'pan=stereo|FL=0.32*FL+0.32*BL+0.90*FC+0.10*LFE|FR=0.32*FR+0.32*BR+0.90*FC+0.10*LFE';
}

/// A `dynaudnorm` stage tuned per [level]; `off` applies no filter.
String? dialogueBoostFilter(DialogueBoostLevel level) => switch (level) {
      DialogueBoostLevel.off => null,
      DialogueBoostLevel.low => 'dynaudnorm=f=250:g=15:m=4:s=6',
      DialogueBoostLevel.medium => 'dynaudnorm=f=250:g=15:m=6:s=8',
      DialogueBoostLevel.high => 'dynaudnorm=f=250:g=15:m=8:s=10',
    };

/// Builds the Night-Mode Audio portion (smart downmix + dialogue boost) of
/// the filter chain. Returns an empty string when both are disabled.
String buildNightModeAudioFilter({
  required bool enableSmartDownmix,
  required DialogueBoostLevel dialogueBoost,
}) {
  return AudioFilterChainBuilder()
      .addFilter(smartDownmixFilter(enabled: enableSmartDownmix))
      .addFilter(dialogueBoostFilter(dialogueBoost))
      .build();
}

/// Builds the ReplayGain `af`-fallback segment used when mpv's native
/// `replaygain` property isn't supported by the current build.
String buildReplayGainFallbackFilter(double replayGainFallbackDb) {
  return AudioFilterChainBuilder()
      .addFilter(stereoFormatFilter())
      .addFilter('loudnorm')
      .addFilter(volumeGainFilter(replayGainFallbackDb))
      .build();
}
