import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:gramercy/features/localization/services/preset_service.dart';

/// Serialized preset plus its override count, so the UI can report both
/// without re-reading the JSON it just produced.
class PresetExport {
  final String json;
  final int count;

  const PresetExport({required this.json, required this.count});
}

/// Presentation-flow model for the presets menu (audit layering fix): the
/// widget no longer reaches into [dbProvider] itself — all DB access lives
/// here in the providers layer, and heavy JSON work routes through the
/// isolate-backed service variants.
class PresetMenuModel {
  final PresetService service;
  final AppDatabase db;

  const PresetMenuModel({required this.service, required this.db});

  /// Serialized preset JSON, or null when nothing is customized yet.
  Future<PresetExport?> buildExport() async {
    final overrides = await service.loadAllOverrides(db);
    if (overrides.isEmpty) return null;
    final json = await service.serializePresetAsync(overrides);
    return PresetExport(json: json, count: overrides.length);
  }

  /// Imports preset JSON; returns the upserted override count.
  Future<int> importFromJson(String jsonString) =>
      service.importPresetAsync(db, jsonString);
}

final presetMenuModelProvider = Provider<PresetMenuModel>((ref) {
  return PresetMenuModel(
    service: ref.watch(presetServiceProvider),
    db: ref.watch(dbProvider),
  );
});
