/// Shared text-level helpers for the War Thunder CSV export/parse pipeline.
///
/// Kept separate from the workers so both `csv_export_worker.dart` and
/// `localization_worker.dart` stay under the 200-line budget while sharing
/// one canonical CSV text behavior (quoting, splitting, BOM, sibling paths).
const String wtCsvBom = '\uFEFF';

/// A value must be double-quoted when it contains `;`, `"`, CR or LF (F2-2).
final RegExp _wtValueQuotedTrigger = RegExp(r'[;"\r\n]');

/// Restore-artifact sibling path (create-once `.orig` copy, F1-4).
String wtOrigPath(String sourcePath) => '$sourcePath.orig';

/// Staging sibling path in the target's own directory, flushed before the
/// atomic rename onto [targetPath] (F1-3).
String wtTmpPath(String targetPath) => '$targetPath.tmp';

/// Quotes [value] for CSV emission when it contains `;`, `"`, CR or LF (F2-2).
/// Doubling embedded `"` characters is part of the quoting contract.
String formatWtCsvValue(String value) => _wtValueQuotedTrigger.hasMatch(value)
    ? '"${value.replaceAll('"', '""')}"'
    : value;

/// Splits one physical CSV line into RAW columns, honouring `"` regions
/// (F2-3): a `"` toggles the quote region; a doubled `""` inside a region
/// stays inside it, so quoted `;` characters never start a new column.
///
/// Columns deliberately keep their raw text so existing cleanWtString
/// semantics stay identical downstream. A field left open at end of line is
/// treated as closed there (lenient).
List<String> splitWtLine(String line) {
  // Fast path: the overwhelming majority of game rows contain no quotes, so
  // native split is ~10x cheaper than the per-character state machine below.
  if (!line.contains('"')) return line.split(';');
  final columns = <String>[];
  final current = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('""');
        i++;
        continue;
      }
      inQuotes = !inQuotes;
    } else if (char == ';' && !inQuotes) {
      columns.add(current.toString());
      current.clear();
      continue;
    }
    current.write(char);
  }
  columns.add(current.toString());
  return columns;
}
