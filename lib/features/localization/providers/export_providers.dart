import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:path/path.dart' as p;

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  Future<bool> exportCurrentFile() async {
    state = const ExportState(status: ExportStatus.inProgress, message: 'Deploying patches to game...');
    final wtPath = ref.read(wtPathProvider);
    final fileName = ref.read(selectedFileProvider);

    if (wtPath == null || wtPath.isEmpty) {
      state = const ExportState(status: ExportStatus.error, message: 'War Thunder install path is not set.');
      return false;
    }

    try {
      final db = ref.read(dbProvider);
      final overridesList = await db.getOverridesForFile(fileName);
      final overridesMap = {for (var o in overridesList) o.stringKey: o.customValue};

      final worker = ref.read(workerServiceProvider);
      final targetPath = p.join(wtPath, 'lang', fileName);

      final configBlkPath = p.join(wtPath, 'config.blk');
      if (File(configBlkPath).existsSync()) {
        await worker.patchConfigBlk(configBlkPath);
        ref.invalidate(configBlkStatusProvider);
      }

      await worker.exportPatchedCsv(
        baseFilePath: targetPath,
        targetFilePath: targetPath,
        overrides: overridesMap,
      );

      ref.invalidate(baseStringsProvider(fileName));

      AppLogger.instance.i('Deployed $fileName (${overridesMap.length} overrides)', tag: 'EXPORT');
      state = ExportState(
        status: ExportStatus.success,
        message: 'Successfully deployed patches for $fileName to game!',
      );
      return true;
    } catch (e, st) {
      AppLogger.instance.e('Export failed for $fileName', tag: 'EXPORT', error: e, stack: st);
      state = ExportState(status: ExportStatus.error, message: 'Export failed: $e');
      return false;
    }
  }

  void reset() => state = const ExportState();
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(ExportNotifier.new);

Future<void> saveLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
  required String customValue,
}) async {
  final db = ref.read(dbProvider);
  await db.saveOverride(
    LocalizationsOverridesCompanion.insert(
      fileName: fileName,
      stringKey: key,
      customValue: customValue,
    ),
  );

  if (ref.read(autoExportProvider)) {
    await ref.read(exportNotifierProvider.notifier).exportCurrentFile();
  }
}

Future<void> revertLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
}) async {
  final db = ref.read(dbProvider);
  await db.deleteOverride(fileName, key);

  if (ref.read(autoExportProvider)) {
    await ref.read(exportNotifierProvider.notifier).exportCurrentFile();
  }
}
