import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/security/lang_file_guard.dart';
import 'package:gramercy/features/localization/models/rebuild_models.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class RebuildSynthesizer {
  const RebuildSynthesizer();

  Future<List<String>> _invalidateAndGetFiles(WidgetRef ref) async {
    ref.invalidate(availableFilesProvider);
    final files = await ref.read(availableFilesProvider.future);
    for (final file in files) {
      ref.invalidate(baseStringsProvider(file));
    }
    return files;
  }

  Future<int> _reapplyOverrides(WidgetRef ref, String wtPath) async {
    final db = ref.read(dbProvider);
    final allOverrides = await db.getAllOverrides();
    final overridesByFile = <String, Map<String, String>>{};

    for (final ov in allOverrides) {
      overridesByFile.putIfAbsent(ov.fileName, () => {})[ov.stringKey] =
          ov.customValue;
    }

    final worker = ref.read(workerServiceProvider);
    var appliedCount = 0;

    for (final entry in overridesByFile.entries) {
      appliedCount += await _applyEntryOverrides(ref, worker, wtPath, entry);
    }
    return appliedCount;
  }

  /// Defense-in-depth for audit F1-1/F2-1: `file` names come from untrusted
  /// preset JSON via the vault. deserializePreset now validates strict
  /// basenames, but legacy/migrated rows could still hold traversal or
  /// absolute values that `p.join` would happily splice into a path (it does
  /// not normalize `..` and drops everything before an absolute part), so the
  /// write site re-derives the path through [safeLangFilePath] instead.
  ///
  /// Unsafe values are skipped without logging their contents (log-forging
  /// hygiene; see audit F2-5).
  Future<int> _applyEntryOverrides(
    WidgetRef ref,
    LocalizationWorkerService worker,
    String wtPath,
    MapEntry<String, Map<String, String>> entry,
  ) async {
    final fileName = entry.key;
    final filePath = safeLangFilePath(wtPath, fileName);
    if (filePath == null) {
      AppLogger.instance.w(
        'Skipped unsafe override target <redacted>',
        tag: 'REBUILD',
      );
      return 0;
    }
    if (!File(filePath).existsSync()) return 0;

    // The worker refuses symlinks/non-regular files (audit F1-2): a false
    // result must not count as applied overrides.
    final exported = await worker.exportPatchedCsv(
      baseFilePath: filePath,
      targetFilePath: filePath,
      overrides: entry.value,
    );
    if (!exported) {
      AppLogger.instance.w(
        'Export refused during re-apply <redacted>',
        tag: 'REBUILD',
      );
      return 0;
    }
    ref.invalidate(baseStringsProvider(fileName));
    return entry.value.length;
  }

  Future<RebuildSummary> reloadAndSynthesize({
    required WidgetRef ref,
    required String wtPath,
  }) async {
    try {
      final files = await _invalidateAndGetFiles(ref);
      final appliedCount = await _reapplyOverrides(ref, wtPath);

      AppLogger.instance.i(
        'Reloaded ${files.length} files and re-applied $appliedCount overrides',
        tag: 'REBUILD',
      );
      return RebuildSummary(
        success: true,
        filesReloaded: files.length,
        overridesApplied: appliedCount,
      );
    } catch (e, st) {
      AppLogger.instance.e(
        'Error during reload and synthesis',
        tag: 'REBUILD',
        error: e,
        stack: st,
      );
      return RebuildSummary(success: false, errorMessage: e.toString());
    }
  }
}
