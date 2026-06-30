import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/syncplay/sync_play_models.dart';
import 'package:driftfin/models/syncplay/sync_play_state.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/syncplay/jellyfin_socket.dart';
import 'package:driftfin/providers/syncplay/time_sync_service.dart';
import 'package:driftfin/providers/user_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/wrappers/media_control_wrapper.dart';
import 'package:driftfin/wrappers/players/player_states.dart';

/// Jellyfin time ticks are 100-nanosecond units.
int _ticksFromDuration(Duration d) => d.inMicroseconds * 10;
Duration _durationFromTicks(int ticks) => Duration(microseconds: ticks ~/ 10);

/// Drives a Jellyfin SyncPlay ("Watch Together") session: owns the WebSocket and
/// time-sync services, routes group-update and scheduled-command messages, keeps
/// the local player aligned with the group, and reports buffering/ready so the
/// group waits for slow members.
///
/// MVP scope: synchronized play/pause/seek for members already playing the same
/// item. Auto-loading a different item from the group's PlayQueue is deferred
/// (it surfaces [pendingItemId] for the UI to prompt instead).
class SyncPlayController extends StateNotifier<SyncPlayState> {
  SyncPlayController(this.ref) : super(const SyncPlayState());

  final Ref ref;

  final JellyfinSocket _socket = JellyfinSocket();
  TimeSyncService? _timeSync;

  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<SyncPlayConnection>? _connSub;
  StreamSubscription<PlayerState>? _playerSub;
  Timer? _commandTimer;

  bool _wired = false;
  bool _lastBuffering = false;

  /// PlaylistItemId the group is currently playing (from PlayQueue updates),
  /// reported back in buffering/ready messages.
  String? _currentPlaylistItemId;

  /// Set when the group is playing an item different from the local player; the
  /// UI can prompt the user to open it. Null when in sync.
  String? pendingItemId;

  JellyfinOpenApi get _api => ref.read(jellyApiProvider).api;
  MediaControlsWrapper get _player => ref.read(videoPlayerProvider);

  // ---- Public API ---------------------------------------------------------

  Future<List<GroupInfoDto>> listGroups() async {
    try {
      final resp = await _api.syncPlayListGet();
      return resp.body ?? const [];
    } catch (e) {
      log('SyncPlay listGroups failed: $e');
      return const [];
    }
  }

  Future<void> createGroup({String? name}) async {
    _ensureWired();
    try {
      final groupName = (name == null || name.trim().isEmpty) ? _defaultGroupName() : name.trim();
      await _api.syncPlayNewPost(body: NewGroupRequestDto(groupName: groupName));
      // Seed the group's queue with whatever we're currently watching.
      await _seedCurrentQueue();
    } catch (e) {
      _setError('Failed to create group: $e');
    }
  }

  Future<void> joinGroup(String groupId) async {
    _ensureWired();
    try {
      await _api.syncPlayJoinPost(body: JoinGroupRequestDto(groupId: groupId));
    } catch (e) {
      _setError('Failed to join group: $e');
    }
  }

  Future<void> leaveGroup() async {
    try {
      await _api.syncPlayLeavePost();
    } catch (e) {
      log('SyncPlay leave failed: $e');
    }
    _commandTimer?.cancel();
    pendingItemId = null;
    _currentPlaylistItemId = null;
    state = state.copyWith(clearGroup: true);
  }

  /// Routed from the player when the user toggles play/pause while in a group:
  /// instead of acting locally, ask the server, which schedules the action for
  /// everyone (including us).
  Future<void> userTogglePlayPause() async {
    if (!state.inGroup) return;
    final playing = _player.lastState?.playing ?? false;
    try {
      if (playing) {
        await _api.syncPlayPausePost();
      } else {
        await _api.syncPlayUnpausePost();
      }
    } catch (e) {
      log('SyncPlay toggle failed: $e');
    }
  }

  /// Routed from the player when the user seeks while in a group.
  Future<void> userSeek(Duration position) async {
    if (!state.inGroup) return;
    try {
      await _api.syncPlaySeekPost(body: SeekRequestDto(positionTicks: _ticksFromDuration(position)));
    } catch (e) {
      log('SyncPlay seek failed: $e');
    }
  }

  // ---- Wiring -------------------------------------------------------------

  void _ensureWired() {
    if (_wired) return;
    final account = ref.read(userProvider);
    final baseUrl = ref.read(serverUrlProvider);
    final token = account?.credentials.token;
    final deviceId = account?.credentials.deviceId;
    if (baseUrl == null || baseUrl.isEmpty || token == null || token.isEmpty) {
      _setError('Not signed in to a server');
      return;
    }
    _wired = true;

    _timeSync = TimeSyncService(
      fetchUtc: () async {
        final resp = await _api.getUtcTimeGet();
        final b = resp.body;
        if (b?.requestReceptionTime == null || b?.responseTransmissionTime == null) return null;
        return UtcMeasurement(requestReceived: b!.requestReceptionTime!, responseSent: b.responseTransmissionTime!);
      },
      onPing: (ms) {
        // Best-effort: let the server account for our latency in scheduling.
        _api.syncPlayPingPost(body: PingRequestDto(ping: ms)).ignore();
      },
    )..start();

    _connSub = _socket.connectionState.listen((c) => state = state.copyWith(connection: c));
    _msgSub = _socket.messages.listen(_onMessage);
    _playerSub = _player.stateStream.listen(_onPlayerState);

    _socket.connect(baseUrl: baseUrl, token: token, deviceId: deviceId ?? '');
  }

  // ---- Inbound message routing -------------------------------------------

  void _onMessage(Map<String, dynamic> msg) {
    switch (msg['MessageType']?.toString()) {
      case 'SyncPlayGroupUpdate':
        final data = msg['Data'];
        if (data is Map<String, dynamic>) _onGroupUpdate(SyncPlayGroupUpdate.fromJson(data));
        break;
      case 'SyncPlayCommand':
        final data = msg['Data'];
        if (data is Map<String, dynamic>) _onCommand(data);
        break;
    }
  }

  void _onGroupUpdate(SyncPlayGroupUpdate update) {
    switch (update.type) {
      case SyncGroupUpdateType.groupJoined:
        final info = update.groupInfo;
        state = state.copyWith(
          inGroup: true,
          groupId: info?['GroupId']?.toString() ?? update.groupId,
          groupName: info?['GroupName']?.toString(),
          members: _participants(info),
          groupState: SyncGroupState.parse(info?['State']),
          clearError: true,
        );
        // Tell the server we're ready at our current position, otherwise a
        // group that is already playing will keep waiting on us.
        _reportReady();
        break;
      case SyncGroupUpdateType.groupLeft:
      case SyncGroupUpdateType.notInGroup:
      case SyncGroupUpdateType.groupDoesNotExist:
        _commandTimer?.cancel();
        pendingItemId = null;
        state = state.copyWith(clearGroup: true);
        break;
      case SyncGroupUpdateType.libraryAccessDenied:
        _setError('Library access denied for this group');
        state = state.copyWith(clearGroup: true);
        break;
      case SyncGroupUpdateType.userJoined:
      case SyncGroupUpdateType.userLeft:
        _refreshMembers();
        break;
      case SyncGroupUpdateType.stateUpdate:
        final data = update.data;
        if (data is Map<String, dynamic>) {
          state = state.copyWith(groupState: SyncGroupState.parse(data['State']));
        }
        break;
      case SyncGroupUpdateType.playQueue:
        final data = update.data;
        if (data is Map<String, dynamic>) _onPlayQueue(data);
        break;
      case SyncGroupUpdateType.unknown:
        break;
    }
  }

  void _onPlayQueue(Map<String, dynamic> q) {
    final playlist = q['Playlist'];
    final index = (q['PlayingItemIndex'] as num?)?.toInt() ?? 0;
    if (playlist is List && index >= 0 && index < playlist.length) {
      final item = playlist[index];
      if (item is Map<String, dynamic>) {
        _currentPlaylistItemId = item['PlaylistItemId']?.toString();
        final itemId = item['ItemId']?.toString();
        final localItemId = ref.read(playBackModel)?.item.id;
        // MVP: if the group is on a different item than we're watching, surface
        // it for the UI to prompt rather than silently switching playback.
        pendingItemId = (itemId != null && itemId != localItemId) ? itemId : null;
      }
    }
  }

  // ---- Scheduled command execution ---------------------------------------

  void _onCommand(Map<String, dynamic> cmd) {
    final command = parseSyncCommand(cmd['Command']);
    final ticks = (cmd['PositionTicks'] as num?)?.toInt();
    final position = ticks != null ? _durationFromTicks(ticks) : null;
    final whenStr = cmd['When']?.toString();
    final when = whenStr != null ? DateTime.tryParse(whenStr) : null;

    final localWhen = (when != null && (_timeSync?.hasSynced ?? false)) ? _timeSync!.serverToLocal(when) : DateTime.now().toUtc();
    var delay = localWhen.difference(DateTime.now().toUtc());
    if (delay.isNegative) delay = Duration.zero;

    _commandTimer?.cancel();
    _commandTimer = Timer(delay, () => _applyCommand(command, position));
  }

  void _applyCommand(SyncCommand command, Duration? position) {
    final player = _player;
    switch (command) {
      case SyncCommand.unpause:
        if (position != null) player.syncApplySeek(position);
        player.syncApplyPlay();
        break;
      case SyncCommand.pause:
        player.syncApplyPause();
        if (position != null) player.syncApplySeek(position);
        break;
      case SyncCommand.seek:
        if (position != null) player.syncApplySeek(position);
        break;
      case SyncCommand.stop:
        player.syncApplyPause();
        break;
      case SyncCommand.unknown:
        break;
    }
  }

  // ---- Buffering / ready handshake ---------------------------------------

  void _onPlayerState(PlayerState s) {
    if (!state.inGroup) return;
    if (s.buffering == _lastBuffering) return;
    _lastBuffering = s.buffering;
    _reportBuffer(s.buffering, s.position, s.playing);
  }

  /// Report that we're ready at our current position (e.g. right after joining).
  void _reportReady() {
    final s = _player.lastState;
    if (s == null) return;
    _lastBuffering = false;
    _reportBuffer(false, s.position, s.playing);
  }

  void _reportBuffer(bool buffering, Duration position, bool playing) {
    final when = _timeSync?.localToServer(DateTime.now()) ?? DateTime.now().toUtc();
    final ticks = _ticksFromDuration(position);
    if (buffering) {
      _api
          .syncPlayBufferingPost(
            body: BufferRequestDto(when: when, positionTicks: ticks, isPlaying: playing, playlistItemId: _currentPlaylistItemId),
          )
          .ignore();
    } else {
      _api
          .syncPlayReadyPost(
            body: ReadyRequestDto(when: when, positionTicks: ticks, isPlaying: playing, playlistItemId: _currentPlaylistItemId),
          )
          .ignore();
    }
  }

  // ---- Helpers ------------------------------------------------------------

  Future<void> _seedCurrentQueue() async {
    final pb = ref.read(playBackModel);
    final itemId = pb?.item.id;
    if (itemId == null) return;
    final position = _player.lastState?.position ?? Duration.zero;
    try {
      await _api.syncPlaySetNewQueuePost(
        body: PlayRequestDto(
          playingQueue: [itemId],
          playingItemPosition: 0,
          startPositionTicks: _ticksFromDuration(position),
        ),
      );
    } catch (e) {
      log('SyncPlay seed queue failed: $e');
    }
  }

  Future<void> _refreshMembers() async {
    final id = state.groupId;
    if (id == null) return;
    try {
      final resp = await _api.syncPlayIdGet(id: id);
      state = state.copyWith(members: _participants(resp.body?.toJson()));
    } catch (e) {
      log('SyncPlay refresh members failed: $e');
    }
  }

  List<String> _participants(Map<String, dynamic>? info) {
    final p = info?['Participants'] ?? info?['participants'];
    if (p is List) return p.map((e) => e.toString()).toList();
    return state.members;
  }

  String _defaultGroupName() {
    final title = ref.read(playBackModel)?.item.title;
    return (title == null || title.isEmpty) ? 'Watch Together' : title;
  }

  void _setError(String message) {
    log('SyncPlay: $message');
    state = state.copyWith(lastError: message);
  }

  @override
  void dispose() {
    _commandTimer?.cancel();
    _msgSub?.cancel();
    _connSub?.cancel();
    _playerSub?.cancel();
    _timeSync?.dispose();
    _socket.dispose();
    super.dispose();
  }
}

final syncPlayControllerProvider = StateNotifierProvider<SyncPlayController, SyncPlayState>(
  (ref) => SyncPlayController(ref),
);
