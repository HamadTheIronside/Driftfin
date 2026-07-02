// Exercises CastController's Jellyfin-session ("Beam & Handoff") dispatch
// path end to end against a fake JellyService, without touching real
// Chromecast/DLNA discovery (mDNS/SSDP are unavailable in CI and would make
// these tests slow/flaky) or a live Jellyfin server.
import 'package:chopper/chopper.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart' as enums;
import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/account_model.dart';
import 'package:driftfin/models/credentials_model.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/cast_provider.dart';
import 'package:driftfin/providers/service_provider.dart';
import 'package:driftfin/providers/user_provider.dart';
import 'package:driftfin/providers/video_player_provider.dart';
import 'package:driftfin/util/duration_extensions.dart';

import 'support/video_player_test_support.dart';

/// Records every call made through the session-dispatch wrappers instead of
/// hitting a real server. [sessionsById] is mutable so tests can simulate the
/// remote session's play state changing (or disappearing) between polls.
class _FakeCastJellyService extends JellyService {
  _FakeCastJellyService(Ref ref, this.sessionsById) : super(ref, JellyfinOpenApi.create());

  final Map<String, SessionInfoDto> sessionsById;

  final List<Map<String, dynamic>> playingPostCalls = [];
  final List<Map<String, dynamic>> playingCommandCalls = [];

  @override
  Future<Response<List<SessionInfoDto>>> getControllableSessions() async =>
      Response(http.Response('', 200), sessionsById.values.toList());

  @override
  Future<Response> sessionsSessionIdPlayingPost({
    required String sessionId,
    required List<String> itemIds,
    int? startPositionTicks,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    playingPostCalls.add({
      'sessionId': sessionId,
      'itemIds': itemIds,
      'startPositionTicks': startPositionTicks,
      'mediaSourceId': mediaSourceId,
      'audioStreamIndex': audioStreamIndex,
      'subtitleStreamIndex': subtitleStreamIndex,
    });
    return Response(http.Response('', 200), null);
  }

  @override
  Future<Response> sessionsSessionIdPlayingCommandPost({
    required String sessionId,
    required enums.SessionsSessionIdPlayingCommandPostCommand command,
    int? seekPositionTicks,
  }) async {
    playingCommandCalls.add({
      'sessionId': sessionId,
      'command': command,
      'seekPositionTicks': seekPositionTicks,
    });
    return Response(http.Response('', 200), null);
  }
}

class _FakeCastJellyApi extends JellyApi {
  _FakeCastJellyApi(this.sessionsById);

  final Map<String, SessionInfoDto> sessionsById;
  late final _FakeCastJellyService service;

  @override
  JellyService build() {
    service = _FakeCastJellyService(ref, sessionsById);
    return service;
  }
}

class _FakeUser extends User {
  _FakeUser(this.initial);
  final AccountModel? initial;

  @override
  AccountModel? build() => initial;
}

const _remoteSession = SessionInfoDto(id: 's1', deviceName: 'Living Room TV', supportsRemoteControl: true);

const _sessionTarget = CastTarget(
  id: 'session:s1',
  name: 'Living Room TV',
  backend: CastBackend.jellyfinSession,
  session: _remoteSession,
);

typedef _Harness = ({
  ProviderContainer container,
  _FakeCastJellyService service,
  CastController controller,
  FakeBasePlayer player,
});

/// Sets up a container with the cast target's remote session already
/// registered, a fake video player, and a playback model with media loaded
/// so `CastController._currentMedia()` resolves.
Future<_Harness> _readyHarness({Map<String, SessionInfoDto>? sessionsById}) async {
  final fakeApi = _FakeCastJellyApi(sessionsById ?? {'s1': _remoteSession});
  final container = ProviderContainer(
    overrides: [
      jellyApiProvider.overrideWith(() => fakeApi),
      userProvider.overrideWith(() => _FakeUser(AccountModel(
            name: 'me',
            id: 'user-1',
            avatar: '',
            lastUsed: DateTime(2024),
            credentials: CredentialsModel.internal(url: 'http://server.local', deviceId: 'my-device'),
          ))),
      playBackModel.overrideWith((ref) => testPlaybackModel()),
      videoPlayerProvider.overrideWith((ref) => FakeVideoPlayerNotifier(ref)),
    ],
  );

  final notifier = container.read(videoPlayerProvider.notifier) as FakeVideoPlayerNotifier;
  await notifier.setupFake();

  return (
    container: container,
    service: fakeApi.service,
    controller: container.read(castProvider.notifier),
    player: notifier.fakePlayer,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connect() to a Jellyfin session hands off the exact position + track selection, then marks it connected',
      () async {
    final harness = await _readyHarness();
    addTearDown(harness.container.dispose);
    harness.player.lastState.position = const Duration(seconds: 42);
    harness.player.lastState.duration = const Duration(minutes: 10);

    await harness.controller.connect(_sessionTarget);

    expect(harness.service.playingPostCalls, hasLength(1));
    final call = harness.service.playingPostCalls.single;
    expect(call['sessionId'], 's1');
    expect(call['itemIds'], ['item-1']);
    expect(call['startPositionTicks'], const Duration(seconds: 42).toRuntimeTicks);

    final state = harness.container.read(castProvider);
    expect(state.status, CastStatus.connected);
    expect(state.playing, isTrue);
    expect(state.duration, const Duration(minutes: 10));
  });

  test('connect() reports an error and never dispatches when there is no media to cast', () async {
    final fakeApi = _FakeCastJellyApi({'s1': _remoteSession});
    final container = ProviderContainer(
      overrides: [
        jellyApiProvider.overrideWith(() => fakeApi),
        userProvider.overrideWith(() => _FakeUser(null)),
        // playBackModel left at its default (null) -> no media loaded.
        videoPlayerProvider.overrideWith((ref) => FakeVideoPlayerNotifier(ref)),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(videoPlayerProvider.notifier) as FakeVideoPlayerNotifier;
    await notifier.setupFake();

    await container.read(castProvider.notifier).connect(_sessionTarget);

    expect(fakeApi.service.playingPostCalls, isEmpty);
    expect(container.read(castProvider).status, CastStatus.error);
  });

  test('play/pause/seek send the matching playstate command to the connected session', () async {
    final harness = await _readyHarness();
    addTearDown(harness.container.dispose);
    await harness.controller.connect(_sessionTarget);

    harness.controller.pause();
    harness.controller.play();
    harness.controller.seek(const Duration(seconds: 30));

    final commands = harness.service.playingCommandCalls.map((c) => c['command']).toList();
    expect(commands, [
      enums.SessionsSessionIdPlayingCommandPostCommand.pause,
      enums.SessionsSessionIdPlayingCommandPostCommand.unpause,
      enums.SessionsSessionIdPlayingCommandPostCommand.seek,
    ]);
    expect(
      harness.service.playingCommandCalls.last['seekPositionTicks'],
      const Duration(seconds: 30).toRuntimeTicks,
    );
    expect(harness.container.read(castProvider).playing, isTrue);
    expect(harness.container.read(castProvider).position, const Duration(seconds: 30));
  });

  test('disconnect() sends a stop command and resets to the idle state', () async {
    final harness = await _readyHarness();
    addTearDown(harness.container.dispose);
    await harness.controller.connect(_sessionTarget);

    await harness.controller.disconnect();

    expect(
      harness.service.playingCommandCalls.last['command'],
      enums.SessionsSessionIdPlayingCommandPostCommand.stop,
    );
    expect(harness.container.read(castProvider).isCasting, isFalse);
    expect(harness.container.read(castProvider).status, CastStatus.disconnected);
  });

  test("the position-poll timer reflects the remote session's reported play state", () {
    fakeAsync((async) {
      late _Harness harness;
      _readyHarness().then((h) {
        harness = h;
        harness.controller.connect(_sessionTarget);
      });
      async.flushMicrotasks();

      // The remote now reports itself paused, 5 minutes in.
      harness.service.sessionsById['s1'] = const SessionInfoDto(
        id: 's1',
        deviceName: 'Living Room TV',
        supportsRemoteControl: true,
        playState: PlayerStateInfo(isPaused: true, positionTicks: 3000000000),
      );

      async.elapse(const Duration(seconds: 2));

      final state = harness.container.read(castProvider);
      expect(state.playing, isFalse);
      expect(state.position, const Duration(minutes: 5));

      harness.container.dispose();
    });
  });

  test('the position-poll timer disconnects locally once the remote session disappears', () {
    fakeAsync((async) {
      late _Harness harness;
      _readyHarness().then((h) {
        harness = h;
        harness.controller.connect(_sessionTarget);
      });
      async.flushMicrotasks();

      harness.service.sessionsById.remove('s1'); // remote ended playback / logged out

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();

      expect(harness.container.read(castProvider).isCasting, isFalse);

      harness.container.dispose();
    });
  });
}
