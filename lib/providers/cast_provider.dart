import 'dart:async';

import 'package:cast_plus/cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:driftfin/providers/image_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';

/// Connection lifecycle for a Chromecast session.
enum CastStatus { disconnected, discovering, connecting, connected, error }

/// Immutable view of the current cast state for the UI.
class CastState {
  final CastStatus status;
  final List<CastDevice> devices;
  final CastDevice? device;
  final Duration position;
  final Duration duration;
  final bool playing;
  final String? error;

  const CastState({
    this.status = CastStatus.disconnected,
    this.devices = const [],
    this.device,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.error,
  });

  bool get isCasting => status == CastStatus.connected;

  CastState copyWith({
    CastStatus? status,
    List<CastDevice>? devices,
    CastDevice? device,
    bool clearDevice = false,
    Duration? position,
    Duration? duration,
    bool? playing,
    String? error,
    bool clearError = false,
  }) {
    return CastState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      device: clearDevice ? null : (device ?? this.device),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Builds the Cast `LOAD` payload for the default media receiver from the
/// current Jellyfin playback model. Pure function — unit-tested.
Map<String, dynamic> buildLoadMessage({
  required String url,
  required String title,
  String? imageUrl,
  String contentType = 'video/mp4',
  Duration startAt = Duration.zero,
}) {
  return {
    'type': 'LOAD',
    'autoPlay': true,
    'currentTime': startAt.inSeconds,
    'media': {
      'contentId': url,
      'contentType': contentType,
      'streamType': 'BUFFERED',
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': title,
        if (imageUrl != null)
          'images': [
            {'url': imageUrl}
          ],
      },
    },
  };
}

/// Parsed view of a Cast `MEDIA_STATUS` message. Null when the message carries
/// no status entry. Pure — unit-tested.
typedef MediaStatus = ({int? mediaSessionId, bool? playing, Duration? position, Duration? duration});

MediaStatus? parseMediaStatus(Map<String, dynamic> message) {
  if (message['type'] != 'MEDIA_STATUS') return null;
  final statuses = (message['status'] as List?) ?? const [];
  if (statuses.isEmpty) return null;
  final s = statuses.first as Map<String, dynamic>;
  final current = (s['currentTime'] as num?)?.toDouble();
  final dur = ((s['media'] as Map?)?['duration'] as num?)?.toDouble();
  return (
    mediaSessionId: (s['mediaSessionId'] as num?)?.toInt(),
    playing: s['playerState'] == null ? null : s['playerState'] == 'PLAYING',
    position: current != null ? Duration(milliseconds: (current * 1000).round()) : null,
    duration: dur != null ? Duration(milliseconds: (dur * 1000).round()) : null,
  );
}

/// Builds a media-namespace command payload (PLAY/PAUSE/SEEK/STOP/SET_VOLUME).
/// Pure — unit-tested.
Map<String, dynamic> mediaCommand(String type, int mediaSessionId, [Map<String, dynamic> extra = const {}]) {
  return {'type': type, 'mediaSessionId': mediaSessionId, ...extra};
}

final castProvider = StateNotifierProvider<CastController, CastState>((ref) {
  return CastController(ref);
});

/// Runtime Chromecast controller. Independent of the local [BasePlayer] backend
/// (casting is a runtime hand-off, not a settings-time player choice). Reuses
/// the already-built Jellyfin direct-play URL in `PlaybackModel.media.url`.
class CastController extends StateNotifier<CastState> {
  CastController(this.ref) : super(const CastState());

  final Ref ref;
  final _log = Logger('Cast');

  // Default Media Receiver application id.
  static const _defaultReceiverAppId = 'CC1AD845';

  CastSession? _session;
  StreamSubscription? _stateSub;
  StreamSubscription? _messageSub;
  Timer? _statusTimer;
  int? _mediaSessionId;

  /// Discover Chromecast devices on the local network.
  Future<void> discover() async {
    state = state.copyWith(status: CastStatus.discovering, clearError: true);
    try {
      final devices = await CastDiscoveryService().search();
      state = state.copyWith(
        devices: devices,
        // Stay in discovering until the user picks; revert if nothing found.
        status: state.isCasting ? state.status : CastStatus.discovering,
      );
    } catch (e, s) {
      _log.warning('Cast discovery failed', e, s);
      state = state.copyWith(status: CastStatus.error, error: e.toString());
    }
  }

  /// Connect to [device], launch the default media receiver, and load the
  /// currently playing item.
  Future<void> connect(CastDevice device) async {
    await _teardownSession();
    state = state.copyWith(status: CastStatus.connecting, device: device, clearError: true);
    try {
      final session = await CastSessionManager().startSession(device);
      _session = session;

      // The package emits `connected` only after a receiver app is launched
      // (it needs the app's transportId). So: launch the default receiver now,
      // and load the media once the session reports connected.
      _stateSub = session.stateStream.listen((s) {
        if (s == CastSessionState.connected) {
          _loadCurrent();
        } else if (s == CastSessionState.closed) {
          _onClosed();
        }
      });
      _messageSub = session.messageStream.listen(_onMessage);

      // Pause local playback so we don't double-play, then launch the receiver.
      ref.read(videoPlayerProvider).pause();
      session.sendMessage(CastSession.kNamespaceReceiver, {
        'type': 'LAUNCH',
        'appId': _defaultReceiverAppId,
      });
    } catch (e, s) {
      _log.warning('Cast connect failed', e, s);
      state = state.copyWith(status: CastStatus.error, error: e.toString(), clearDevice: true);
      await _teardownSession();
    }
  }

  void _onMessage(Map<String, dynamic> message) {
    final status = parseMediaStatus(message);
    if (status == null) return;
    _mediaSessionId = status.mediaSessionId ?? _mediaSessionId;
    state = state.copyWith(
      status: CastStatus.connected,
      playing: status.playing,
      position: status.position,
      duration: status.duration,
    );
    _startStatusPolling();
  }

  void _loadCurrent() {
    final session = _session;
    final model = ref.read(playBackModel);
    final url = model?.media?.url;
    if (session == null || model == null || url == null) return;
    final imageUrl = ref.read(imageUtilityProvider).getItemsImageUrl(model.item.id);
    session.sendMessage(
      CastSession.kNamespaceMedia,
      buildLoadMessage(
        url: url,
        title: model.item.name,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        startAt: ref.read(videoPlayerProvider).lastState?.position ?? Duration.zero,
      ),
    );
    state = state.copyWith(status: CastStatus.connected);
  }

  void _media(String type, [Map<String, dynamic> extra = const {}]) {
    final session = _session;
    final id = _mediaSessionId;
    if (session == null || id == null) return;
    session.sendMessage(CastSession.kNamespaceMedia, mediaCommand(type, id, extra));
  }

  void play() => _media('PLAY');
  void pause() => _media('PAUSE');
  void seek(Duration to) => _media('SEEK', {'currentTime': to.inSeconds});
  void setVolume(double level) => _media('SET_VOLUME', {
        'volume': {'level': level.clamp(0.0, 1.0)}
      });

  void _startStatusPolling() {
    _statusTimer ??= Timer.periodic(const Duration(seconds: 2), (_) => _media('GET_STATUS'));
  }

  void _onClosed() {
    state = const CastState();
    _teardownSession();
  }

  /// Stop casting and tear down the session.
  Future<void> disconnect() async {
    _media('STOP');
    await _teardownSession();
    state = const CastState();
  }

  Future<void> _teardownSession() async {
    _statusTimer?.cancel();
    _statusTimer = null;
    await _stateSub?.cancel();
    await _messageSub?.cancel();
    _stateSub = null;
    _messageSub = null;
    _mediaSessionId = null;
    try {
      await _session?.close();
    } catch (_) {}
    _session = null;
  }

  @override
  void dispose() {
    _teardownSession();
    super.dispose();
  }
}
