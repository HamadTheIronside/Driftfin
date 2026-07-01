import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/l10n/generated/app_localizations.dart';
import 'package:driftfin/models/recommended_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('BecauseYouWatched', () {
    test('interpolates the seed item name into the localized label', () {
      const nameSwitch = BecauseYouWatched('Dune');
      expect(nameSwitch.label(l10n), l10n.livingHomeBecauseYouWatched('Dune'));
      expect(nameSwitch.label(l10n), contains('Dune'));
    });
  });

  group('MoreFromDirector', () {
    test('interpolates the director name into the localized label', () {
      const nameSwitch = MoreFromDirector('Denis Villeneuve');
      expect(nameSwitch.label(l10n), l10n.livingHomeMoreFromDirector('Denis Villeneuve'));
      expect(nameSwitch.label(l10n), contains('Denis Villeneuve'));
    });
  });

  group('HiddenGems', () {
    test('uses the fixed localized label', () {
      const nameSwitch = HiddenGems();
      expect(nameSwitch.label(l10n), l10n.livingHomeHiddenGems);
    });
  });
}
