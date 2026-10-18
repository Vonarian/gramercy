import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/security/lang_file_guard.dart';

final presetServiceProvider = Provider<PresetService>((ref) {
  return const PresetService();
});

class PresetService {
  const PresetService();

  static const String currentFormat = 'gramercy_preset_v1';
  static const String currentVersion = '1.0';
  static const String defaultSource = 'Gramercy WT Localization Cockpit';

  Future<List<LocalizationsOverride>> loadAllOverrides(AppDatabase db) =>
      db.getAllOverrides();

  Future<int> importPreset(AppDatabase db, String jsonString) async {
    final companions = deserializePreset(jsonString);
    if (companions.isEmpty) return 0;
    return db.batchUpsertOverrides(companions);
  }

  /// Isolate-backed [importPreset]: the untrusted-JSON parse/companion build
  /// runs off the main isolate (community presets can be large); the
  /// [FormatException] for unsafe target files (F1-1/F2-1) still propagates.
  Future<int> importPresetAsync(AppDatabase db, String jsonString) async {
    final companions = await Isolate.run(() => _companionsFrom(jsonString));
    if (companions.isEmpty) return 0;
    return db.batchUpsertOverrides(companions);
  }

  Future<int> importCompanions(
    AppDatabase db,
    List<LocalizationsOverridesCompanion> companions,
  ) => db.batchUpsertOverrides(companions);
  String serializePreset(
    List<LocalizationsOverride> overrides, {
    DateTime? exportedAt,
    String? source,
  }) {
    final jsonResult = _encodePresetJson(
      _buildPayload(overrides, exportedAt: exportedAt, source: source),
    );
    AppLogger.instance.i(
      'Serialized ${overrides.length} overrides to preset format',
      tag: 'PRESET',
    );
    return jsonResult;
  }

  /// Isolate-backed [serializePreset] twin: identical bytes for identical
  /// inputs ([exportedAt]/[source] pinned), with encoding off the main
  /// isolate. Logging stays on the caller isolate.
  Future<String> serializePresetAsync(
    List<LocalizationsOverride> overrides, {
    DateTime? exportedAt,
    String? source,
  }) async {
    final jsonResult = await Isolate.run(
      () => _encodePresetJson(
        _buildPayload(overrides, exportedAt: exportedAt, source: source),
      ),
    );
    AppLogger.instance.i(
      'Serialized ${overrides.length} overrides to preset format',
      tag: 'PRESET',
    );
    return jsonResult;
  }

  static String _encodePresetJson(Map<String, Object> payload) =>
      const JsonEncoder.withIndent('  ').convert(payload);

  Map<String, Object> _buildPayload(
    List<LocalizationsOverride> overrides, {
    DateTime? exportedAt,
    String? source,
  }) {
    return {
      'format': currentFormat,
      'version': currentVersion,
      'source': source ?? defaultSource,
      'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
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

  List<LocalizationsOverridesCompanion> deserializePreset(String jsonString) {
    final companions = _companionsFrom(jsonString);
    AppLogger.instance.i(
      'Deserialized ${companions.length} valid overrides from preset JSON',
      tag: 'PRESET',
    );
    return companions;
  }

  /// Pure parse/companion-build core, shared by the sync and isolate-backed
  /// import paths; contains no logging so it stays worker-isolate safe.
  List<LocalizationsOverridesCompanion> _companionsFrom(String jsonString) {
    final decoded = _decodePayload(jsonString);
    final rawOverrides = _extractOverrides(decoded);

    final companions = <LocalizationsOverridesCompanion>[];
    for (final item in rawOverrides) {
      final companion = _toCompanion(item);
      if (companion != null) companions.add(companion);
    }
    return companions;
  }

  /// Validates the imported `file` field as a strict lang/ basename.
  ///
  /// Security (audit F1-1/F2-1, severe): community presets are untrusted; the
  /// raw `file` value previously passed validation and was persisted, then
  /// joined into a filesystem path where traversal/absolute names overwrote
  /// arbitrary existing files (e.g. `../config.blk`, `C:\tmp\v.csv`).
  /// Failing loud here also guards the snapshot-vault restore flow (F1-6),
  /// which parses through this same choke point.
  LocalizationsOverridesCompanion? _toCompanion(dynamic item) {
    if (item is! Map) return null;
    final file = item['file'];
    final key = item['key'];
    final value = item['value'];

    if (file is String && !isSafeLangFileName(file)) {
      throw FormatException(
        'Unsafe preset target file: "$file" — path traversal and '
        'absolute paths are not allowed.',
      );
    }
    if (file is! String) return null;
    if (key is! String || key.isEmpty || value is! String) return null;

    // F2-2: CR/LF in imported values corrupts CSV rows on export; normalize
    // before anything is persisted. fileName is a no-op only because the
    // guard above already refuses control characters.
    return LocalizationsOverridesCompanion.insert(
      fileName: _normalizeNewlines(file),
      stringKey: _normalizeNewlines(key),
      customValue: _normalizeNewlines(value),
    );
  }

  String _normalizeNewlines(String raw) =>
      raw.replaceAll('\r\n', ' ').replaceAll('\n', ' ').replaceAll('\r', ' ');

  dynamic _decodePayload(String jsonString) {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw const FormatException('File does not contain valid JSON.');
    }
    return decoded;
  }

  List<dynamic> _extractOverrides(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root of preset JSON must be an object.');
    }

    final format = decoded['format'];
    if (format != currentFormat) {
      throw FormatException(
        'Incompatible preset format: "$format". Expected "$currentFormat".',
      );
    }

    final rawOverrides = decoded['overrides'];
    if (rawOverrides is! List) {
      throw const FormatException('Missing or invalid "overrides" list.');
    }
    return rawOverrides;
  }
}
