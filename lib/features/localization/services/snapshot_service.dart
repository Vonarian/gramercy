import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../../core/database/database.dart';
import '../../../core/logging/app_logger.dart';
import '../models/snapshot_models.dart';
import 'preset_service.dart';

class SnapshotService {
  final AppDatabase db;
  final Directory baseDir;
  final PresetService presetService;

  const SnapshotService({
    required this.db,
    required this.baseDir,
    this.presetService = const PresetService(),
  });

  Future<SnapshotMetadata?> createSnapshot({
    required String label,
    String? description,
  }) async {
    final overrides = await db.getAllOverrides();
    if (overrides.isEmpty) return null;

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final now = DateTime.now().toUtc();
    final id = 'snapshot_${now.microsecondsSinceEpoch}';
    final filePath = p.join(baseDir.path, '$id.json');
    final payload = _buildPayload(id, label, description, now, overrides);

    final encoded = await Isolate.run(() => _encodeJsonWorker(payload));
    await File(filePath).writeAsString(encoded);

    AppLogger.instance.i(
      'Created snapshot [$id] "$label" with ${overrides.length} overrides',
      tag: 'SNAPSHOT',
    );

    return SnapshotMetadata(
      id: id,
      name: label,
      createdAt: now,
      description: description,
      totalOverrides: overrides.length,
      filePath: filePath,
    );
  }

  Future<List<SnapshotMetadata>> listSnapshots() async {
    if (!await baseDir.exists()) return const [];

    final snapshots = <SnapshotMetadata>[];
    final entities = await baseDir.list().toList();

    for (final entity in entities.whereType<File>()) {
      if (!entity.path.endsWith('.json')) continue;
      final snapshot = await _readSnapshotMetadata(entity);
      if (snapshot != null) {
        snapshots.add(snapshot);
      }
    }

    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshots;
  }

  Future<int> restoreSnapshot(String snapshotId) async {
    final file = await _findSnapshotFile(snapshotId);
    if (file == null || !await file.exists()) {
      return 0;
    }

    final content = await file.readAsString();
    final companions = await Isolate.run(() => _deserializeWorker(content));
    final count = await db.batchUpsertOverrides(companions);

    AppLogger.instance.i(
      'Restored snapshot [$snapshotId] ($count overrides)',
      tag: 'SNAPSHOT',
    );
    return count;
  }

  Future<bool> deleteSnapshot(String snapshotId) async {
    final file = await _findSnapshotFile(snapshotId);
    if (file == null || !await file.exists()) {
      return false;
    }

    await file.delete();
    AppLogger.instance.i(
      'Deleted snapshot [$snapshotId] from ${file.path}',
      tag: 'SNAPSHOT',
    );
    return true;
  }

  Map<String, dynamic> _buildPayload(
    String id,
    String label,
    String? description,
    DateTime now,
    List<LocalizationsOverride> overrides,
  ) {
    return {
      'format': PresetService.currentFormat,
      'version': PresetService.currentVersion,
      'source': PresetService.defaultSource,
      'id': id,
      'name': label,
      'description': ?description,
      'createdAt': now.toIso8601String(),
      'exportedAt': now.toIso8601String(),
      'totalOverrides': overrides.length,
      'overrides': overrides
          .map(
            (o) => {
              'file': o.fileName,
              'key': o.stringKey,
              'value': o.customValue,
            },
          )
          .toList(),
    };
  }

  Future<SnapshotMetadata?> _readSnapshotMetadata(File file) async {
    try {
      final content = await file.readAsString();
      final decoded = content.length <= _inlineDecodeLimit
          ? jsonDecode(content)
          : await Isolate.run(() => jsonDecode(content));
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == PresetService.currentFormat) {
        return SnapshotMetadata.fromJson(decoded, file.path);
      }
    } catch (_) {
      // Corrupt or unreadable file
    }
    return null;
  }

  /// Resolves the on-disk file backing [snapshotId]; mutates nothing.
  /// Guarded by [_isSafeSnapshotId] (F2-4): ids may be attacker-chosen
  /// (tampered vault JSON); a crafted id such as `..\victim` would escape
  /// [baseDir] via [p.join] and redirect [deleteSnapshot] or
  /// [restoreSnapshot] at arbitrary files.
  Future<File?> _findSnapshotFile(String snapshotId) async {
    if (!_isSafeSnapshotId(snapshotId)) return null;

    final direct = File(p.join(baseDir.path, '$snapshotId.json'));
    if (await direct.exists()) return direct;

    // Raw-name fallback: still safe because the guard guarantees the id has
    // no separators or drive/stream syntax, so it stays inside [baseDir].
    final directAsIs = File(p.join(baseDir.path, snapshotId));
    if (await directAsIs.exists()) return directAsIs;

    // Metadata-enumeration fallback: only files enumerated under [baseDir]
    // are inspected, and candidates must match id metadata.
    if (!await baseDir.exists()) return null;
    final entities = await baseDir.list().toList();
    for (final entity in entities.whereType<File>()) {
      if (!entity.path.endsWith('.json')) continue;
      final meta = await _readSnapshotMetadata(entity);
      if (meta?.id == snapshotId) return entity;
    }
    return null;
  }

  /// Strict single path segment guard: non-empty, trim-stable,
  /// separator- and colon-free, not `.`/`..`, and [p.basename]-stable.
  bool _isSafeSnapshotId(String id) =>
      id.isNotEmpty &&
      id == id.trim() &&
      !id.contains('/') &&
      !id.contains(r'\') &&
      !id.contains(':') &&
      id != '.' &&
      id != '..' &&
      p.basename(id) == id;

  /// Inline decode cap; bigger snapshots parse in a worker isolate.
  static const int _inlineDecodeLimit = 256 * 1024;

  static String _encodeJsonWorker(Map<String, dynamic> payload) =>
      const JsonEncoder.withIndent('  ').convert(payload);

  static List<LocalizationsOverridesCompanion> _deserializeWorker(
    String content,
  ) => const PresetService().deserializePreset(content);
}
