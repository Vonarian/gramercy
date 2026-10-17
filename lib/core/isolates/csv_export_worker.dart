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

  await _streamAtomicExport(baseFile, tmpFile, targetFile, params.overrides);
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

Future<void> _streamAtomicExport(
  File baseFile,
  File tmpFile,
  File targetFile,
  Map<String, String> overrides,
) async {
  final sink = tmpFile.openWrite(mode: FileMode.write);
  try {
    if (!await baseFile.exists()) {
      sink.write(_overridesOnlyContent(overrides));
    } else {
      await _streamPatchedContent(baseFile, sink, overrides);
    }
    await sink.flush();
    await sink.close();
    await tmpFile.rename(targetFile.path);
  } catch (e) {
    try {
      await sink.close();
    } catch (_) {}
    try {
      if (await tmpFile.exists()) await tmpFile.delete();
    } catch (_) {}
    rethrow;
  }
}

Future<void> _streamPatchedContent(
  File baseFile,
  IOSink sink,
  Map<String, String> overrides,
) async {
  final rawBytes = await baseFile.readAsBytes();
  if (_hasUtf8Bom(rawBytes)) {
    sink.write(wtCsvBom);
  }
  final content = utf8.decode(rawBytes);
  final lines = content.replaceAll('\r\n', '\n').split('\n');
  var isFirst = true;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    final patched = _patchSingleLine(line, i, overrides);
    if (!isFirst) {
      sink.write('\r\n');
    }
    sink.write(patched);
    isFirst = false;
  }
}

String _patchSingleLine(String line, int index, Map<String, String> overrides) {
  if (index == 0) return line;
  final cols = splitWtLine(line);
  if (cols.isEmpty) return line;
  final key = cleanWtString(cols[0]);
  if (overrides.containsKey(key)) {
    final formatted = formatWtCsvValue(overrides[key]!);
    if (cols.length > 1) {
      cols[1] = formatted;
    } else {
      cols.add(formatted);
    }
  }
  return cols.join(';');
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
