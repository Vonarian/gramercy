import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/security/lang_file_guard.dart';
import 'package:gramercy/features/localization/models/rebuild_models.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:gramercy/features/localization/providers/environment_providers.dart';
import 'package:gramercy/features/localization/providers/strings_providers.dart';

/// Provider-anchored reload & apply flow: replaces the old RebuildSynthesizer
/// whose public API leaked WidgetRef into the service layer. UI code reads
/// [rebuildFlowProvider] and calls [reloadAndSynthesize] with values only.
class RebuildFlow {
  final Ref _ref;

  const RebuildFlow(this._ref);

  Future<List<String>> _invalidateAndGetFiles() async {
    _ref.invalidate(availableFilesProvider);
    final files = await _ref.read(availableFilesProvider.future);
    for (final file in files) {
      _ref.invalidate(baseStringsProvider(file));
    }
    return files;
  }

  Future<int> _reapplyOverrides(String wtPath) async {
    final db = _ref.read(dbProvider);
    final allOverrides = await db.getAllOverrides();
    final overridesByFile = <String, Map<String, String>>{};

    for (final ov in allOverrides) {
      overridesByFile.putIfAbsent(ov.fileName, () => {})[ov.stringKey] =
          ov.customValue;
    }

    final worker = _ref.read(workerServiceProvider);
    var appliedCount = 0;

    for (final entry in overridesByFile.entries) {
      appliedCount += await _applyEntryOverrides(worker, wtPath, entry);
    }
    return appliedCount;
  }

  /// Defense-in-depth for audit F1-1/F2-1: `file` names come from untrusted
  /// preset JSON via the vault. deserializePreset now validates strict
  /// basenames, but legacy/migrated rows could still hold traversal or
  /// absolute values that `p.join` would happily splice into a path (it does
  /// not normalize `..` and drops everything before an absolute part), so
  /// the write site re-derives the path through [safeLangFilePath] instead.
  ///
  /// Unsafe values are skipped without logging their contents (log-forging
  /// hygiene; see audit F2-5).
  Future<int> _applyEntryOverrides(
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
    _ref.invalidate(baseStringsProvider(fileName));
    return entry.value.length;
  }

  Future<RebuildSummary> reloadAndSynthesize({required String wtPath}) async {
    try {
      final files = await _invalidateAndGetFiles();
      final appliedCount = await _reapplyOverrides(wtPath);

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

final rebuildFlowProvider = Provider<RebuildFlow>(RebuildFlow.new);
