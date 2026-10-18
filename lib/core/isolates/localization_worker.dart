import 'dart:convert';
import 'dart:io';

import 'package:gramercy/core/isolates/config_blk_service.dart';
import 'package:gramercy/core/isolates/csv_export_worker.dart';
import 'package:gramercy/core/isolates/wt_csv_text.dart';
import 'package:worker_manager/worker_manager.dart';

export 'package:gramercy/core/isolates/config_blk_service.dart';
export 'package:gramercy/core/isolates/csv_export_worker.dart';

class CsvTaskParameters {
  final String filePath;
  const CsvTaskParameters(this.filePath);
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

  // F2-6 (display path only): tolerate legacy non-UTF-8 community packs by
  // decoding with replacement characters instead of failing on the first
  // invalid byte. The export read path stays strict (fail-closed).
  final bytes = await file.readAsBytes();
  var content = utf8.decode(bytes, allowMalformed: true);
  if (content.startsWith(wtCsvBom)) {
    content = content.substring(wtCsvBom.length);
  }

  final lines = content.replaceAll('\r\n', '\n').split('\n');
  final Map<String, String> localizationMap = {};

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    // F2-3: quote-aware split; raw columns keep cleanWtString semantics.
    final cols = splitWtLine(line);
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
      () => exportPatchedCsvWorker(
        ExportTaskParameters(
          baseFilePath: baseFilePath,
          targetFilePath: targetFilePath,
          overrides: overrides,
        ),
      ),
    );
  }

  Future<ConfigBlkStatus> checkConfigBlk(String configBlkPath) {
    return workerManager.execute(
      () => checkConfigBlkStatusWorker(configBlkPath),
    );
  }

  Future<bool> patchConfigBlk(String configBlkPath) {
    return workerManager.execute(() => patchConfigBlkWorker(configBlkPath));
  }
}
