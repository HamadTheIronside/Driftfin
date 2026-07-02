import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/translation_completeness_check.dart';

void main() {
  test('every locale ARB file has a non-empty value for every key', () {
    final reports = checkTranslationCompleteness(Directory('lib/l10n'));

    expect(reports, isNotEmpty);

    final incomplete = <TranslationReport>[];
    for (final report in reports) {
      if (!report.isComplete) {
        incomplete.add(report);
      }
    }

    final details = <String>[];
    for (final report in incomplete) {
      final missing = report.missingKeys;
      final empty = report.emptyKeys;
      details.add('${report.fileName}: missing=$missing empty=$empty');
    }
    final reason = 'Incomplete translation files:\n${details.join('\n')}';

    expect(incomplete, isEmpty, reason: reason);
  });
}
