import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/media_playback_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/providers/pip_provider.dart';
import 'package:driftfin/providers/settings/video_player_settings_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/wrappers/pip_manager.dart';

class PipLifecycleController extends ConsumerStatefulWidget {
  const PipLifecycleController({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PipLifecycleController> createState() => _PipLifecycleControllerState();
}

class _PipLifecycleControllerState extends ConsumerState<PipLifecycleController> {
  @override
  void initState() {
    super.initState();
    if (pipPlatformSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyCurrent());
    }
  }

  void _applyCurrent() {
    if (!mounted) return;
    final state = ref.read(mediaPlaybackProvider).state;
    final autoEnter = ref.read(videoPlayerSettingsProvider).enablePictureInPicture;
    _apply(state, autoEnter);
  }

  /// PiP should only auto-enter when an actual video is loaded — not for audio
  /// playback and not when nothing is playing at all (which would otherwise let
  /// the OS pop a PiP window as soon as the app is backgrounded).
  bool get _hasVideoPlayback {
    final model = ref.read(playBackModel);
    return model != null && !model.isAudioPlayback;
  }

  void _apply(VideoPlayerState state, bool autoEnter) {
    final manager = ref.read(pipManagerProvider);
    final isVideo = _hasVideoPlayback;
    if (isVideo && (state == VideoPlayerState.fullScreen || state == VideoPlayerState.minimized)) {
      manager.enable(aspectWidth: 16.0, aspectHeight: 9.0, autoEnter: autoEnter);
    } else {
      manager.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!pipPlatformSupported) {
      return widget.child;
    }
    ref.listen<VideoPlayerState>(
      mediaPlaybackProvider.select((v) => v.state),
      (previous, next) {
        if (previous == next) return;
        final autoEnter = ref.read(videoPlayerSettingsProvider).enablePictureInPicture;
        _apply(next, autoEnter);
      },
    );
    ref.listen<bool>(
      videoPlayerSettingsProvider.select((v) => v.enablePictureInPicture),
      (previous, next) {
        if (previous == next) return;
        final state = ref.read(mediaPlaybackProvider).state;
        _apply(state, next);
      },
    );
    // Re-evaluate whenever the active item changes (video started, swapped for
    // audio, or cleared) so PiP is only ever armed while a video is loaded.
    ref.listen<PlaybackModel?>(
      playBackModel,
      (previous, next) {
        _applyCurrent();
      },
    );

    final inPip = ref.watch(pipStateProvider).asData?.value ?? false;
    final state = ref.watch(mediaPlaybackProvider.select((v) => v.state));
    if (inPip && state == VideoPlayerState.minimized) {
      final player = ref.watch(videoPlayerProvider);
      final video = player.videoWidget(const ValueKey('pip_minimized_video'), BoxFit.contain);
      final subtitle = player.subtitleWidget(false);
      return ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video != null) video,
            if (subtitle != null) subtitle,
          ],
        ),
      );
    }
    return widget.child;
  }
}
