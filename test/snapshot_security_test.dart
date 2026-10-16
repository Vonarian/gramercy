import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/models/snapshot_models.dart';
import 'package:gramercy/features/localization/services/snapshot_service.dart';

/// Security regression tests for audit finding F2-4 (LOW, CONFIRMED):
/// a snapshot id sourced from snapshot JSON metadata must never escape
/// [SnapshotService.baseDir] via [deleteSnapshot] or [restoreSnapshot].
void main() {
  late AppDatabase db;
  late Directory sandbox;
  late Directory vault;
  late File victim;
  late SnapshotService snapshotService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sandbox = await Directory.systemTemp.createTemp('gramercy_snap_sec_');
    vault = Directory('${sandbox.path}/vault')..createSync(recursive: true);
    victim = File('${sandbox.path}/victim.json')
      ..writeAsStringSync('DO-NOT-DELETE victim-payload-marker');
    snapshotService = SnapshotService(db: db, baseDir: vault);
  });

  tearDown(() async {
    await db.close();
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  group('F2-4 - deleteSnapshot path containment', () {
    test('rejects backslash traversal id and keeps victim intact', () async {
      final deleted = await snapshotService.deleteSnapshot('..\\victim');

      expect(deleted, isFalse);
      expect(victim.existsSync(), isTrue);
      expect(victim.readAsStringSync(), contains('DO-NOT-DELETE'));
    });

    test(
      'rejects forward slash traversal id and keeps victim intact',
      () async {
        final deleted = await snapshotService.deleteSnapshot('../victim');

        expect(deleted, isFalse);
        expect(victim.existsSync(), isTrue);
      },
    );

    test('rejects absolute id replacing the vault prefix', () async {
      // An absolute id makes p.join return the id as-is (replacing the vault
      // prefix), letting deleteSnapshot() hit sandbox/victim.json directly.
      final deleted = await snapshotService.deleteSnapshot(victim.path);

      expect(deleted, isFalse);
      expect(victim.existsSync(), isTrue);
    });

    test('pins the safe-id rule semantics for degenerate ids', () async {
      expect(await snapshotService.deleteSnapshot(''), isFalse);
      expect(await snapshotService.deleteSnapshot('.'), isFalse);
      expect(await snapshotService.deleteSnapshot('..'), isFalse);
      expect(await snapshotService.deleteSnapshot(' ..\\victim '), isFalse);
      expect(await snapshotService.deleteSnapshot('name:ads'), isFalse);
    });
  });

  group('F2-4 - restoreSnapshot path containment', () {
    test(
      'rejects traversal id pointing at a valid preset outside vault',
      () async {
        await victim.writeAsString(
          '{"format":"gramercy_preset_v1","version":"1.0",'
          '"overrides":[{"file":"evil.csv","key":"exfil","value":"PWNED"}]}',
        );

        final restored = await snapshotService.restoreSnapshot('..\\victim');

        expect(restored, equals(0));
        expect(await db.getAllOverrides(), isEmpty);
      },
    );
  });

  group('legit snapshots keep resolving after containment', () {
    Future<SnapshotMetadata> seedSnapshot() async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'tank_m4a3',
          customValue: 'Sherman Easy Eight',
        ),
      );
      final snapshot = await snapshotService.createSnapshot(label: 'Legit');
      return snapshot!;
    }

    test('create/delete round-trip with generated id still works', () async {
      final snapshot = await seedSnapshot();

      final deleted = await snapshotService.deleteSnapshot(snapshot.id);
      expect(deleted, isTrue);
      expect(File(snapshot.filePath).existsSync(), isFalse);
      expect(await snapshotService.listSnapshots(), isEmpty);
    });

    test('id with explicit .json suffix still resolves', () async {
      final snapshot = await seedSnapshot();

      final deleted = await snapshotService.deleteSnapshot(
        '${snapshot.id}.json',
      );
      expect(deleted, isTrue);
      expect(File(snapshot.filePath).existsSync(), isFalse);
    });

    test('restore of vault-managed id still upserts overrides', () async {
      final snapshot = await seedSnapshot();

      final restored = await snapshotService.restoreSnapshot(snapshot.id);
      expect(restored, equals(1));

      final overrides = await db.getAllOverrides();
      expect(overrides.single.stringKey, equals('tank_m4a3'));
    });
  });
}
