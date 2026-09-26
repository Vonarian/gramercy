import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/isolates/config_blk_service.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/features/localization/models/rebuild_models.dart';
import 'package:gramercy/features/localization/services/backup_service.dart';
import 'package:gramercy/features/localization/services/game_process_service.dart';
import 'package:gramercy/features/localization/services/rebuild_synthesizer.dart';
import 'package:path/path.dart' as p;

export 'package:gramercy/features/localization/models/rebuild_models.dart';
export 'package:gramercy/features/localization/services/backup_service.dart';
export 'package:gramercy/features/localization/services/game_process_service.dart';
export 'package:gramercy/features/localization/services/rebuild_synthesizer.dart';

class RebuildService {
  final BackupService backupService;
  final GameProcessService gameProcessService;
  final RebuildSynthesizer synthesizer;

  const RebuildService({
    this.backupService = const BackupService(),
    this.gameProcessService = const GameProcessService(),
    this.synthesizer = const RebuildSynthesizer(),
  });

  bool _isTargetFile(String path) {
    final lower = path.toLowerCase();
    final base = p.basename(lower);
    return lower.endsWith('.csv') ||
        lower.endsWith('.orig') ||
        base == 'localization.blk';
  }

  Future<int> _deleteTargetFiles(Directory langDir) async {
    var deleted = 0;
    await for (final entity in langDir.list(recursive: false)) {
      if (entity is File && _isTargetFile(entity.path)) {
        try {
          await entity.delete();
          deleted++;
        } catch (_) {}
      }
    }
    return deleted;
  }

  Future<List<String>> _findRemainingFiles(Directory langDir) async {
    final remaining = <String>[];
    await for (final entity in langDir.list(recursive: false)) {
      if (entity is File && _isTargetFile(entity.path)) {
        remaining.add(p.basename(entity.path));
      }
    }
    return remaining;
  }

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

      final backupPath = await backupService.backupLocalizationFolder(wtPath);
      final deleted = await _deleteTargetFiles(langDir);
      final remaining = await _findRemainingFiles(langDir);

      if (remaining.isNotEmpty) {
        AppLogger.instance.w(
          'Purge incomplete: ${remaining.length} files locked on disk',
          tag: 'REBUILD',
        );
        return PurgeResult(
          success: false,
          deletedCount: deleted,
          backupPath: backupPath,
          remainingFiles: remaining,
          errorMessage:
              'Could not delete ${remaining.length} file(s) (${remaining.take(3).join(', ')}). '
              'The file is in use by War Thunder. Please close the game completely and try again.',
        );
      }

      AppLogger.instance.i(
        'Purged $deleted localization files from ${langDir.path}',
        tag: 'REBUILD',
      );
      return PurgeResult(
        success: true,
        deletedCount: deleted,
        backupPath: backupPath,
        purgedAt: DateTime.now(),
      );
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

  Future<FreshStringsStatus> checkFreshStringsExist(
    String wtPath, {
    DateTime? since,
  }) async {
    if (wtPath.isEmpty) {
      return const FreshStringsStatus(hasFiles: false, fileCount: 0);
    }

    final langDir = Directory(p.join(wtPath, 'lang'));
    if (!await langDir.exists()) {
      return const FreshStringsStatus(hasFiles: false, fileCount: 0);
    }

    final keyFound = <String>[];
    var count = 0;
    final threshold = since?.subtract(const Duration(seconds: 2));

    try {
      await for (final entity in langDir.list(recursive: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.csv')) {
          if (await entity.length() > 0) {
            if (threshold != null) {
              final modified = await entity.lastModified();
              if (modified.isBefore(threshold)) continue;
            }
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

  Future<bool> isGameRunning() => gameProcessService.isGameRunning();

  Future<bool> launchWarThunder(String wtPath) =>
      gameProcessService.launchWarThunder(wtPath);

  Future<RebuildSummary> reloadAndSynthesize({
    required WidgetRef ref,
    required String wtPath,
  }) => synthesizer.reloadAndSynthesize(ref: ref, wtPath: wtPath);
}

final rebuildServiceProvider = Provider<RebuildService>((ref) {
  return const RebuildService();
});
