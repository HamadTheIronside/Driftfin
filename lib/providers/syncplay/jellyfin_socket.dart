import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:driftfin/models/syncplay/sync_play_state.dart';

/// A persistent, auto-reconnecting connection to a Jellyfin server's `/socket`
/// WebSocket. This is the first WebSocket in the app and is intentionally
/// generic: SyncPlay is just one of several message categories carried here
/// (the same socket also powers remote control / session messages), so the
/// socket only handles transport, keep-alive and reconnection — message
/// semantics live in higher layers.
///
/// Jellyfin authenticates the socket via query parameters
/// (`?api_key=<token>&deviceId=<id>`), which also keeps it working on web where
/// custom WebSocket headers are unavailable.
class JellyfinSocket {
  JellyfinSocket();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  DateTime? _connectedAt;
  bool _disposed = false;

  // Connection inputs, retained so reconnection can rebuild the URL.
  String? _baseUrl;
  String? _token;
  String? _deviceId;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _connection = StreamController<SyncPlayConnection>.broadcast();

  /// Decoded inbound messages (`{MessageType, Data, ...}`).
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  /// Connection lifecycle for UI/state.
  Stream<SyncPlayConnection> get connectionState => _connection.stream;

  bool get isConnected => _channel != null;

  /// Open (or re-open) the socket. Safe to call repeatedly; an existing
  /// connection is torn down first.
  void connect({required String baseUrl, required String token, required String deviceId}) {
    _baseUrl = baseUrl;
    _token = token;
    _deviceId = deviceId;
    _disposed = false;
    _reconnectAttempt = 0;
    _open();
  }

  Uri? _socketUri() {
    final base = _baseUrl;
    final token = _token;
    final deviceId = _deviceId;
    if (base == null || base.isEmpty || token == null || token.isEmpty) return null;
    // http(s) -> ws(s), strip a trailing slash, append /socket.
    final wsBase = base.replaceFirst(RegExp(r'^http'), 'ws').replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$wsBase/socket').replace(queryParameters: {
      'api_key': token,
      'deviceId': deviceId,
    });
  }

  void _open() {
    final uri = _socketUri();
    if (uri == null) return;
    _teardownChannel();
    _connection.add(SyncPlayConnection.connecting);
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      // ready resolves once the handshake completes; mark connected then.
      unawaited(_awaitReady(channel));
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> _awaitReady(WebSocketChannel channel) async {
    try {
      await channel.ready;
      if (_disposed || _channel != channel) return;
      _connectedAt = DateTime.now();
      _connection.add(SyncPlayConnection.connected);
      // Default keep-alive cadence; refined when ForceKeepAlive arrives.
      _scheduleKeepAlive(const Duration(seconds: 30));
    } catch (e) {
      _onError(e);
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> msg;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      msg = decoded;
    } catch (_) {
      return;
    }
    final type = msg['MessageType']?.toString();
    if (type == 'ForceKeepAlive') {
      // Data is the server's timeout in seconds; ping at half that.
      final timeout = msg['Data'];
      final seconds = (timeout is num && timeout > 2) ? (timeout ~/ 2) : 30;
      _scheduleKeepAlive(Duration(seconds: seconds));
      return;
    }
    if (type == 'KeepAlive') return;
    _messages.add(msg);
  }

  void _scheduleKeepAlive(Duration interval) {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(interval, (_) => send({'MessageType': 'KeepAlive'}));
  }

  /// Send a message envelope. No-op when disconnected.
  void send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(message));
    } catch (e, s) {
      log('SyncPlay socket send failed: $e', stackTrace: s);
    }
  }

  void _onError(Object error, [StackTrace? stack]) {
    log('SyncPlay socket error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    if (_disposed) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _teardownChannel();
    if (_disposed) return;
    _connection.add(SyncPlayConnection.disconnected);
    // Only treat a *stable* (>5s) connection that dropped as a fresh start;
    // a connection that drops immediately (e.g. auth rejected) keeps escalating
    // the backoff instead of hammering the server every second.
    final wasStable = _connectedAt != null && DateTime.now().difference(_connectedAt!) > const Duration(seconds: 5);
    if (wasStable) _reconnectAttempt = 0;
    _connectedAt = null;
    // Exponential backoff capped at 30s.
    final delaySeconds = (1 << _reconnectAttempt.clamp(0, 5)).clamp(1, 30);
    _reconnectAttempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_disposed) _open();
    });
  }

  void _teardownChannel() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close(ws_status.goingAway);
    } catch (_) {}
    _channel = null;
  }

  /// Close permanently (no reconnect) and release resources.
  Future<void> dispose() async {
    _disposed = true;
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _teardownChannel();
    _connection.add(SyncPlayConnection.disconnected);
    await _messages.close();
    await _connection.close();
  }
}
