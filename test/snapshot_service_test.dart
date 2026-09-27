import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/models/snapshot_models.dart';
import 'package:gramercy/features/localization/services/snapshot_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late SnapshotService snapshotService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync('gramercy_snapshot_test_');
    snapshotService = SnapshotService(db: db, baseDir: tempDir);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SnapshotService - createSnapshot', () {
    test('returns null when no overrides exist in DB', () async {
      final snapshot = await snapshotService.createSnapshot(
        label: 'Empty DB Snapshot',
      );

      expect(snapshot, isNull);
      expect(tempDir.listSync().isEmpty, isTrue);
    });

    test('persists JSON conforming to gramercy_preset_v1 and returns SnapshotMetadata', () async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_m4a3',
          customValue: 'Sherman Easy Eight',
        ),
      );
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'ui.csv',
          stringKey: 'btn_attack',
          customValue: 'Attack!',
        ),
      );

      final metadata = await snapshotService.createSnapshot(
        label: 'My Battle Preset',
        description: 'A custom loadout preset',
      );

      expect(metadata, isNotNull);
      expect(metadata!.name, equals('My Battle Preset'));
      expect(metadata.description, equals('A custom loadout preset'));
      expect(metadata.totalOverrides, equals(2));
      expect(metadata.filePath, contains(tempDir.path));

      final file = File(metadata.filePath);
      expect(file.existsSync(), isTrue);

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json['format'], equals('gramercy_preset_v1'));
      expect(json['version'], equals('1.0'));
      expect(json['id'], equals(metadata.id));
      expect(json['name'], equals('My Battle Preset'));
      expect(json['description'], equals('A custom loadout preset'));
      expect(json['totalOverrides'], equals(2));

      final overrides = json['overrides'] as List<dynamic>;
      expect(overrides.length, equals(2));
      expect(
        overrides.any(
          (o) =>
              o['file'] == 'units.csv' &&
              o['key'] == 'tank_m4a3' &&
              o['value'] == 'Sherman Easy Eight',
        ),
        isTrue,
      );
    });
  });

  group('SnapshotService - listSnapshots', () {
    test('returns empty list if baseDir is empty or non-existent', () async {
      final emptyList = await snapshotService.listSnapshots();
      expect(emptyList, isEmpty);

      final nonExistentDir = Directory('${tempDir.path}/non_existent');
      final serviceNonExistent = SnapshotService(
        db: db,
        baseDir: nonExistentDir,
      );
      expect(await serviceNonExistent.listSnapshots(), isEmpty);
    });

    test(
      'parses JSON headers and returns sorted list (newest first)',
      () async {
        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv',
            stringKey: 'spitfire',
            customValue: 'Supermarine Spitfire',
          ),
        );

        final snap1 = await snapshotService.createSnapshot(label: 'Snapshot 1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final snap2 = await snapshotService.createSnapshot(label: 'Snapshot 2');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final snap3 = await snapshotService.createSnapshot(label: 'Snapshot 3');

        final list = await snapshotService.listSnapshots();

        expect(list.length, equals(3));
        expect(list[0].id, equals(snap3!.id));
        expect(list[1].id, equals(snap2!.id));
        expect(list[2].id, equals(snap1!.id));
        expect(list[0].name, equals('Snapshot 3'));
        expect(list[1].name, equals('Snapshot 2'));
        expect(list[2].name, equals('Snapshot 1'));
      },
    );

    test('ignores non-json and corrupted files gracefully', () async {
      final textFile = File('${tempDir.path}/notes.txt');
      await textFile.writeAsString('just notes');

      final corruptJson = File('${tempDir.path}/corrupt.json');
      await corruptJson.writeAsString('{ invalid json');

      final wrongFormatJson = File('${tempDir.path}/wrong_format.json');
      await wrongFormatJson.writeAsString('{"format": "other_preset_v2"}');

      final list = await snapshotService.listSnapshots();
      expect(list, isEmpty);
    });
  });

  group('SnapshotService - restoreSnapshot', () {
    test('reads snapshot and batch-upserts overrides into database', () async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_1',
          customValue: 'Original Tank',
        ),
      );

      final snapshot = await snapshotService.createSnapshot(label: 'V1 State');
      expect(snapshot, isNotNull);

      // Modify the DB override and add another
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_1',
          customValue: 'Modified Tank',
        ),
      );
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_2',
          customValue: 'Tank 2',
        ),
      );

      // Restore snapshot
      final restoredCount = await snapshotService.restoreSnapshot(snapshot!.id);
      expect(restoredCount, equals(1));

      final overrides = await db.getAllOverrides();
      final restoredTank1 = overrides.firstWhere(
        (o) => o.stringKey == 'tank_1',
      );
      expect(restoredTank1.customValue, equals('Original Tank'));
    });

    test('returns 0 when restoring non-existent snapshot ID', () async {
      final restoredCount = await snapshotService.restoreSnapshot(
        'non_existent_id',
      );
      expect(restoredCount, equals(0));
    });
  });

  group('SnapshotService - deleteSnapshot', () {
    test('removes file from disk and returns true', () async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_1',
          customValue: 'Tank 1',
        ),
      );

      final snapshot = await snapshotService.createSnapshot(
        label: 'To be deleted',
      );
      expect(snapshot, isNotNull);

      final file = File(snapshot!.filePath);
      expect(file.existsSync(), isTrue);

      final deleted = await snapshotService.deleteSnapshot(snapshot.id);
      expect(deleted, isTrue);
      expect(file.existsSync(), isFalse);

      final remaining = await snapshotService.listSnapshots();
      expect(remaining, isEmpty);
    });

    test('returns false when deleting non-existent snapshot ID', () async {
      final deleted = await snapshotService.deleteSnapshot('does_not_exist');
      expect(deleted, isFalse);
    });
  });

  group('SnapshotMetadata Model', () {
    test('fromJson and toJson round-trip preserves all fields', () {
      final now = DateTime.utc(2026, 9, 27, 12, 0, 0);
      final json = {
        'id': 'snap_123',
        'name': 'Test Snapshot',
        'createdAt': now.toIso8601String(),
        'description': 'Description text',
        'totalOverrides': 42,
      };

      final metadata = SnapshotMetadata.fromJson(
        json,
        '/path/to/snap_123.json',
      );

      expect(metadata.id, equals('snap_123'));
      expect(metadata.name, equals('Test Snapshot'));
      expect(metadata.createdAt, equals(now));
      expect(metadata.description, equals('Description text'));
      expect(metadata.totalOverrides, equals(42));
      expect(metadata.filePath, equals('/path/to/snap_123.json'));

      final outJson = metadata.toJson();
      expect(outJson['id'], equals('snap_123'));
      expect(outJson['name'], equals('Test Snapshot'));
      expect(outJson['totalOverrides'], equals(42));
    });

    test('fromJson falls back to exportedAt and overrides count', () {
      final now = DateTime.utc(2026, 9, 27, 12, 0, 0);
      final json = {
        'label': 'Preset Label',
        'exportedAt': now.toIso8601String(),
        'overrides': [
          {'file': 'a.csv', 'key': 'k1', 'value': 'v1'},
        ],
      };

      final metadata = SnapshotMetadata.fromJson(json, '/tmp/snap_custom.json');

      expect(metadata.id, equals('snap_custom'));
      expect(metadata.name, equals('Preset Label'));
      expect(metadata.createdAt, equals(now));
      expect(metadata.description, isNull);
      expect(metadata.totalOverrides, equals(1));
      expect(metadata.filePath, equals('/tmp/snap_custom.json'));
    });

    test('supports value equality, hashCode, and toString', () {
      final now = DateTime.utc(2026, 9, 27, 12, 0, 0);
      final snapA = SnapshotMetadata(
        id: '1',
        name: 'A',
        createdAt: now,
        description: 'desc',
        totalOverrides: 5,
        filePath: '/tmp/1.json',
      );
      final snapB = SnapshotMetadata(
        id: '1',
        name: 'A',
        createdAt: now,
        description: 'desc',
        totalOverrides: 5,
        filePath: '/tmp/1.json',
      );
      final snapC = SnapshotMetadata(
        id: '2',
        name: 'C',
        createdAt: now,
        totalOverrides: 1,
        filePath: '/tmp/2.json',
      );

      expect(snapA, equals(snapB));
      expect(snapA.hashCode, equals(snapB.hashCode));
      expect(snapA, isNot(equals(snapC)));
      expect(
        snapA.toString(),
        contains('SnapshotMetadata(id: 1, name: A, totalOverrides: 5)'),
      );
    });
  });
}
