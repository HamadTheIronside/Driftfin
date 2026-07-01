import 'dart:convert';

import 'package:driftfin/models/settings/key_combinations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyCombination equality/hashCode', () {
    test('equal by keyId, not object identity', () {
      final a = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      final b = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      expect(a, b);
    });

    test('differs when any of the 4 fields differ', () {
      final a = KeyCombination(key: LogicalKeyboardKey.keyA);
      final b = KeyCombination(key: LogicalKeyboardKey.keyB);
      expect(a == b, isFalse);
    });

    test('two empty combinations are equal', () {
      expect(KeyCombination(), KeyCombination());
    });
  });

  group('KeyCombination.containsSameSet', () {
    test('matches when primary key+modifier are the same', () {
      final a = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      final b = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      expect(a.containsSameSet(b), isTrue);
    });

    test('two empty combinations contain the same (empty) set', () {
      expect(KeyCombination().containsSameSet(KeyCombination()), isTrue);
    });

    test('matches when this altKey equals the other\'s primary key (asymmetric relation)', () {
      final a = KeyCombination(altKey: LogicalKeyboardKey.keyA, altModifier: LogicalKeyboardKey.control);
      final b = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      expect(a.containsSameSet(b), isTrue);
    });

    test('is not necessarily symmetric: differing setups can disagree on direction', () {
      // a's primary key is null, b's primary key is keyA -> a's first clause fails (null != keyA).
      // a's altKey is keyB which doesn't match b's primary key (keyA) either -> a.containsSameSet(b) is false.
      final a = KeyCombination(altKey: LogicalKeyboardKey.keyB, altModifier: LogicalKeyboardKey.control);
      final b = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      expect(a.containsSameSet(b), isFalse);
      // b.containsSameSet(a): b's primary key (keyA) doesn't match a's primary key (null) -> first clause fails.
      // b's altKey is null, so the second clause compares null to a's primary key (null) -> true,
      // and modifierMatches(b.altModifier=null, a.modifier=null) -> true, so the whole thing is true.
      expect(b.containsSameSet(a), isTrue);
    });

    test('does not match on differing keys', () {
      final a = KeyCombination(key: LogicalKeyboardKey.keyA);
      final b = KeyCombination(key: LogicalKeyboardKey.keyB);
      expect(a.containsSameSet(b), isFalse);
    });
  });

  group('KeyCombination.label / altLabel', () {
    test('joins modifier and key labels with " + "', () {
      final combo = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.shift);
      expect(combo.label, 'Shift ⇧ + A');
    });

    test('is empty when both key and modifier are null', () {
      expect(KeyCombination().label, '');
    });

    test('altLabel mirrors label logic for the alt slot', () {
      final combo = KeyCombination(altKey: LogicalKeyboardKey.keyB, altModifier: LogicalKeyboardKey.control);
      expect(combo.altLabel, 'Ctrl + B');
    });
  });

  group('KeyCombination.altSet', () {
    test('null when there is no altKey', () {
      final combo = KeyCombination(key: LogicalKeyboardKey.keyA);
      expect(combo.altSet, isNull);
    });

    test('promotes the alt binding to the primary slot', () {
      final combo = KeyCombination(altKey: LogicalKeyboardKey.keyB, altModifier: LogicalKeyboardKey.alt);
      final promoted = combo.altSet;
      expect(promoted?.key, LogicalKeyboardKey.keyB);
      expect(promoted?.modifier, LogicalKeyboardKey.alt);
    });

    test('the returned combo still carries the old alt fields unchanged', () {
      final combo = KeyCombination(altKey: LogicalKeyboardKey.keyB, altModifier: LogicalKeyboardKey.alt);
      final promoted = combo.altSet;
      expect(promoted?.altKey, LogicalKeyboardKey.keyB);
      expect(promoted?.altModifier, LogicalKeyboardKey.alt);
    });
  });

  group('KeyCombination.setKeys', () {
    test('normal set replaces the primary key/modifier only', () {
      final combo = KeyCombination(altKey: LogicalKeyboardKey.keyC);
      final updated = combo.setKeys(LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      expect(updated.key, LogicalKeyboardKey.keyA);
      expect(updated.modifier, LogicalKeyboardKey.control);
      expect(updated.altKey, LogicalKeyboardKey.keyC, reason: 'alt slot untouched by a normal set');
    });

    test('setKeys(null) with an existing altKey promotes alt to primary and clears alt', () {
      final combo = KeyCombination(altKey: LogicalKeyboardKey.keyB, altModifier: LogicalKeyboardKey.alt);
      final updated = combo.setKeys(null);
      expect(updated.key, LogicalKeyboardKey.keyB);
      expect(updated.modifier, LogicalKeyboardKey.alt);
      expect(updated.altKey, isNull);
      expect(updated.altModifier, isNull);
    });

    test('setKeys(null) with no altKey clears both key and modifier', () {
      final combo = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      final updated = combo.setKeys(null);
      expect(updated.key, isNull);
      expect(updated.modifier, isNull);
    });

    test('alt:true sets only the alt slot, leaving the primary slot untouched', () {
      final combo = KeyCombination(key: LogicalKeyboardKey.keyA, modifier: LogicalKeyboardKey.control);
      final updated = combo.setKeys(LogicalKeyboardKey.keyZ, modifier: LogicalKeyboardKey.shift, alt: true);
      expect(updated.key, LogicalKeyboardKey.keyA);
      expect(updated.modifier, LogicalKeyboardKey.control);
      expect(updated.altKey, LogicalKeyboardKey.keyZ);
      expect(updated.altModifier, LogicalKeyboardKey.shift);
    });
  });

  group('KeyCombination.modifierMatches', () {
    test('exact equality matches', () {
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftLeft), isTrue);
    });

    test('both null matches (exact-equality short-circuit)', () {
      expect(KeyCombination.modifierMatches(null, null), isTrue);
    });

    test('one null, one non-null does not match', () {
      expect(KeyCombination.modifierMatches(null, LogicalKeyboardKey.shift), isFalse);
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.shift, null), isFalse);
    });

    test('normalizes any super/meta variant as matching another super/meta variant', () {
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight), isTrue);
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.meta, LogicalKeyboardKey.superKey), isTrue);
    });

    test('does not normalize left/right variants for shift/alt/ctrl', () {
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight), isFalse);
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight), isFalse);
      expect(KeyCombination.modifierMatches(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight), isFalse);
    });
  });

  group('LogicalKeyboardSerializer', () {
    const serializer = LogicalKeyboardSerializer();

    test('round-trips a known key through JSON', () {
      final json = serializer.toJson(LogicalKeyboardKey.keyA);
      expect(serializer.fromJson(json), LogicalKeyboardKey.keyA);
    });

    test('falls back to LogicalKeyboardKey.abort for an unknown keyId', () {
      final unknownJson = jsonEncode('999999999999');
      expect(serializer.fromJson(unknownJson), LogicalKeyboardKey.abort);
    });

    test('throws on non-numeric garbage input', () {
      expect(() => serializer.fromJson(jsonEncode('not-a-number')), throwsFormatException);
    });

    test('toJson double-encodes the keyId as a JSON string', () {
      final json = serializer.toJson(LogicalKeyboardKey.keyA);
      expect(json, jsonEncode(LogicalKeyboardKey.keyA.keyId.toString()));
    });
  });

  group('KeyCombination.fromJson / toJson', () {
    test('round-trips a full combination', () {
      final combo = KeyCombination(
        key: LogicalKeyboardKey.keyA,
        modifier: LogicalKeyboardKey.control,
        altKey: LogicalKeyboardKey.keyB,
        altModifier: LogicalKeyboardKey.alt,
      );
      final restored = KeyCombination.fromJson(combo.toJson());
      expect(restored, combo);
    });

    test('round-trips an all-null combination', () {
      final combo = KeyCombination();
      final restored = KeyCombination.fromJson(combo.toJson());
      expect(restored, combo);
    });
  });

  group('LogicalKeyExtension.label', () {
    test('space has a dedicated label', () {
      expect(LogicalKeyboardKey.space.label, 'Space');
    });

    test('arrow keys map to unicode arrows', () {
      expect(LogicalKeyboardKey.arrowUp.label, '↑');
      expect(LogicalKeyboardKey.arrowDown.label, '↓');
      expect(LogicalKeyboardKey.arrowLeft.label, '←');
      expect(LogicalKeyboardKey.arrowRight.label, '→');
    });

    test('shift shows the same label regardless of platform', () {
      expect(LogicalKeyboardKey.shift.label, 'Shift ⇧');
    });

    test('falls back to keyLabel for an unmapped key', () {
      expect(LogicalKeyboardKey.keyA.label, 'A');
    });
  });

  group('KeyMapExtension.setOrRemove', () {
    final defaultShortcut = KeyCombination(key: LogicalKeyboardKey.keyA);
    final defaults = {'action': defaultShortcut};

    test('setting a value equal to the default removes any override', () {
      final current = {'action': KeyCombination(key: LogicalKeyboardKey.keyZ)};
      final result = current.setOrRemove(MapEntry('action', defaultShortcut), defaults);
      expect(result.containsKey('action'), isFalse);
    });

    test('setting a different value adds/updates the override', () {
      final current = <String, KeyCombination>{};
      final newCombo = KeyCombination(key: LogicalKeyboardKey.keyZ);
      final result = current.setOrRemove(MapEntry('action', newCombo), defaults);
      expect(result['action'], newCombo);
    });

    test('does not mutate the receiver map', () {
      final current = {'action': KeyCombination(key: LogicalKeyboardKey.keyZ)};
      current.setOrRemove(MapEntry('action', defaultShortcut), defaults);
      expect(current.containsKey('action'), isTrue, reason: 'original map must be untouched');
    });
  });
}
