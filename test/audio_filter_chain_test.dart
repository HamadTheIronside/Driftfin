import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/audio_filter_chain.dart';

void main() {
  group('AudioFilterChainBuilder', () {
    test('builds an empty string with no filters added', () {
      expect(AudioFilterChainBuilder().build(), '');
    });

    test('joins added filters with commas, in order', () {
      final chain = AudioFilterChainBuilder().addFilter('format=stereo').addFilter('loudnorm').build();
      expect(chain, 'format=stereo,loudnorm');
    });

    test('skips null and empty filters', () {
      final chain = AudioFilterChainBuilder()
          .addFilter('format=stereo')
          .addFilter(null)
          .addFilter('')
          .addFilter('loudnorm')
          .build();
      expect(chain, 'format=stereo,loudnorm');
    });

    test('addFilter returns the builder for chaining', () {
      final builder = AudioFilterChainBuilder();
      expect(builder.addFilter('a'), same(builder));
    });
  });

  group('smartDownmixFilter', () {
    test('null when disabled', () {
      expect(smartDownmixFilter(enabled: false), isNull);
    });

    test('a center-weighted pan filter when enabled', () {
      final filter = smartDownmixFilter(enabled: true);
      expect(filter, isNotNull);
      expect(filter, startsWith('pan=stereo'));
      expect(filter, contains('FC')); // boosts the center/dialogue channel
    });
  });

  group('dialogueBoostFilter', () {
    test('null when off', () {
      expect(dialogueBoostFilter(DialogueBoostLevel.off), isNull);
    });

    test('a dynaudnorm filter for low/medium/high, each distinct', () {
      final low = dialogueBoostFilter(DialogueBoostLevel.low);
      final medium = dialogueBoostFilter(DialogueBoostLevel.medium);
      final high = dialogueBoostFilter(DialogueBoostLevel.high);

      for (final filter in [low, medium, high]) {
        expect(filter, isNotNull);
        expect(filter, startsWith('dynaudnorm'));
      }
      expect({low, medium, high}.length, 3, reason: 'each level should produce a distinct filter');
    });
  });

  group('buildNightModeAudioFilter', () {
    test('empty when both smart downmix and dialogue boost are disabled', () {
      final chain = buildNightModeAudioFilter(enableSmartDownmix: false, dialogueBoost: DialogueBoostLevel.off);
      expect(chain, '');
    });

    test('includes only the downmix filter when just smart downmix is enabled', () {
      final chain = buildNightModeAudioFilter(enableSmartDownmix: true, dialogueBoost: DialogueBoostLevel.off);
      expect(chain, startsWith('pan=stereo'));
      expect(chain, isNot(contains('dynaudnorm')));
    });

    test('includes only the boost filter when just dialogue boost is enabled', () {
      final chain = buildNightModeAudioFilter(enableSmartDownmix: false, dialogueBoost: DialogueBoostLevel.medium);
      expect(chain, isNot(contains('pan=stereo')));
      expect(chain, startsWith('dynaudnorm'));
    });

    test('composes both filters, comma-joined, when both are enabled', () {
      final chain = buildNightModeAudioFilter(enableSmartDownmix: true, dialogueBoost: DialogueBoostLevel.high);
      final downmix = smartDownmixFilter(enabled: true);
      final boost = dialogueBoostFilter(DialogueBoostLevel.high);
      expect(chain, '$downmix,$boost');
    });
  });

  group('buildReplayGainFallbackFilter', () {
    test('composes stereo format, loudnorm and the gain in one chain', () {
      final chain = buildReplayGainFallbackFilter(-6.5);
      expect(chain, 'format=stereo,loudnorm,volume=-6.5dB');
    });
  });

  group('volumeGainFilter / stereoFormatFilter', () {
    test('volumeGainFilter formats the dB value', () {
      expect(volumeGainFilter(3.25), 'volume=3.25dB');
    });

    test('stereoFormatFilter is the plain format filter', () {
      expect(stereoFormatFilter(), 'format=stereo');
    });
  });
}
