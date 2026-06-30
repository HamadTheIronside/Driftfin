import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/syncplay/time_sync_service.dart';

/// Builds a fetchUtc that reports the server clock as [ahead] of the local clock,
/// captured at call time so the NTP math sees a near-zero round trip.
Future<UtcMeasurement?> Function() serverAhead(Duration ahead) => () async {
      final now = DateTime.now().toUtc();
      return UtcMeasurement(requestReceived: now.add(ahead), responseSent: now.add(ahead));
    };

void main() {
  group('TimeSyncService before any sample', () {
    test('offset is zero and conversions are identity', () {
      final svc = TimeSyncService(fetchUtc: () async => null);
      addTearDown(svc.dispose);
      expect(svc.hasSynced, false);
      expect(svc.offset, Duration.zero);
      final t = DateTime.utc(2026, 1, 1, 12);
      expect(svc.serverToLocal(t), t);
      expect(svc.localToServer(t), t);
    });
  });

  group('TimeSyncService.start sampling', () {
    test('learns a server-ahead offset and reports it within tolerance', () async {
      final pings = <int>[];
      final svc = TimeSyncService(
        fetchUtc: serverAhead(const Duration(seconds: 10)),
        onPing: pings.add,
        fastInterval: const Duration(milliseconds: 50),
      );
      addTearDown(svc.dispose);

      svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(svc.hasSynced, true);
      expect(svc.offset.inMilliseconds, closeTo(10000, 500));
      expect(pings, isNotEmpty);
      expect(pings.first, greaterThanOrEqualTo(0));
    });

    test('serverToLocal / localToServer are inverse and apply the learned offset', () async {
      final svc = TimeSyncService(fetchUtc: serverAhead(const Duration(seconds: 10)));
      addTearDown(svc.dispose);
      svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final serverTs = DateTime.utc(2026, 6, 30, 20);
      final local = svc.serverToLocal(serverTs);
      // Server clock is ahead, so the same wall-moment is ~10s earlier locally.
      expect(serverTs.difference(local).inMilliseconds, closeTo(10000, 500));
      // Round trip back to server time recovers the original within rounding.
      expect(svc.localToServer(local).difference(serverTs).inMilliseconds.abs(), lessThan(5));
    });

    test('a null measurement yields no sample (stays unsynced)', () async {
      final svc = TimeSyncService(fetchUtc: () async => null);
      addTearDown(svc.dispose);
      svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(svc.hasSynced, false);
      expect(svc.offset, Duration.zero);
    });

    test('a thrown fetch is swallowed and does not crash sampling', () async {
      final svc = TimeSyncService(fetchUtc: () async => throw StateError('network down'));
      addTearDown(svc.dispose);
      svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(svc.hasSynced, false);
    });

    test('stop keeps the learned offset; dispose clears it', () async {
      final svc = TimeSyncService(fetchUtc: serverAhead(const Duration(seconds: 5)));
      svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(svc.hasSynced, true);

      svc.stop();
      expect(svc.hasSynced, true); // offset survives a stop
      expect(svc.offset.inMilliseconds, closeTo(5000, 500));

      svc.dispose();
      expect(svc.hasSynced, false); // dispose wipes samples
      expect(svc.offset, Duration.zero);
    });
  });
}
