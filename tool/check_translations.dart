import 'dart:io';

import 'translation_completeness_check.dart';

/// CI entry point: fails (non-zero exit) if any locale ARB file under
/// lib/l10n is missing or has an empty value for a key that exists in the
/// app_en.arb template. Run with: dart run tool/check_translations.dart
void main() {
  final l10nDir = Directory('lib/l10n');
  final reports = checkTranslationCompleteness(l10nDir);
  final incomplete = reports.where((report) => !report.isComplete).toList();

  if (incomplete.isEmpty) {
    stdout.writeln(
      'All ${reports.length} translation files are 100% complete.',
    );
    return;
  }

  stderr.writeln(
    'Incomplete translations found in ${incomplete.length} file(s):',
  );
  for (final report in incomplete) {
    stderr.writeln(
      '  ${report.fileName}: ${report.missingKeys.length} missing, '
      '${report.emptyKeys.length} empty',
    );
    for (final key in report.missingKeys) {
      stderr.writeln('    missing: $key');
    }
    for (final key in report.emptyKeys) {
      stderr.writeln('    empty:   $key');
    }
  }
  exitCode = 1;
}
