import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Delta Vault Database Tests', () {
    test('saveOverride inserts and updates on conflict (upsert)', () async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'us_m4a3_76w_sherman',
          customValue: 'M4A3 (76) W Sherman',
        ),
      );

      var overrides = await db.getOverridesForFile('units.csv');
      expect(overrides.length, equals(1));
      expect(overrides.first.customValue, equals('M4A3 (76) W Sherman'));

      // Upsert update on conflict
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'us_m4a3_76w_sherman',
          customValue: 'Easy Eight',
        ),
      );

      overrides = await db.getOverridesForFile('units.csv');
      expect(overrides.length, equals(1));
      expect(overrides.first.customValue, equals('Easy Eight'));
    });

    test('deleteOverride removes delta and reverts to base', () async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'germ_pzkpfw_VI_ausf_B_tiger_IIh',
          customValue: 'King Tiger Henschel',
        ),
      );

      var overrides = await db.getOverridesForFile('units.csv');
      expect(overrides.length, equals(1));

      final deletedCount = await db.deleteOverride(
        'units.csv',
        'germ_pzkpfw_VI_ausf_B_tiger_IIh',
      );
      expect(deletedCount, equals(1));

      overrides = await db.getOverridesForFile('units.csv');
      expect(overrides.isEmpty, isTrue);
    });

    test('watchOverridesForFile streams reactive updates', () async {
      final stream = db.watchOverridesForFile('units.csv');

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
          isEmpty,
        ]),
      );

      // Give Drift stream a moment to emit initial state
      await pumpEventQueue();

      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'spitfire_mk9',
          customValue: 'Spitfire Mk IXc',
        ),
      );

      await pumpEventQueue();

      await db.deleteOverride('units.csv', 'spitfire_mk9');

      await expectation;
    });
  });
}
