import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/widgets/keyboard/alpha_numeric_keyboard.dart';

Widget _harness({
  required void Function(String) onCharacter,
  TextInputType keyboardType = TextInputType.name,
  TextInputAction keyboardActionType = TextInputAction.done,
  VoidCallback? onBackspace,
  VoidCallback? onClear,
  VoidCallback? onDone,
}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AlphaNumericKeyboard(
          onCharacter: onCharacter,
          keyboardType: keyboardType,
          keyboardActionType: keyboardActionType,
          onBackspace: onBackspace ?? () {},
          onClear: onClear ?? () {},
          onDone: onDone ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders alpha layout and taps a character key', (tester) async {
    String? tapped;
    await tester.pumpWidget(_harness(onCharacter: (c) => tapped = c));
    await tester.pumpAndSettle();

    expect(find.byType(AlphaNumericKeyboard), findsOneWidget);

    await tester.tap(find.text('q').first);
    await tester.pumpAndSettle();
    expect(tapped, 'q');
  });

  testWidgets('shift toggles uppercase output', (tester) async {
    String? tapped;
    await tester.pumpWidget(_harness(onCharacter: (c) => tapped = c));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard_capslock_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Q').first);
    await tester.pumpAndSettle();
    expect(tapped, 'Q');
  });

  testWidgets('backspace, clear and done buttons invoke callbacks', (tester) async {
    var backspaceCalled = false;
    var clearCalled = false;
    var doneCalled = false;
    await tester.pumpWidget(_harness(
      onCharacter: (_) {},
      onBackspace: () => backspaceCalled = true,
      onClear: () => clearCalled = true,
      onDone: () => doneCalled = true,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.backspace_rounded));
    await tester.pumpAndSettle();
    expect(backspaceCalled, isTrue);

    await tester.tap(find.text('CLEAR'));
    await tester.pumpAndSettle();
    expect(clearCalled, isTrue);

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
    expect(doneCalled, isTrue);
  });

  testWidgets('numeric keyboard type shows number layout with helper-free rows', (tester) async {
    await tester.pumpWidget(_harness(onCharacter: (_) {}, keyboardType: TextInputType.number));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('url keyboard type shows helper buttons', (tester) async {
    await tester.pumpWidget(_harness(onCharacter: (_) {}, keyboardType: TextInputType.url));
    await tester.pumpAndSettle();

    expect(find.text('https://'), findsOneWidget);
    expect(find.text('.com'), findsOneWidget);
  });
}
