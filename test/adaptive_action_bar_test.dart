import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/screens/video_player/components/adaptive_action_bar.dart';

List<PlayerBarAction> _actions(int count, {List<int> disabled = const []}) => List.generate(
      count,
      (index) => PlayerBarAction(
        icon: Icons.star,
        tooltip: 'Action $index',
        onPressed: disabled.contains(index) ? null : () {},
      ),
    );

void main() {
  group('visibleBarActions', () {
    test('returns everything when it all fits', () {
      final actions = _actions(3);
      expect(visibleBarActions(actions, 200, itemExtent: 48), actions);
    });

    test('returns everything when width is unbounded', () {
      final actions = _actions(10);
      expect(visibleBarActions(actions, double.infinity, itemExtent: 48), actions);
    });

    test('reserves one slot for the overflow control when not everything fits', () {
      final actions = _actions(5);
      // 3 items fit (144px), but since not all 5 fit, one slot is reserved
      // for the overflow button, leaving room for only 2 inline actions.
      final visible = visibleBarActions(actions, 144, itemExtent: 48);
      expect(visible, actions.sublist(0, 2));
    });

    test('collapses everything when there is no room at all', () {
      final actions = _actions(4);
      expect(visibleBarActions(actions, 40, itemExtent: 48), isEmpty);
    });

    test('empty action list stays empty regardless of width', () {
      expect(visibleBarActions(const [], 500), isEmpty);
    });
  });

  group('AdaptiveActionBar', () {
    Future<void> pump(WidgetTester tester, List<PlayerBarAction> actions, double width) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: AdaptiveActionBar(actions: actions),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders every action inline when there is enough room', (tester) async {
      final actions = _actions(3);
      await pump(tester, actions, 300);

      expect(find.byType(IconButton), findsNWidgets(3));
      expect(find.byType(PopupMenuButton<PlayerBarAction>), findsNothing);
    });

    testWidgets('collapses overflowing actions behind a single menu button', (tester) async {
      final actions = _actions(5);
      await pump(tester, actions, 150);

      // Only some actions render inline; the rest are reachable through one
      // overflow control instead of causing a RenderFlex overflow.
      expect(find.byType(PopupMenuButton<PlayerBarAction>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping an overflow entry invokes its action', (tester) async {
      var tapped = false;
      final actions = [
        PlayerBarAction(icon: Icons.star, tooltip: 'Visible', onPressed: () {}),
        PlayerBarAction(icon: Icons.cloud, tooltip: 'Hidden action', onPressed: () => tapped = true),
      ];
      await pump(tester, actions, 48);

      await tester.tap(find.byType(PopupMenuButton<PlayerBarAction>));
      await tester.pumpAndSettle();

      expect(find.text('Hidden action'), findsOneWidget);
      await tester.tap(find.text('Hidden action'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders nothing for an empty action list', (tester) async {
      await pump(tester, const [], 300);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(PopupMenuButton<PlayerBarAction>), findsNothing);
    });
  });
}
