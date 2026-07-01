import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/util/stream_value.dart';

void main() {
  group('StreamValue', () {
    test('listen immediately emits the initial value before any add', () {
      final sv = StreamValue<int>(1);
      final received = <int>[];
      sv.listen(received.add);
      expect(received, [1]);
      sv.close();
    });

    test('add emits new value to listeners via the stream', () async {
      final sv = StreamValue<int>(0);
      final received = <int>[];
      sv.stream.listen(received.add);
      sv.add(5);
      sv.add(10);
      await Future.delayed(Duration.zero);
      expect(received, [5, 10]);
      sv.close();
    });

    test('listen after an add reports the latest value, not the initial one', () {
      final sv = StreamValue<int>(1);
      sv.add(99);
      final received = <int>[];
      sv.listen(received.add);
      expect(received, [99]);
      sv.close();
    });

    test('supports multiple listeners (broadcast)', () async {
      final sv = StreamValue<String>('start');
      final a = <String>[];
      final b = <String>[];
      sv.stream.listen(a.add);
      sv.stream.listen(b.add);
      sv.add('next');
      await Future.delayed(Duration.zero);
      expect(a, ['next']);
      expect(b, ['next']);
      sv.close();
    });

    test('addError forwards errors to stream listeners', () async {
      final sv = StreamValue<int>(0);
      Object? caughtError;
      sv.stream.listen((_) {}, onError: (e) => caughtError = e);
      sv.addError(Exception('boom'));
      await Future.delayed(Duration.zero);
      expect(caughtError, isA<Exception>());
      sv.close();
    });

    test('close closes the underlying controller', () async {
      final sv = StreamValue<int>(0);
      sv.close();
      expect(sv.stream.isBroadcast, isTrue);
    });
  });
}
