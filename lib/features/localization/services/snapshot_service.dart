import 'dart:convert';
import 'dart:io';

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

    const encoder = JsonEncoder.withIndent('  ');
    await File(filePath).writeAsString(encoder.convert(payload));

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
    final companions = presetService.deserializePreset(content);
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
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == PresetService.currentFormat) {
        return SnapshotMetadata.fromJson(decoded, file.path);
      }
    } catch (_) {
      // Corrupt or unreadable file
    }
    return null;
  }

  /// Resolves the on-disk file backing [snapshotId].
  ///
  /// Guarded by [_isSafeSnapshotId]: an id that is not a strict single path
  /// segment yields `null` before any path construction. Snapshot ids come
  /// from snapshot JSON metadata and may be attacker-chosen text if the
  /// vault file is tampered with; unguarded, `..\victim`, `../victim`, or an
  /// absolute drive path would escape [baseDir] through [p.join] and let
  /// [deleteSnapshot] and [restoreSnapshot] target arbitrary files (F2-4).
  Future<File?> _findSnapshotFile(String snapshotId) async {
    if (!_isSafeSnapshotId(snapshotId)) return null;

    final direct = File(p.join(baseDir.path, '$snapshotId.json'));
    if (await direct.exists()) return direct;

    // Raw-name fallback: still safe because the guard guarantees the id has
    // no separators or drive/stream syntax, so it stays inside [baseDir].
    final directAsIs = File(p.join(baseDir.path, snapshotId));
    if (await directAsIs.exists()) return directAsIs;

    // Metadata-enumeration fallback: structurally safe (only inspects files
    // enumerated under [baseDir]) and compared against their id metadata.
    if (!await baseDir.exists()) return null;
    final entities = await baseDir.list().toList();
    for (final entity in entities.whereType<File>()) {
      if (!entity.path.endsWith('.json')) continue;
      final meta = await _readSnapshotMetadata(entity);
      if (meta?.id == snapshotId) return entity;
    }
    return null;
  }

  /// A snapshot id is safe only when it is a strict single path segment:
  /// non-empty, with no surrounding whitespace, no separators, no drive /
  /// NTFS-stream colon syntax, not a relative-name reserve, and unchanged
  /// by [p.basename].
  bool _isSafeSnapshotId(String id) {
    return id.isNotEmpty &&
        id == id.trim() &&
        !id.contains('/') &&
        !id.contains(r'\') &&
        !id.contains(':') &&
        id != '.' &&
        id != '..' &&
        p.basename(id) == id;
  }
}
