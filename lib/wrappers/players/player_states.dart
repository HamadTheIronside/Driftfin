class PlayerState {
  bool playing;
  bool completed;
  Duration position;
  Duration duration;
  double volume;
  double rate;
  bool buffering;
  Duration buffer;
  PlayerError? error;

  PlayerState({
    this.playing = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.rate = 1.0,
    this.buffering = true,
    this.buffer = Duration.zero,
    this.error,
  });

  PlayerState update({
    bool? playing,
    bool? completed,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    Duration? buffer,
    PlayerError? error,
  }) {
    if (playing != null) this.playing = playing;
    if (completed != null) this.completed = completed;
    if (buffering != null) this.buffering = buffering;
    if (position != null) this.position = position;
    if (duration != null) this.duration = duration;
    if (volume != null) this.volume = volume;
    if (rate != null) this.rate = rate;
    if (buffer != null) this.buffer = buffer;
    if (error != null) this.error = error;
    return this;
  }

  /// Clears a previously reported error, e.g. after a successful reload.
  PlayerState clearError() {
    error = null;
    return this;
  }
}

/// A non-fatal or fatal playback error reported by a [BasePlayer] backend.
///
/// Distinct from the retry loop in `lib_mpv.dart` giving up silently: this is
/// how a backend tells the UI/playback layer *why* it failed so it can react
/// (e.g. fall back to a transcode) instead of the player just sitting there.
class PlayerError {
  final String message;
  final bool fatal;

  const PlayerError(this.message, {this.fatal = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlayerError && message == other.message && fatal == other.fatal;

  @override
  int get hashCode => Object.hash(message, fatal);

  @override
  String toString() => 'PlayerError($message, fatal: $fatal)';
}

class PlayerStream {
  final Stream<bool> playing;
  final Stream<bool> completed;
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<double> volume;
  final Stream<double> rate;
  final Stream<bool> buffering;
  final Stream<Duration> buffer;

  const PlayerStream(
    this.playing,
    this.completed,
    this.position,
    this.duration,
    this.volume,
    this.rate,
    this.buffering,
    this.buffer,
  );

  void bindToState(PlayerState state) {
    playing.listen((value) => state.update(playing: value));
    completed.listen((value) => state.update(completed: value));
    buffering.listen((value) => state.update(buffering: value));
    position.listen((value) => state.update(position: value));
    duration.listen((value) => state.update(duration: value));
    volume.listen((value) => state.update(volume: value));
    rate.listen((value) => state.update(rate: value));
    buffer.listen((value) => state.update(buffer: value));
  }
}
