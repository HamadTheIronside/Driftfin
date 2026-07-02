import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/providers/cast_provider.dart';
import 'package:driftfin/screens/video_player/components/cast_button.dart';

/// A [CastController] stand-in that skips real network discovery/dispatch so
/// the "Play on…" picker can be widget-tested with a fixed target list.
class _FakeCastController extends CastController {
  _FakeCastController(super.ref);

  final List<CastTarget> connected = [];

  void seed(CastState newState) => state = newState;

  @override
  Future<void> discover() async {}

  @override
  Future<void> connect(CastTarget target) async {
    connected.add(target);
  }
}

const _chromecastTarget = CastTarget(id: 'cc:Living Room', name: 'Living Room', backend: CastBackend.chromecast);

const _sessionTarget = CastTarget(
  id: 'session:s1',
  name: 'Bedroom TV · bob',
  backend: CastBackend.jellyfinSession,
  session: SessionInfoDto(id: 's1', deviceName: 'Bedroom TV', userName: 'bob', supportsRemoteControl: true),
);

Widget _harness({required void Function(_FakeCastController) onCreated, CastState initial = const CastState()}) {
  return ProviderScope(
    overrides: [
      castProvider.overrideWith((ref) {
        final fake = _FakeCastController(ref)..seed(initial);
        onCreated(fake);
        return fake;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Center(child: CastButton())),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unified picker lists nearby cast devices and remote Jellyfin sessions in separate sections',
      (tester) async {
    await tester.pumpWidget(_harness(
      onCreated: (_) {},
      initial: const CastState(devices: [_chromecastTarget, _sessionTarget]),
    ));

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Nearby devices'), findsOneWidget);
    expect(find.text('Your other devices'), findsOneWidget);
    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text('Bedroom TV · bob'), findsOneWidget);
  });

  testWidgets('tapping a Jellyfin session target dispatches the handoff to that session', (tester) async {
    late _FakeCastController fake;
    await tester.pumpWidget(_harness(
      onCreated: (f) => fake = f,
      initial: const CastState(devices: [_chromecastTarget, _sessionTarget]),
    ));

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bedroom TV · bob'));
    await tester.pumpAndSettle();

    expect(fake.connected, hasLength(1));
    expect(fake.connected.single.backend, CastBackend.jellyfinSession);
    expect(fake.connected.single.session?.id, 's1');
  });

  testWidgets('shows a combined empty state when nothing is discovered', (tester) async {
    await tester.pumpWidget(_harness(onCreated: (_) {}));

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('No devices or active sessions found'), findsOneWidget);
  });
}
