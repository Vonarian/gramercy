import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:path/path.dart' as p;

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  void _setState(ExportState exportState) => state = exportState;

  void _fail(String message) =>
      _setState(ExportState(status: ExportStatus.error, message: message));

  Future<Map<String, String>> _overridesFor(String fileName) async {
    final db = ref.read(dbProvider);
    final overridesList = await db.getOverridesForFile(fileName);
    return {for (var o in overridesList) o.stringKey: o.customValue};
  }

  Future<void> _patchConfigIfPresent(String wtPath) async {
    final worker = ref.read(workerServiceProvider);
    final configBlkPath = p.join(wtPath, 'config.blk');
    if (!File(configBlkPath).existsSync()) return;
    await worker.patchConfigBlk(configBlkPath);
    ref.invalidate(configBlkStatusProvider);
  }

  /// Runs the CSV export and honors the worker's symlink/non-regular-file
  /// refusal (audit F1-2) instead of silently reporting success.
  Future<bool> _deploy(
    String fileName,
    String targetPath,
    Map<String, String> overridesMap,
  ) async {
    final worker = ref.read(workerServiceProvider);
    final exported = await worker.exportPatchedCsv(
      baseFilePath: targetPath,
      targetFilePath: targetPath,
      overrides: overridesMap,
    );
    if (!exported) {
      AppLogger.instance.w(
        'Export refused (not a regular file): $fileName',
        tag: 'EXPORT',
      );
      _fail('Export refused: source or target is not a regular file.');
      return false;
    }

    ref.invalidate(baseStringsProvider(fileName));
    AppLogger.instance.i(
      'Deployed $fileName (${overridesMap.length} overrides)',
      tag: 'EXPORT',
    );
    _setState(
      ExportState(
        status: ExportStatus.success,
        message: 'Successfully deployed patches for $fileName to game!',
      ),
    );
    return true;
  }

  Future<bool> exportCurrentFile() async {
    _setState(
      const ExportState(
        status: ExportStatus.inProgress,
        message: 'Deploying patches to game...',
      ),
    );
    final wtPath = ref.read(wtPathProvider);
    final fileName = ref.read(selectedFileProvider);

    if (wtPath == null || wtPath.isEmpty) {
      _fail('War Thunder install path is not set.');
      return false;
    }

    try {
      final overridesMap = await _overridesFor(fileName);
      await _patchConfigIfPresent(wtPath);
      return await _deploy(
        fileName,
        p.join(wtPath, 'lang', fileName),
        overridesMap,
      );
    } catch (e, st) {
      AppLogger.instance.e(
        'Export failed for $fileName',
        tag: 'EXPORT',
        error: e,
        stack: st,
      );
      _fail('Export failed: $e');
      return false;
    }
  }

  void reset() => state = const ExportState();
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);

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
