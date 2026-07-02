import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:driftfin/models/syncplay/sync_play_models.dart';
import 'package:driftfin/providers/syncplay/sync_play_relay.dart';

void main() {
  group('postSyncPlayRelayMessage', () {
    test('returns true and posts the expected JSON body on 204', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      });

      final ok = await postSyncPlayRelayMessage(
        'http://server/Driftfin/SyncPlay/g1/Messages',
        const {'authorization': 'token'},
        SyncRelayKind.chat,
        text: 'hello',
        client: client,
      );

      expect(ok, isTrue);
      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(captured!.headers['authorization'], 'token');
      expect(captured!.headers['content-type'], 'application/json');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['kind'], 'chat');
      expect(body['text'], 'hello');
      expect(body.containsKey('emoji'), isFalse);
    });

    test('encodes emoji for a reaction and omits text', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      });

      await postSyncPlayRelayMessage(
        'http://server/Driftfin/SyncPlay/g1/Messages',
        const {},
        SyncRelayKind.reaction,
        emoji: '👍',
        client: client,
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['kind'], 'reaction');
      expect(body['emoji'], '👍');
      expect(body.containsKey('text'), isFalse);
    });

    test('true for any 2xx status', () async {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        await postSyncPlayRelayMessage('http://s/x', const {}, SyncRelayKind.typing, client: client),
        isTrue,
      );
    });

    test('false on 404 (plugin not installed)', () async {
      final client = MockClient((_) async => http.Response('', 404));
      expect(
        await postSyncPlayRelayMessage('http://s/x', const {}, SyncRelayKind.chat, client: client),
        isFalse,
      );
    });

    test('false on 5xx', () async {
      final client = MockClient((_) async => http.Response('', 500));
      expect(
        await postSyncPlayRelayMessage('http://s/x', const {}, SyncRelayKind.chat, client: client),
        isFalse,
      );
    });

    test('false when the request throws, never propagates', () async {
      final client = MockClient((_) async => throw Exception('boom'));
      expect(
        await postSyncPlayRelayMessage('http://s/x', const {}, SyncRelayKind.chat, client: client),
        isFalse,
      );
    });
  });
}
