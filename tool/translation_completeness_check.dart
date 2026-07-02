import 'dart:convert';
import 'dart:io';

/// Completeness report for a single non-template ARB locale file.
class TranslationReport {
  const TranslationReport({
    required this.fileName,
    required this.missingKeys,
    required this.emptyKeys,
  });

  final String fileName;
  final List<String> missingKeys;
  final List<String> emptyKeys;

  bool get isComplete => missingKeys.isEmpty && emptyKeys.isEmpty;
}

/// Compares every `app_*.arb` file in [l10nDir] against the `app_en.arb`
/// template and reports keys that are missing or present-but-empty.
///
/// Keys starting with `@` (ICU metadata, `@@locale`, ...) are ignored since
/// only the template needs them.
List<TranslationReport> checkTranslationCompleteness(Directory l10nDir) {
  final templateFile = File('${l10nDir.path}/app_en.arb');
  final template =
      jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;
  final templateKeys =
      template.keys.where((key) => !key.startsWith('@')).toList()..sort();

  final arbFiles =
      l10nDir
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.arb') && file.path != templateFile.path,
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return [for (final file in arbFiles) _checkFile(file, templateKeys)];
}

TranslationReport _checkFile(File file, List<String> templateKeys) {
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final missingKeys = <String>[];
  final emptyKeys = <String>[];

  for (final key in templateKeys) {
    if (!data.containsKey(key)) {
      missingKeys.add(key);
      continue;
    }
    final value = data[key];
    if (value is String && value.trim().isEmpty) {
      emptyKeys.add(key);
    }
  }

  return TranslationReport(
    fileName: file.uri.pathSegments.last,
    missingKeys: missingKeys,
    emptyKeys: emptyKeys,
  );
}
