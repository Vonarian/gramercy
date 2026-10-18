import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/security/lang_file_guard.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:path/path.dart' as p;

/// Guard-validated deployment inputs for one export run (wtPath, fileName,
/// guarded target path).
typedef _ExportTarget = ({String wtPath, String fileName, String safePath});

/// Debounce window between an override save and the coalesced auto-deploy.
final autoExportDebounceProvider = Provider<Duration>(
  (_) => const Duration(seconds: 2),
);

class ExportNotifier extends Notifier<ExportState> {
  Timer? _autoExportTimer;

  @override
  ExportState build() {
    ref.onDispose(() => _autoExportTimer?.cancel());
    return const ExportState();
  }

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

  /// Schedules one coalesced auto-deploy after [autoExportDebounceProvider]:
  /// rapid successive saves cancel the pending timer, so edit bursts cost a
  /// single full export instead of one per save.
  void requestAutoExport() {
    _autoExportTimer?.cancel();
    _autoExportTimer = Timer(ref.read(autoExportDebounceProvider), () {
      _autoExportTimer = null;
      exportCurrentFile();
    });
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

    // Base-strings cache intentionally NOT invalidated here: overrides
    // re-merge from the drift watch stream (perf audit Critical #1).
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
    final target = _resolveExportTarget();
    if (target == null) return false;

    try {
      final overridesMap = await _overridesFor(target.fileName);
      await _patchConfigIfPresent(target.wtPath);
      return await _deploy(target.fileName, target.safePath, overridesMap);
    } catch (e, st) {
      AppLogger.instance.e(
        'Export failed for ${target.fileName}',
        tag: 'EXPORT',
        error: e,
        stack: st,
      );
      _fail('Export failed: $e');
      return false;
    }
  }

  /// Resolves path/fileName guards (audit B1) before any deployment work.
  /// Fails loud via [ExportStatus.error] and returns null when unusable.
  _ExportTarget? _resolveExportTarget() {
    final wtPath = ref.read(wtPathProvider);
    final fileName = ref.read(selectedFileProvider);

    if (wtPath == null || wtPath.isEmpty) {
      _fail('War Thunder install path is not set.');
      return null;
    }

    final targetPath = safeLangFilePath(wtPath, fileName);
    if (targetPath == null) {
      AppLogger.instance.w(
        'Refusing export for unsafe lang file name: $fileName',
        tag: 'EXPORT',
      );
      _fail('Refusing export: "fileName" is not a safe lang file name.');
      return null;
    }
    return (wtPath: wtPath, fileName: fileName, safePath: targetPath);
  }

  void reset() => state = const ExportState();

  Future<void> saveOverride({
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
      requestAutoExport();
    }
  }

  Future<void> revertOverride({
    required String fileName,
    required String key,
  }) async {
    final db = ref.read(dbProvider);
    await db.deleteOverride(fileName, key);
    if (ref.read(autoExportProvider)) {
      requestAutoExport();
    }
  }
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);

Future<void> saveLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
  required String customValue,
}) => ref
    .read(exportNotifierProvider.notifier)
    .saveOverride(fileName: fileName, key: key, customValue: customValue);

Future<void> revertLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
}) => ref
    .read(exportNotifierProvider.notifier)
    .revertOverride(fileName: fileName, key: key);
