import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/wrappers/players/player_states.dart';

void main() {
  group('PlayerState', () {
    test('constructor defaults', () {
      final state = PlayerState();

      expect(state.playing, isFalse);
      expect(state.completed, isFalse);
      expect(state.position, Duration.zero);
      expect(state.duration, Duration.zero);
      expect(state.volume, 100);
      expect(state.rate, 1.0);
      expect(state.buffering, isTrue);
      expect(state.buffer, Duration.zero);
    });

    test('update mutates only the provided fields and returns itself', () {
      final state = PlayerState();

      final result = state.update(playing: true, position: const Duration(seconds: 5));

      expect(identical(result, state), isTrue);
      expect(state.playing, isTrue);
      expect(state.position, const Duration(seconds: 5));
      // Untouched fields keep their defaults.
      expect(state.completed, isFalse);
      expect(state.duration, Duration.zero);
      expect(state.volume, 100);
      expect(state.rate, 1.0);
      expect(state.buffering, isTrue);
      expect(state.buffer, Duration.zero);
    });

    test('update with no arguments leaves all fields unchanged', () {
      final state = PlayerState(playing: true, volume: 42, rate: 1.5);

      state.update();

      expect(state.playing, isTrue);
      expect(state.volume, 42);
      expect(state.rate, 1.5);
    });

    test('successive updates accumulate', () {
      final state = PlayerState();

      state.update(buffering: false);
      state.update(playing: true);
      state.update(completed: true);

      expect(state.buffering, isFalse);
      expect(state.playing, isTrue);
      expect(state.completed, isTrue);
    });

    test('update can explicitly reset booleans back to false', () {
      final state = PlayerState(playing: true, completed: true, buffering: false);

      state.update(playing: false, completed: false, buffering: true);

      expect(state.playing, isFalse);
      expect(state.completed, isFalse);
      expect(state.buffering, isTrue);
    });

    test('duration and buffer track independent Duration values', () {
      final state = PlayerState();

      state.update(duration: const Duration(minutes: 10), buffer: const Duration(minutes: 2));

      expect(state.duration, const Duration(minutes: 10));
      expect(state.buffer, const Duration(minutes: 2));
    });

    test('error starts null and can be set via update', () {
      final state = PlayerState();
      expect(state.error, isNull);

      const error = PlayerError('boom', fatal: true);
      state.update(error: error);

      expect(state.error, error);
    });

    test('update without an error argument does not clear a previously set error', () {
      final state = PlayerState()..update(error: const PlayerError('boom'));

      state.update(playing: true);

      expect(state.error, const PlayerError('boom'));
    });

    test('clearError resets the error back to null', () {
      final state = PlayerState()..update(error: const PlayerError('boom'));

      state.clearError();

      expect(state.error, isNull);
    });

    test('PlayerError equality is value-based', () {
      expect(const PlayerError('boom', fatal: true), const PlayerError('boom', fatal: true));
      expect(const PlayerError('boom'), isNot(const PlayerError('boom', fatal: true)));
    });
  });

  group('PlayerStream.bindToState', () {
    test('forwards emitted values from each stream into the PlayerState', () async {
      final playingController = StreamController<bool>();
      final completedController = StreamController<bool>();
      final positionController = StreamController<Duration>();
      final durationController = StreamController<Duration>();
      final volumeController = StreamController<double>();
      final rateController = StreamController<double>();
      final bufferingController = StreamController<bool>();
      final bufferController = StreamController<Duration>();

      final playerStream = PlayerStream(
        playingController.stream,
        completedController.stream,
        positionController.stream,
        durationController.stream,
        volumeController.stream,
        rateController.stream,
        bufferingController.stream,
        bufferController.stream,
      );

      final state = PlayerState();
      playerStream.bindToState(state);

      playingController.add(true);
      completedController.add(true);
      positionController.add(const Duration(seconds: 30));
      volumeController.add(55);
      rateController.add(2.0);
      bufferingController.add(false);
      durationController.add(const Duration(minutes: 3));
      bufferController.add(const Duration(seconds: 45));

      // Stream listeners are async; let the microtask queue drain.
      await Future<void>.delayed(Duration.zero);

      expect(state.playing, isTrue);
      expect(state.completed, isTrue);
      expect(state.position, const Duration(seconds: 30));
      expect(state.volume, 55);
      expect(state.rate, 2.0);
      expect(state.buffering, isFalse);
      expect(state.duration, const Duration(minutes: 3));
      expect(state.buffer, const Duration(seconds: 45));

      await playingController.close();
      await completedController.close();
      await positionController.close();
      await durationController.close();
      await volumeController.close();
      await rateController.close();
      await bufferingController.close();
      await bufferController.close();
    });
  });
}
