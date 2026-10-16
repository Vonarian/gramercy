import 'dart:convert';
import 'dart:io';

import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/isolates/wt_csv_text.dart';

class ExportTaskParameters {
  final String baseFilePath;
  final String targetFilePath;
  final Map<String, String> overrides;

  const ExportTaskParameters({
    required this.baseFilePath,
    required this.targetFilePath,
    required this.overrides,
  });
}

/// Synthesizes and exports patched CSV back to the lang/ folder off-thread.
///
/// Hardening: refuses symlinked paths (F1-2), synthesizes from the live base
/// file while `.orig` stays a create-once restore artifact (F1-4), emits
/// BOM- and quote-aware CSV (F2-2, F2-3, F2-7), and lands the result
/// atomically through a same-directory `.tmp` rename (F1-3).
Future<bool> exportPatchedCsvWorker(ExportTaskParameters params) async {
  final baseFile = File(params.baseFilePath);
  final targetFile = File(params.targetFilePath);
  final backupFile = File(wtOrigPath(baseFile.path));
  final tmpFile = File(wtTmpPath(targetFile.path));

  final guardedPaths = [
    baseFile.path,
    targetFile.path,
    backupFile.path,
    tmpFile.path,
  ];
  if (_anyPathIsSymlinkSync(guardedPaths)) {
    return false;
  }

  final targetDir = targetFile.parent;
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }
  await _ensureOrigBackup(baseFile, backupFile);

  final content = await _synthesizeContent(baseFile, params.overrides);
  await _writeAtomic(tmpFile, targetFile, content);
  return true;
}

/// F1-2: none of the guarded paths may be a symlink — writing through or
/// copying one would corrupt the link's target. Missing paths are fine.
bool _anyPathIsSymlinkSync(List<String> paths) {
  for (final path in paths) {
    if (FileSystemEntity.typeSync(path, followLinks: false) ==
        FileSystemEntityType.link) {
      return true;
    }
  }
  return false;
}

/// F1-4: `.orig` is created once and is never read for synthesis.
Future<void> _ensureOrigBackup(File baseFile, File backupFile) async {
  if (await baseFile.exists() && !await backupFile.exists()) {
    try {
      await baseFile.copy(backupFile.path);
    } catch (_) {}
  }
}

/// Builds the export body: fresh base rows patched with overrides, or the
/// overrides-only header branch when no base file exists.
Future<String> _synthesizeContent(
  File baseFile,
  Map<String, String> overrides,
) async {
  if (!await baseFile.exists()) {
    return _overridesOnlyContent(overrides);
  }

  final rawBytes = await baseFile.readAsBytes();
  // Strict decode stays fail-closed on export (F2-6 applies to display only).
  // Dart's utf8 decoder already consumes one leading BOM, so detect it from
  // the raw bytes, not from the decoded string (F2-7).
  final hadBom = _hasUtf8Bom(rawBytes);
  final content = utf8.decode(rawBytes);
  final rows = _patchBaseRows(
    content.replaceAll('\r\n', '\n').split('\n'),
    overrides,
  );
  return '${hadBom ? wtCsvBom : ''}${rows.join('\r\n')}';
}

/// F2-7: raw-byte BOM detection (EF BB BF).
bool _hasUtf8Bom(List<int> bytes) =>
    bytes.length >= 3 &&
    bytes[0] == 0xEF &&
    bytes[1] == 0xBB &&
    bytes[2] == 0xBF;

/// F2-7: re-emits the BOM when the base file carried one.
String _overridesOnlyContent(Map<String, String> overrides) {
  final rows = <String>['<ID>;<English>'];
  for (final entry in overrides.entries) {
    rows.add('${entry.key};${formatWtCsvValue(entry.value)}');
  }
  return rows.join('\r\n');
}

/// Patches base rows with overrides; raw columns re-join unchanged unless a
/// row key matches an override (F2-3), whose value is quoted on emission.
List<String> _patchBaseRows(List<String> lines, Map<String, String> overrides) {
  final rows = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;

    final cols = splitWtLine(line);
    if (i > 0 && cols.isNotEmpty) {
      final key = cleanWtString(cols[0]);
      if (overrides.containsKey(key)) {
        final formatted = formatWtCsvValue(overrides[key]!);
        if (cols.length > 1) {
          cols[1] = formatted;
        } else {
          cols.add(formatted);
        }
      }
    }
    rows.add(cols.join(';'));
  }
  return rows;
}

/// F1-3: writes the UTF-8 payload to the `.tmp` sibling, flushes, then
/// renames over the target. `File.rename` replaces an existing target file
/// on Windows (verified) and POSIX, so a partial write never corrupts the
/// real CSV. Byte-level emission keeps any re-emitted BOM intact (F2-7).
Future<void> _writeAtomic(File tmpFile, File targetFile, String content) async {
  try {
    await tmpFile.writeAsBytes(utf8.encode(content), flush: true);
    await tmpFile.rename(targetFile.path);
  } finally {
    try {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    } catch (_) {}
  }
}
