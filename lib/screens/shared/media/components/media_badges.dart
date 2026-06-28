import 'package:flutter/material.dart';

import 'package:collection/collection.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/util/video_properties.dart';

/// Glanceable quality badges (resolution, HDR/Dolby Vision, audio format) for an
/// item's media streams. Renders nothing when there's no usable stream data.
class MediaBadges extends StatelessWidget {
  final MediaStreamsModel streams;
  const MediaBadges({required this.streams, super.key});

  @override
  Widget build(BuildContext context) {
    final video = streams.videoStreams.firstOrNull;
    final audio = streams.audioStreams.firstWhereOrNull((a) => a.isDefault) ?? streams.audioStreams.firstOrNull;

    final badges = <String>[];

    final resolution = Resolution.fromVideoStream(video)?.value;
    if (resolution != null && resolution.isNotEmpty) badges.add(resolution);

    if (video != null) {
      final profile = DisplayProfile.fromVideoStream(video);
      if (profile != DisplayProfile.sdr) badges.add(profile.value);
    }

    final audioBadge = _audioBadge(audio);
    if (audioBadge != null) badges.add(audioBadge);

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges.map((label) => _Badge(label)).toList(),
    );
  }

  String? _audioBadge(AudioStreamModel? audio) {
    if (audio == null) return null;
    final spatial = switch (audio.spatialFormat) {
      dto.AudioSpatialFormat.dolbyatmos => 'Atmos',
      dto.AudioSpatialFormat.dtsx => 'DTS:X',
      _ => null,
    };
    final codec = switch (audio.codec.toLowerCase()) {
      'truehd' => 'TrueHD',
      'eac3' => 'DD+',
      'ac3' => 'Dolby',
      'dts' || 'dca' => 'DTS',
      'flac' => 'FLAC',
      'aac' => 'AAC',
      'opus' => 'Opus',
      'mp3' => 'MP3',
      _ => audio.codec.isEmpty ? null : audio.codec.toUpperCase(),
    };
    final channels = _channels(audio.channels);
    final base = spatial ?? codec;
    if (base == null) return channels;
    return channels == null ? base : '$base $channels';
  }

  String? _channels(int? channels) => switch (channels) {
        8 => '7.1',
        6 => '5.1',
        2 => '2.0',
        1 => '1.0',
        _ => null,
      };
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
