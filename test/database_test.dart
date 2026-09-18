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
        emitsInOrder([isEmpty, hasLength(1), isEmpty]),
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

    test('getAllOverrides retrieves all overrides across all files', () async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_1',
          customValue: 'Tank One',
        ),
      );
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'ui.csv',
          stringKey: 'btn_ok',
          customValue: 'Affirmative',
        ),
      );

      final all = await db.getAllOverrides();
      expect(all.length, equals(2));
      expect(
        all.map((e) => e.stringKey).toSet(),
        containsAll(['tank_1', 'btn_ok']),
      );
    });

    test(
      'batchUpsertOverrides inserts or updates multiple items in a batch',
      () async {
        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'tank_1',
            customValue: 'Tank Old',
          ),
        );

        final count = await db.batchUpsertOverrides([
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'tank_1',
            customValue: 'Tank Updated',
          ),
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'tank_2',
            customValue: 'Tank New',
          ),
        ]);

        expect(count, equals(2));
        final overrides = await db.getAllOverrides();
        expect(overrides.length, equals(2));
        final tank1 = overrides.firstWhere((e) => e.stringKey == 'tank_1');
        expect(tank1.customValue, equals('Tank Updated'));
        final tank2 = overrides.firstWhere((e) => e.stringKey == 'tank_2');
        expect(tank2.customValue, equals('Tank New'));
      },
    );

    test(
      'clearOverridesForFile deletes all overrides for a given file',
      () async {
        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'tank_1',
            customValue: 'Tank 1',
          ),
        );
        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'tank_2',
            customValue: 'Tank 2',
          ),
        );
        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'ui.csv',
            stringKey: 'btn_ok',
            customValue: 'OK',
          ),
        );

        final deleted = await db.clearOverridesForFile('units.csv');
        expect(deleted, equals(2));

        final remainingUnits = await db.getOverridesForFile('units.csv');
        expect(remainingUnits.isEmpty, isTrue);

        final remainingUi = await db.getOverridesForFile('ui.csv');
        expect(remainingUi.length, equals(1));
      },
    );

    test(
      'watchTotalOverridesCount and watchOverridesCountForFile stream counts',
      () async {
        final totalStream = db.watchTotalOverridesCount();
        final fileStream = db.watchOverridesCountForFile('units.csv');

        final totalExpectation = expectLater(
          totalStream,
          emitsInOrder([0, 1, 2]),
        );
        final fileExpectation = expectLater(
          fileStream,
          emitsInOrder([0, 1, 1]),
        );

        await pumpEventQueue();

        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'k1',
            customValue: 'v1',
          ),
        );
        await pumpEventQueue();

        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'ui.csv',
            stringKey: 'k2',
            customValue: 'v2',
          ),
        );
        await pumpEventQueue();

        await totalExpectation;
        await fileExpectation;
      },
    );
  });
}
