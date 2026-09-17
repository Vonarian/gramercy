import 'dart:io';
import 'package:gramercy/core/isolates/config_blk_service.dart';
import 'package:gramercy/core/isolates/csv_export_worker.dart';
import 'package:gramercy/features/localization/models/localization_entry.dart';
import 'package:worker_manager/worker_manager.dart';

export 'package:gramercy/core/isolates/config_blk_service.dart';
export 'package:gramercy/core/isolates/csv_export_worker.dart';

class CsvTaskParameters {
  final String filePath;
  const CsvTaskParameters(this.filePath);
}

class FilterTaskParameters {
  final List<LocalizationEntry> entries;
  final String query;
  final FilterMode filterMode;

  const FilterTaskParameters({
    required this.entries,
    required this.query,
    this.filterMode = FilterMode.all,
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

/// Off-thread filtering task for large localization datasets
List<LocalizationEntry> filterEntriesWorker(FilterTaskParameters params) {
  final q = params.query.trim().toLowerCase();
  final matchOverridden = params.filterMode == FilterMode.overriddenOnly;
  final matchUnmodified = params.filterMode == FilterMode.unmodifiedOnly;

  if (q.isEmpty && params.filterMode == FilterMode.all) {
    return params.entries;
  }

  final results = <LocalizationEntry>[];
  for (var i = 0; i < params.entries.length; i++) {
    final entry = params.entries[i];
    if (matchOverridden && !entry.isOverridden) continue;
    if (matchUnmodified && entry.isOverridden) continue;
    if (q.isNotEmpty && !entry.matchesQuery(q)) continue;
    results.add(entry);
  }
  return results;
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

  Future<List<LocalizationEntry>> filterEntries({
    required List<LocalizationEntry> entries,
    required String query,
    FilterMode filterMode = FilterMode.all,
  }) {
    return workerManager.execute(
      () => filterEntriesWorker(FilterTaskParameters(
        entries: entries,
        query: query,
        filterMode: filterMode,
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
