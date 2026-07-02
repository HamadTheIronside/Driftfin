import 'dart:io';

import 'translation_completeness_check.dart';

/// CI entry point: fails (non-zero exit) if any locale ARB file under
/// lib/l10n is missing or has an empty value for a key that exists in the
/// app_en.arb template. Run with: dart run tool/check_translations.dart
void main() {
  final l10nDir = Directory('lib/l10n');
  final reports = checkTranslationCompleteness(l10nDir);

  final incomplete = <TranslationReport>[];
  for (final report in reports) {
    if (!report.isComplete) {
      incomplete.add(report);
    }
  }

  if (incomplete.isEmpty) {
    final count = reports.length;
    stdout.writeln('All $count translation files are 100% complete.');
    return;
  }

  final fileCount = incomplete.length;
  stderr.writeln('Incomplete translations in $fileCount file(s):');
  for (final report in incomplete) {
    final missing = report.missingKeys.length;
    final empty = report.emptyKeys.length;
    stderr.writeln('  ${report.fileName}: $missing missing, $empty empty');
    for (final key in report.missingKeys) {
      stderr.writeln('    missing: $key');
    }
    for (final key in report.emptyKeys) {
      stderr.writeln('    empty:   $key');
    }
  }
  exitCode = 1;
}
