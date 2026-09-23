import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/isolates/config_blk_service.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/features/localization/models/rebuild_models.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:path/path.dart' as p;

export 'package:gramercy/features/localization/models/rebuild_models.dart';

class RebuildService {
  const RebuildService();

  Future<PurgeResult> purgeLocalizationCache(String wtPath) async {
    if (wtPath.isEmpty) {
      return const PurgeResult(
        success: false,
        errorMessage: 'Invalid War Thunder path.',
      );
    }

    try {
      final configBlk = File(p.join(wtPath, 'config.blk'));
      if (await configBlk.exists()) {
        await patchConfigBlkWorker(configBlk.path);
      }

      final langDir = Directory(p.join(wtPath, 'lang'));
      if (!await langDir.exists()) {
        return const PurgeResult(success: true, deletedCount: 0);
      }

      var deleted = 0;
      await for (final entity in langDir.list()) {
        if (entity is File) {
          final lower = entity.path.toLowerCase();
          if (lower.endsWith('.csv') || lower.endsWith('.orig')) {
            await entity.delete();
            deleted++;
          }
        }
      }

      AppLogger.instance.i(
        'Purged $deleted localization files from ${langDir.path}',
        tag: 'REBUILD',
      );
      return PurgeResult(success: true, deletedCount: deleted);
    } catch (e, st) {
      AppLogger.instance.e(
        'Failed to purge localization cache',
        tag: 'REBUILD',
        error: e,
        stack: st,
      );
      return PurgeResult(success: false, errorMessage: e.toString());
    }
  }

  Future<FreshStringsStatus> checkFreshStringsExist(String wtPath) async {
    if (wtPath.isEmpty) {
      return const FreshStringsStatus(hasFiles: false, fileCount: 0);
    }

    final langDir = Directory(p.join(wtPath, 'lang'));
    if (!await langDir.exists()) {
      return const FreshStringsStatus(hasFiles: false, fileCount: 0);
    }

    final keyFound = <String>[];
    var count = 0;

    try {
      await for (final entity in langDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.csv')) {
          if (await entity.length() > 0) {
            count++;
            keyFound.add(p.basename(entity.path));
          }
        }
      }
    } catch (_) {}

    return FreshStringsStatus(
      hasFiles: count > 0,
      fileCount: count,
      keyFilesFound: keyFound,
    );
  }

  Future<bool> launchWarThunder(String wtPath) async {
    try {
      if (Platform.isWindows) {
        final launcher = File(p.join(wtPath, 'launcher.exe'));
        final aces = File(p.join(wtPath, 'win64', 'aces.exe'));
        final acesRoot = File(p.join(wtPath, 'aces.exe'));

        if (await launcher.exists()) {
          await Process.start(
            launcher.path,
            [],
            mode: ProcessStartMode.detached,
          );
          return true;
        } else if (await aces.exists()) {
          await Process.start(aces.path, [], mode: ProcessStartMode.detached);
          return true;
        } else if (await acesRoot.exists()) {
          await Process.start(
            acesRoot.path,
            [],
            mode: ProcessStartMode.detached,
          );
          return true;
        } else {
          await Process.run('cmd', ['/c', 'start', 'steam://rungameid/236390']);
          return true;
        }
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', ['steam://rungameid/236390']);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', ['steam://rungameid/236390']);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.w(
        'Could not auto-launch War Thunder: $e',
        tag: 'REBUILD',
      );
      return false;
    }
  }

  Future<RebuildSummary> reloadAndSynthesize({
    required WidgetRef ref,
    required String wtPath,
  }) async {
    try {
      ref.invalidate(availableFilesProvider);
      final files = await ref.read(availableFilesProvider.future);

      for (final file in files) {
        ref.invalidate(baseStringsProvider(file));
      }

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

final rebuildServiceProvider = Provider<RebuildService>((ref) {
  return const RebuildService();
});
