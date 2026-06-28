import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/providers/shared_provider.dart';

/// Bring-your-own Trakt integration: the user supplies their own Trakt API
/// app (client id + secret) in settings, logs in via the OAuth *device* flow,
/// and Driftfin scrobbles playback to Trakt. Credentials/tokens are stored
/// locally and are never part of the cross-device settings sync.

const String _traktBase = 'https://api.trakt.tv';

/// OAuth tokens returned by Trakt.
class TraktTokens {
  final String accessToken;
  final String refreshToken;
  final int createdAt; // unix seconds
  final int expiresIn; // seconds

  const TraktTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.createdAt,
    required this.expiresIn,
  });

  /// True within an hour of expiry, so callers refresh proactively.
  bool expiredAt(int nowSeconds) => nowSeconds >= (createdAt + expiresIn - 3600);

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'createdAt': createdAt,
        'expiresIn': expiresIn,
      };

  factory TraktTokens.fromJson(Map<String, dynamic> json) => TraktTokens(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      );

  factory TraktTokens.fromOauth(Map<String, dynamic> json) => TraktTokens(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      );
}

/// Result of starting the device flow.
class TraktDeviceCode {
  final String deviceCode;
  final String userCode;
  final String verificationUrl;
  final int expiresIn;
  final int interval;

  const TraktDeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
  });

  factory TraktDeviceCode.fromJson(Map<String, dynamic> json) => TraktDeviceCode(
        deviceCode: json['device_code'] as String? ?? '',
        userCode: json['user_code'] as String? ?? '',
        verificationUrl: json['verification_url'] as String? ?? 'https://trakt.tv/activate',
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
        interval: (json['interval'] as num?)?.toInt() ?? 5,
      );
}

enum TraktPollStatus { pending, success, slowDown, expired, denied, invalid, error }

class TraktPollResult {
  final TraktPollStatus status;
  final TraktTokens? tokens;
  const TraktPollResult(this.status, [this.tokens]);
}

enum TraktScrobbleAction { start, pause, stop }

/// Thin, dependency-free Trakt client. Injectable [http.Client] for testing.
class TraktApi {
  TraktApi({
    required this.clientId,
    required this.clientSecret,
    this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String clientId;
  final String clientSecret;
  final String? accessToken;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'trakt-api-version': '2',
        'trakt-api-key': clientId,
        if (accessToken != null && accessToken!.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      };

  Future<TraktDeviceCode?> requestDeviceCode() async {
    final response = await _client.post(
      Uri.parse('$_traktBase/oauth/device/code'),
      headers: _headers,
      body: jsonEncode({'client_id': clientId}),
    );
    if (response.statusCode != 200) return null;
    return TraktDeviceCode.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TraktPollResult> pollDeviceToken(String deviceCode) async {
    final response = await _client.post(
      Uri.parse('$_traktBase/oauth/device/token'),
      headers: _headers,
      body: jsonEncode({'code': deviceCode, 'client_id': clientId, 'client_secret': clientSecret}),
    );
    switch (response.statusCode) {
      case 200:
        return TraktPollResult(
            TraktPollStatus.success, TraktTokens.fromOauth(jsonDecode(response.body) as Map<String, dynamic>));
      case 400:
        return const TraktPollResult(TraktPollStatus.pending);
      case 429:
        return const TraktPollResult(TraktPollStatus.slowDown);
      case 404:
      case 409:
        return const TraktPollResult(TraktPollStatus.invalid);
      case 410:
        return const TraktPollResult(TraktPollStatus.expired);
      case 418:
        return const TraktPollResult(TraktPollStatus.denied);
      default:
        return const TraktPollResult(TraktPollStatus.error);
    }
  }

  Future<TraktTokens?> refresh(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('$_traktBase/oauth/token'),
      headers: _headers,
      body: jsonEncode({
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
        'grant_type': 'refresh_token',
      }),
    );
    if (response.statusCode != 200) return null;
    return TraktTokens.fromOauth(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Scrobbles playback. [ids] is the Trakt ids map (tmdb/imdb/tvdb); [isMovie]
  /// chooses the movie vs episode payload; [progress] is 0..100.
  Future<bool> scrobble(
    TraktScrobbleAction action, {
    required Map<String, dynamic> ids,
    required bool isMovie,
    required double progress,
  }) async {
    final path = switch (action) {
      TraktScrobbleAction.start => 'start',
      TraktScrobbleAction.pause => 'pause',
      TraktScrobbleAction.stop => 'stop',
    };
    final body = <String, dynamic>{
      if (isMovie) 'movie': {'ids': ids} else 'episode': {'ids': ids},
      'progress': progress,
    };
    final response = await _client.post(
      Uri.parse('$_traktBase/scrobble/$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}

/// Persisted Trakt config: BYO credentials + tokens. Never synced.
class TraktSettings {
  final String clientId;
  final String clientSecret;
  final bool enabled;
  final TraktTokens? tokens;

  const TraktSettings({this.clientId = '', this.clientSecret = '', this.enabled = false, this.tokens});

  bool get hasCredentials => clientId.trim().isNotEmpty && clientSecret.trim().isNotEmpty;
  bool get isAuthenticated => tokens != null && tokens!.accessToken.isNotEmpty;
  bool get isActive => enabled && hasCredentials && isAuthenticated;

  TraktSettings copyWith({String? clientId, String? clientSecret, bool? enabled, TraktTokens? tokens, bool clearTokens = false}) =>
      TraktSettings(
        clientId: clientId ?? this.clientId,
        clientSecret: clientSecret ?? this.clientSecret,
        enabled: enabled ?? this.enabled,
        tokens: clearTokens ? null : (tokens ?? this.tokens),
      );

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'clientSecret': clientSecret,
        'enabled': enabled,
        'tokens': tokens?.toJson(),
      };

  factory TraktSettings.fromJson(Map<String, dynamic> json) => TraktSettings(
        clientId: json['clientId'] as String? ?? '',
        clientSecret: json['clientSecret'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        tokens: json['tokens'] == null ? null : TraktTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      );
}

const String _traktSettingsKey = 'traktSettings';

final traktProvider = StateNotifierProvider<TraktNotifier, TraktSettings>((ref) {
  return TraktNotifier(ref);
});

class TraktNotifier extends StateNotifier<TraktSettings> {
  TraktNotifier(this.ref) : super(_load(ref)) {
    _client = http.Client();
  }

  final Ref ref;
  late final http.Client _client;

  static TraktSettings _load(Ref ref) {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_traktSettingsKey);
      if (raw == null || raw.isEmpty) return const TraktSettings();
      return TraktSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TraktSettings();
    }
  }

  void _persist() => ref.read(sharedPreferencesProvider).setString(_traktSettingsKey, jsonEncode(state.toJson()));

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
    _persist();
  }

  void setClientId(String value) {
    state = state.copyWith(clientId: value.trim());
    _persist();
  }

  void setClientSecret(String value) {
    state = state.copyWith(clientSecret: value.trim());
    _persist();
  }

  void logout() {
    state = state.copyWith(clearTokens: true);
    _persist();
  }

  TraktApi _api({String? accessToken}) =>
      TraktApi(clientId: state.clientId, clientSecret: state.clientSecret, accessToken: accessToken, client: _client);

  /// Starts the device flow; the UI shows the returned code + url then calls
  /// [pollDeviceToken] until it resolves.
  Future<TraktDeviceCode?> startDeviceLogin() {
    if (!state.hasCredentials) return Future.value(null);
    return _api().requestDeviceCode();
  }

  Future<TraktPollResult> pollDeviceToken(String deviceCode) async {
    final result = await _api().pollDeviceToken(deviceCode);
    if (result.status == TraktPollStatus.success && result.tokens != null) {
      state = state.copyWith(tokens: result.tokens, enabled: true);
      _persist();
    }
    return result;
  }

  /// Returns a usable access token, refreshing if needed. Null if not logged in.
  Future<String?> _validAccessToken(int nowSeconds) async {
    final tokens = state.tokens;
    if (tokens == null || tokens.accessToken.isEmpty) return null;
    if (!tokens.expiredAt(nowSeconds)) return tokens.accessToken;
    final refreshed = await _api().refresh(tokens.refreshToken);
    if (refreshed == null) return tokens.accessToken; // fall back to current
    state = state.copyWith(tokens: refreshed);
    _persist();
    return refreshed.accessToken;
  }

  /// Scrobbles playback to Trakt. No-op (returns false) unless active.
  Future<bool> scrobble(
    TraktScrobbleAction action, {
    required Map<String, dynamic> ids,
    required bool isMovie,
    required double progress,
    required int nowSeconds,
  }) async {
    if (!state.isActive || ids.isEmpty) return false;
    final token = await _validAccessToken(nowSeconds);
    if (token == null) return false;
    return _api(accessToken: token).scrobble(action, ids: ids, isMovie: isMovie, progress: progress);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
