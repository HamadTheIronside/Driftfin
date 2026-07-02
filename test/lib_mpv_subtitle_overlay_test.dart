import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/wrappers/players/lib_mpv.dart';

void main() {
  group('shouldHideOverlay', () {
    test('hides overlay when libass is enabled regardless of text content', () {
      expect(shouldHideOverlay(isLibassEnabled: true, text: 'Hello'), isTrue);
      expect(shouldHideOverlay(isLibassEnabled: true, text: ''), isTrue);
    });

    test('hides overlay when libass is disabled but text is empty', () {
      expect(shouldHideOverlay(isLibassEnabled: false, text: ''), isTrue);
    });

    test('shows overlay when libass is disabled and text is present', () {
      expect(shouldHideOverlay(isLibassEnabled: false, text: 'Hello'), isFalse);
    });
  });
}
