import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/widgets/navigation_scaffold/components/navigation_button.dart';
import 'package:driftfin/widgets/shared/item_actions.dart';

Widget _harness(NavigationButton button) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('vertical unselected button renders icon and reacts to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_harness(NavigationButton(
      label: 'Home',
      selectedIcon: const Icon(Icons.home),
      icon: const Icon(Icons.home_outlined),
      onPressed: () => tapped = true,
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('selected + expanded horizontal button shows label and selected icon', (tester) async {
    await tester.pumpWidget(_harness(const NavigationButton(
      label: 'Library',
      selectedIcon: Icon(Icons.folder),
      icon: Icon(Icons.folder_outlined),
      selected: true,
      horizontal: true,
      expanded: true,
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.folder), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('horizontal expanded button with badge and trailing renders without throwing', (tester) async {
    // The trailing PopupMenuButton is only built while the InkWell reports
    // onHover == true (see navigation_button.dart), which isn't reliably
    // reproducible via synthetic pointer events in this widget tree. This
    // test sticks to verifying the button builds cleanly with badge +
    // trailing configured, rather than asserting the hover-only popup opens.
    await tester.pumpWidget(_harness(NavigationButton(
      label: 'Movies',
      selectedIcon: const Icon(Icons.movie),
      icon: const Icon(Icons.movie_outlined),
      horizontal: true,
      expanded: true,
      badge: const Icon(Icons.circle, size: 8),
      trailing: [ItemActionButton(label: const Text('Refresh'))],
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('custom icon and navFocusNode variant renders without a default icon', (tester) async {
    await tester.pumpWidget(_harness(const NavigationButton(
      label: null,
      selectedIcon: Icon(Icons.star),
      icon: Icon(Icons.star_border),
      customIcon: Icon(Icons.image),
      navFocusNode: true,
      selected: true,
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });
}
