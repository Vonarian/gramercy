import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../logging/app_logger.dart';

part 'database.g.dart';

class LocalizationsOverrides extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()(); // e.g., 'units.csv'
  TextColumn get stringKey => text()(); // e.g., 'us_m4a3_76w_sherman'
  TextColumn get customValue => text()(); // e.g., 'M4A3 (76) W'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {fileName, stringKey},
  ];
}

@DriftDatabase(tables: [LocalizationsOverrides])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'wt_localization'));

  @override
  int get schemaVersion => 1;

  // Watch overrides for a specific file to stream into Riverpod
  Stream<List<LocalizationsOverride>> watchOverridesForFile(String file) {
    return (select(
      localizationsOverrides,
    )..where((t) => t.fileName.equals(file))).watch();
  }

  // Future list of overrides for isolate export
  Future<List<LocalizationsOverride>> getOverridesForFile(String file) {
    return (select(
      localizationsOverrides,
    )..where((t) => t.fileName.equals(file))).get();
  }

  // Future list of all overrides across all files (for preset export)
  Future<List<LocalizationsOverride>> getAllOverrides() {
    return select(localizationsOverrides).get();
  }

  // Batch upsert multiple overrides in a single transaction
  Future<int> batchUpsertOverrides(
    List<LocalizationsOverridesCompanion> entries,
  ) async {
    if (entries.isEmpty) return 0;
    await transaction(() async {
      for (final entry in entries) {
        await saveOverride(entry);
      }
    });
    AppLogger.instance.i(
      'Batch upserted ${entries.length} overrides',
      tag: 'DRIFT',
    );
    return entries.length;
  }

  // Upsert a patch on conflict with uniqueKeys [fileName, stringKey]
  Future<void> saveOverride(LocalizationsOverridesCompanion entity) async {
    await into(localizationsOverrides).insert(
      entity,
      onConflict: DoUpdate(
        (old) => LocalizationsOverridesCompanion(
          customValue: entity.customValue,
          updatedAt: Value(DateTime.now()),
        ),
        target: [
          localizationsOverrides.fileName,
          localizationsOverrides.stringKey,
        ],
      ),
    );
    AppLogger.instance.d(
      'Saved override [${entity.fileName.value}] ${entity.stringKey.value} -> "${entity.customValue.value}"',
      tag: 'DRIFT',
    );
  }

  // Delete an override (revert to base game value)
  Future<int> deleteOverride(String file, String stringKey) async {
    final deleted =
        await (delete(localizationsOverrides)..where(
              (t) => t.fileName.equals(file) & t.stringKey.equals(stringKey),
            ))
            .go();
    AppLogger.instance.i(
      'Reverted override [$file] $stringKey (deleted: $deleted)',
      tag: 'DRIFT',
    );
    return deleted;
  }

  // Clear all overrides for a file
  Future<int> clearOverridesForFile(String file) async {
    final count = await (delete(
      localizationsOverrides,
    )..where((t) => t.fileName.equals(file))).go();
    AppLogger.instance.w(
      'Cleared all $count overrides for file: $file',
      tag: 'DRIFT',
    );
    return count;
  }

  // Watch total count of overrides across all files
  Stream<int> watchTotalOverridesCount() {
    final countExp = localizationsOverrides.id.count();
    final query = selectOnly(localizationsOverrides)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  // Watch count of overrides for a specific file
  Stream<int> watchOverridesCountForFile(String file) {
    final countExp = localizationsOverrides.id.count();
    final query = selectOnly(localizationsOverrides)
      ..where(localizationsOverrides.fileName.equals(file))
      ..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}
