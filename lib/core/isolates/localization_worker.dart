import 'dart:io';
import 'package:gramercy/core/isolates/config_blk_service.dart';
import 'package:worker_manager/worker_manager.dart';

export 'package:gramercy/core/isolates/config_blk_service.dart';

class CsvTaskParameters {
  final String filePath;
  const CsvTaskParameters(this.filePath);
}

class ExportTaskParameters {
  final String baseFilePath;
  final String targetFilePath;
  final Map<String, String> overrides; // key -> customValue

  const ExportTaskParameters({
    required this.baseFilePath,
    required this.targetFilePath,
    required this.overrides,
  });
}

/// Cleans quotes and escaping in War Thunder strings
String cleanWtString(String raw) {
  var str = raw.trim();
  if (str.startsWith('"') && str.endsWith('"') && str.length >= 2) {
    str = str.substring(1, str.length - 1);
  }
  return str.replaceAll('""', '"');
}

/// Parses a War Thunder localization CSV file off-thread.
Future<Map<String, String>> parseCsvWorker(CsvTaskParameters params) async {
  final file = File(params.filePath);
  if (!await file.exists()) {
    return {};
  }

  var content = await file.readAsString();
  if (content.startsWith('\uFEFF')) {
    content = content.substring(1);
  }

  final lines = content.replaceAll('\r\n', '\n').split('\n');
  final Map<String, String> localizationMap = {};

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final cols = line.split(';');
    if (cols.length >= 2) {
      final key = cleanWtString(cols[0]);
      if (key.isNotEmpty) {
        final englishStr = cleanWtString(cols[1]);
        localizationMap[key] = englishStr;
      }
    }
  }

  return localizationMap;
}

/// Synthesizes and exports patched CSV back to the lang/ folder off-thread.
Future<bool> exportPatchedCsvWorker(ExportTaskParameters params) async {
  final baseFile = File(params.baseFilePath);
  final targetFile = File(params.targetFilePath);

  final targetDir = targetFile.parent;
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final backupFile = File('${params.baseFilePath}.orig');
  if (await baseFile.exists() && !await backupFile.exists()) {
    try {
      await baseFile.copy(backupFile.path);
    } catch (_) {}
  }

  final List<String> outputLines = [];

  if (await baseFile.exists()) {
    var content = await (await backupFile.exists()
        ? backupFile.readAsString()
        : baseFile.readAsString());

    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final lines = content.replaceAll('\r\n', '\n').split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      final cols = line.split(';');
      if (i > 0 && cols.isNotEmpty) {
        final key = cleanWtString(cols[0]);
        if (params.overrides.containsKey(key)) {
          final customVal = params.overrides[key]!;
          final formattedVal = customVal.contains(';') || customVal.contains('"')
              ? '"${customVal.replaceAll('"', '""')}"'
              : customVal;
          if (cols.length > 1) {
            cols[1] = formattedVal;
          } else {
            cols.add(formattedVal);
          }
        }
      }
      outputLines.add(cols.join(';'));
    }
  } else {
    outputLines.add('<ID>;<English>');
    for (final entry in params.overrides.entries) {
      final val = entry.value;
      final formattedVal = val.contains(';') || val.contains('"')
          ? '"${val.replaceAll('"', '""')}"'
          : val;
      outputLines.add('${entry.key};$formattedVal');
    }
  }

  await targetFile.writeAsString(outputLines.join('\r\n'), flush: true);
  return true;
}

// ---------------------------------------------------------------------------
// Service wrapper delegating isolate execution to worker_manager
// ---------------------------------------------------------------------------

class LocalizationWorkerService {
  Future<Map<String, String>> loadBaseStrings(String filePath) {
    return workerManager.execute(
      () => parseCsvWorker(CsvTaskParameters(filePath)),
    );
  }

  Future<bool> exportPatchedCsv({
    required String baseFilePath,
    required String targetFilePath,
    required Map<String, String> overrides,
  }) {
    return workerManager.execute(
      () => exportPatchedCsvWorker(ExportTaskParameters(
        baseFilePath: baseFilePath,
        targetFilePath: targetFilePath,
        overrides: overrides,
      )),
    );
  }

  Future<ConfigBlkStatus> checkConfigBlk(String configBlkPath) {
    return workerManager.execute(
      () => checkConfigBlkStatusWorker(configBlkPath),
    );
  }

  Future<bool> patchConfigBlk(String configBlkPath) {
    return workerManager.execute(
      () => patchConfigBlkWorker(configBlkPath),
    );
  }
}
