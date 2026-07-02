import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/providers/cast_provider.dart';

void main() {
  group('buildLoadMessage', () {
    test('builds a LOAD payload with media + metadata', () {
      final msg = buildLoadMessage(
        url: 'https://jelly.example/Videos/abc/stream?api_key=token',
        title: 'The Episode',
        imageUrl: 'https://jelly.example/Items/abc/Images/Primary',
        startAt: const Duration(seconds: 90),
      );

      expect(msg['type'], 'LOAD');
      expect(msg['autoPlay'], true);
      expect(msg['currentTime'], 90);

      final media = msg['media'] as Map<String, dynamic>;
      expect(media['contentId'], 'https://jelly.example/Videos/abc/stream?api_key=token');
      expect(media['contentType'], 'video/mp4');
      expect(media['streamType'], 'BUFFERED');

      final metadata = media['metadata'] as Map<String, dynamic>;
      expect(metadata['title'], 'The Episode');
      expect((metadata['images'] as List).first['url'], 'https://jelly.example/Items/abc/Images/Primary');
    });

    test('omits images when no imageUrl given', () {
      final msg = buildLoadMessage(url: 'https://x/y', title: 'No Image');
      final metadata = (msg['media'] as Map)['metadata'] as Map<String, dynamic>;
      expect(metadata.containsKey('images'), false);
      expect(msg['currentTime'], 0);
    });
  });

  group('CastState', () {
    test('isCasting only when connected', () {
      expect(const CastState().isCasting, false);
      expect(const CastState(status: CastStatus.connecting).isCasting, false);
      expect(const CastState(status: CastStatus.connected).isCasting, true);
    });

    test('copyWith clearDevice and clearError reset fields', () {
      const s = CastState(status: CastStatus.error, error: 'boom');
      final cleared = s.copyWith(clearError: true, status: CastStatus.disconnected);
      expect(cleared.error, null);
      expect(cleared.status, CastStatus.disconnected);
    });

    test('copyWith without clear flags preserves existing fields', () {
      const s = CastState(status: CastStatus.connected, error: 'e');
      final next = s.copyWith(playing: true);
      expect(next.error, 'e');
      expect(next.playing, true);
      expect(next.status, CastStatus.connected);
    });
  });

  group('parseMediaStatus', () {
    test('returns null for non MEDIA_STATUS messages', () {
      expect(parseMediaStatus({'type': 'RECEIVER_STATUS'}), null);
      expect(parseMediaStatus({'type': 'PONG'}), null);
    });

    test('returns null when status list is missing or empty', () {
      expect(parseMediaStatus({'type': 'MEDIA_STATUS'}), null);
      expect(parseMediaStatus({'type': 'MEDIA_STATUS', 'status': []}), null);
    });

    test('parses session id, player state, position and duration', () {
      final status = parseMediaStatus({
        'type': 'MEDIA_STATUS',
        'status': [
          {
            'mediaSessionId': 7,
            'playerState': 'PLAYING',
            'currentTime': 12.5,
            'media': {'duration': 3600.0},
          }
        ],
      });
      expect(status, isNotNull);
      expect(status!.mediaSessionId, 7);
      expect(status.playing, true);
      expect(status.position, const Duration(milliseconds: 12500));
      expect(status.duration, const Duration(seconds: 3600));
    });

    test('playing is false for PAUSED and null when playerState absent', () {
      final paused = parseMediaStatus({
        'type': 'MEDIA_STATUS',
        'status': [
          {'mediaSessionId': 1, 'playerState': 'PAUSED'}
        ],
      });
      expect(paused!.playing, false);
      expect(paused.position, null);
      expect(paused.duration, null);

      final noState = parseMediaStatus({
        'type': 'MEDIA_STATUS',
        'status': [
          {'mediaSessionId': 1}
        ],
      });
      expect(noState!.playing, null);
    });
  });

  group('formatClockTime', () {
    test('formats H:MM:SS for DLNA SEEK', () {
      expect(formatClockTime(Duration.zero), '0:00:00');
      expect(formatClockTime(const Duration(seconds: 5)), '0:00:05');
      expect(formatClockTime(const Duration(minutes: 3, seconds: 9)), '0:03:09');
      expect(formatClockTime(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(formatClockTime(const Duration(hours: 25)), '25:00:00');
    });

    test('clamps negative durations to zero', () {
      expect(formatClockTime(const Duration(seconds: -10)), '0:00:00');
    });
  });

  group('mediaCommand', () {
    test('builds a bare command with the media session id', () {
      expect(mediaCommand('PLAY', 4), {'type': 'PLAY', 'mediaSessionId': 4});
      expect(mediaCommand('PAUSE', 4), {'type': 'PAUSE', 'mediaSessionId': 4});
    });

    test('merges extra fields like SEEK currentTime and SET_VOLUME level', () {
      expect(mediaCommand('SEEK', 4, {'currentTime': 30}), {'type': 'SEEK', 'mediaSessionId': 4, 'currentTime': 30});
      expect(
          mediaCommand('SET_VOLUME', 4, {
            'volume': {'level': 0.5}
          }),
          {
            'type': 'SET_VOLUME',
            'mediaSessionId': 4,
            'volume': {'level': 0.5}
          });
    });
  });

  group('sessionCastTargets', () {
    test('builds a target per controllable session, labelled by device + user', () {
      final targets = sessionCastTargets([
        const SessionInfoDto(
          id: 's1',
          deviceId: 'dev1',
          deviceName: 'Living Room TV',
          userName: 'alice',
          supportsRemoteControl: true,
        ),
      ]);

      expect(targets, hasLength(1));
      final target = targets.single;
      expect(target.id, 'session:s1');
      expect(target.name, 'Living Room TV · alice');
      expect(target.backend, CastBackend.jellyfinSession);
      expect(target.session?.id, 's1');
    });

    test('excludes the caller\'s own device by deviceId', () {
      final targets = sessionCastTargets(
        [const SessionInfoDto(id: 's1', deviceId: 'mine', supportsRemoteControl: true)],
        myDeviceId: 'mine',
      );
      expect(targets, isEmpty);
    });

    test('excludes sessions without an id or without remote-control support', () {
      final targets = sessionCastTargets([
        const SessionInfoDto(deviceId: 'dev1', supportsRemoteControl: true), // no id
        const SessionInfoDto(id: 's2', deviceId: 'dev2', supportsRemoteControl: false), // not controllable
        const SessionInfoDto(id: 's3', deviceId: 'dev3'), // supportsRemoteControl unset
      ]);
      expect(targets, isEmpty);
    });

    test('falls back to the session id when device and user names are blank', () {
      final targets = sessionCastTargets([
        const SessionInfoDto(id: 's1', supportsRemoteControl: true),
      ]);
      expect(targets.single.name, 's1');
    });
  });

  group('buildSessionPlayRequest', () {
    test('converts the start position to runtime ticks and carries the track selection', () {
      final request = buildSessionPlayRequest(
        sessionId: 's1',
        itemId: 'item1',
        startAt: const Duration(seconds: 90),
        mediaSourceId: 'src1',
        audioStreamIndex: 2,
        subtitleStreamIndex: 3,
      );

      expect(request.sessionId, 's1');
      expect(request.itemIds, ['item1']);
      expect(request.startPositionTicks, 900000000);
      expect(request.mediaSourceId, 'src1');
      expect(request.audioStreamIndex, 2);
      expect(request.subtitleStreamIndex, 3);
    });

    test('defaults optional track/media source fields to null', () {
      final request = buildSessionPlayRequest(sessionId: 's1', itemId: 'item1', startAt: Duration.zero);

      expect(request.startPositionTicks, 0);
      expect(request.mediaSourceId, null);
      expect(request.audioStreamIndex, null);
      expect(request.subtitleStreamIndex, null);
    });
  });
}
