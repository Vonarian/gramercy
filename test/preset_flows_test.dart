import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:gramercy/features/localization/providers/preset_providers.dart';
import 'package:gramercy/features/localization/services/preset_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockDb extends Mock implements AppDatabase {}

void main() {
  setUpAll(() {
    registerFallbackValue(<LocalizationsOverridesCompanion>[]);
  });

  ProviderContainer containerWith(AppDatabase db) => ProviderContainer(
    overrides: [
      dbProvider.overrideWithValue(db),
      presetServiceProvider.overrideWithValue(const PresetService()),
    ],
  );

  AppDatabase dbWithOverrides(int count) {
    final db = _MockDb();
    when(() => db.getAllOverrides()).thenAnswer(
      (_) async => List.generate(
        count,
        (i) => LocalizationsOverride(
          id: i + 1,
          fileName: 'units.csv',
          stringKey: 'k$i',
          customValue: 'v$i',
          updatedAt: DateTime(2026),
        ),
      ),
    );
    return db;
  }

  group('PresetMenuModel export flow', () {
    test('returns null json when no overrides exist', () async {
      final db = dbWithOverrides(0);
      final container = containerWith(db);
      addTearDown(container.dispose);

      final export = await container
          .read(presetMenuModelProvider)
          .buildExport();

      expect(export, isNull);
      verify(() => db.getAllOverrides()).called(1);
    });

    test('serializes off the main isolate with preset-shaped output', () async {
      final db = dbWithOverrides(3);
      final container = containerWith(db);
      addTearDown(container.dispose);

      final export = await container
          .read(presetMenuModelProvider)
          .buildExport();

      expect(export, isNotNull);
      expect(export!.count, 3);
      expect(export.json, contains('"format": "gramercy_preset_v1"'));
      expect(export.json, contains('"key": "k2"'));
    });

    test('sync and isolate serializers agree byte-for-byte', () async {
      final service = const PresetService();
      final overrides = List.generate(
        2,
        (i) => LocalizationsOverride(
          id: i + 1,
          fileName: 'units.csv',
          stringKey: 'k$i',
          customValue: 'v$i',
          updatedAt: DateTime(2026),
        ),
      );

      final isolate = await service.serializePresetAsync(
        overrides,
        exportedAt: DateTime.utc(2026),
        source: 'X',
      );
      final inline = service.serializePreset(
        overrides,
        exportedAt: DateTime.utc(2026),
        source: 'X',
      );
      expect(isolate, inline);
    });
  });

  group('PresetMenuModel import flow', () {
    test('imports a valid preset through the isolate deserializer', () async {
      final db = _MockDb();
      when(() => db.batchUpsertOverrides(any())).thenAnswer((_) async => 2);
      final container = containerWith(db);
      addTearDown(container.dispose);

      const json = '''
{
  "format": "gramercy_preset_v1",
  "version": "1.0",
  "overrides": [
    {"file": "units.csv", "key": "a", "value": "A"},
    {"file": "units.csv", "key": "b", "value": "B"}
  ]
}
''';
      final count = await container
          .read(presetMenuModelProvider)
          .importFromJson(json);
      expect(count, 2);
      final captured =
          verify(() => db.batchUpsertOverrides(captureAny())).captured.single
              as List<LocalizationsOverridesCompanion>;
      expect(captured.length, 2);
      expect(captured.first.stringKey.value, 'a');
    });

    test('rejects unsafe preset target through the isolate path', () async {
      final db = _MockDb();
      final container = containerWith(db);
      addTearDown(container.dispose);

      const json = '''
{
  "format": "gramercy_preset_v1",
  "version": "1.0",
  "overrides": [
    {"file": "../evil.csv", "key": "a", "value": "A"}
  ]
}
''';
      await expectLater(
        container.read(presetMenuModelProvider).importFromJson(json),
        throwsFormatException,
      );
      verifyNever(() => db.batchUpsertOverrides(any()));
    });
  });
}
