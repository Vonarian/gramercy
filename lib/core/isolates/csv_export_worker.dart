import 'dart:io';

import 'package:gramercy/core/isolates/localization_worker.dart';

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
          final formattedVal =
              customVal.contains(';') || customVal.contains('"')
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
