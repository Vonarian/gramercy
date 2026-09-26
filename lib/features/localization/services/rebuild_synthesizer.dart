import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/features/localization/models/rebuild_models.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:path/path.dart' as p;

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
      final filePath = p.join(wtPath, 'lang', entry.key);
      if (File(filePath).existsSync()) {
        await worker.exportPatchedCsv(
          baseFilePath: filePath,
          targetFilePath: filePath,
          overrides: entry.value,
        );
        appliedCount += entry.value.length;
        ref.invalidate(baseStringsProvider(entry.key));
      }
    }
    return appliedCount;
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
