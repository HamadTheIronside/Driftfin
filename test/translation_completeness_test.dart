import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/translation_completeness_check.dart';

void main() {
  test('every locale ARB file has a non-empty value for every template key', () {
    final reports = checkTranslationCompleteness(Directory('lib/l10n'));

    expect(reports, isNotEmpty);

    final incomplete = reports.where((report) => !report.isComplete).toList();
    final details = [
      for (final report in incomplete) '${report.fileName}: missing=${report.missingKeys} empty=${report.emptyKeys}',
    ].join('\n');

    expect(incomplete, isEmpty, reason: 'Incomplete translation files:\n$details');
  });
}
