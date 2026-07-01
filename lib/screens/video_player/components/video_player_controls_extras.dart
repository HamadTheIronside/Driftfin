import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/models/items/media_segments_model.dart';
import 'package:driftfin/providers/settings/video_player_settings_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/screens/shared/animated_fade_size.dart';
import 'package:driftfin/screens/video_player/components/video_player_chapters.dart';
import 'package:driftfin/screens/video_player/components/video_player_queue.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Takes a screenshot of the current frame. Grayed out on backends whose
/// [PlayerCapabilities.screenshots] is false (see BasePlayer capability
/// matrix) instead of silently doing nothing when tapped.
class ScreenshotButton extends ConsumerWidget {
  const ScreenshotButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportsScreenshots = ref.watch(videoPlayerProvider.select((value) => value.capabilities.screenshots));
    return IconButton(
      tooltip: context.localized.takeScreenshot,
      onPressed: supportsScreenshots ? () => ref.read(videoPlayerProvider.notifier).takeScreenshot() : null,
      icon: const Icon(Icons.camera_alt_outlined),
    );
  }
}

class ChapterButton extends ConsumerWidget {
  final Duration position;
  const ChapterButton({super.key, required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChapters = ref.watch(playBackModel.select((value) => value?.chapters));
    if (currentChapters == null || currentChapters.isEmpty) return Container();
    // ponytail: prev/next reuse the existing nextChapter/prevChapter seek logic
    // (same call the PageUp/PageDown hotkeys make) — no new logic, fork-safe.
    final settings = ref.read(videoPlayerSettingsProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.localized.prevChapter,
          onPressed: settings.prevChapter,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        IconButton(
          onPressed: () {
            showPlayerChapterDialogue(
              context,
              chapters: currentChapters,
              currentPosition: position,
              onChapterTapped: (chapter) => ref.read(videoPlayerProvider).seek(
                    chapter.startPosition,
                  ),
            );
          },
          icon: const Icon(
            Icons.video_collection_rounded,
          ),
        ),
        IconButton(
          tooltip: context.localized.nextChapter,
          onPressed: settings.nextChapter,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

class OpenQueueButton extends ConsumerWidget {
  const OpenQueueButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playBackModel);
    return IconButton(
      onPressed: state?.queue.isNotEmpty == true
          ? () {
              ref.read(videoPlayerProvider).pause();
              showFullScreenItemQueue(
                context,
                items: state?.queue ?? [],
                currentItem: state?.item,
                onSectionReorder: (section, oldIndex, newIndex) {
                  return ref.read(videoPlayerProvider.notifier).reorderAudioQueueSection(
                        section,
                        oldIndex,
                        newIndex,
                      );
                },
                playSelected: ref.read(videoPlayerProvider.notifier).playAudioQueueItem,
              );
            }
          : null,
      icon: const Icon(Icons.view_list_rounded),
    );
  }
}

class SkipSegmentButton extends ConsumerWidget {
  final MediaSegment? segment;
  final SegmentSkip? skipType;
  final SegmentVisibility visibility;

  final Function() pressedSkip;
  const SkipSegmentButton({
    required this.segment,
    this.skipType,
    required this.visibility,
    required this.pressedSkip,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedFadeSize(
      child: segment != null && skipType != SegmentSkip.none
          ? AnimatedOpacity(
              opacity: switch (visibility) {
                SegmentVisibility.hidden => 0,
                SegmentVisibility.partially => 0.15,
                SegmentVisibility.visible => 1.0,
              },
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton(
                onPressed: pressedSkip,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.localized.skipButtonLabel(segment!.type.label(context))),
                      const Icon(Icons.skip_next_rounded)
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: Key("Other")),
    );
  }
}
