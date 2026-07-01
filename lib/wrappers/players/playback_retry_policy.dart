/// Decides how long a player backend should keep retrying an identical,
/// currently-failing source URL before giving up and reporting failure via
/// `PlayerState.failed`, so callers can fall back to a compatible transcode
/// instead of retrying a dead-end stream forever.
class PlaybackRetryPolicy {
  final Duration retryInterval;
  final Duration maxRetryDuration;

  const PlaybackRetryPolicy({
    this.retryInterval = const Duration(seconds: 5),
    this.maxRetryDuration = const Duration(minutes: 1),
  });

  /// Whether retries starting at [firstAttempt] have run out of budget as of [now].
  bool hasExceededBudget({required DateTime firstAttempt, required DateTime now}) {
    return now.isAfter(firstAttempt.add(maxRetryDuration));
  }
}
