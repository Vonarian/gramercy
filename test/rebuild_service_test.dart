import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/models/snapshot_models.dart';
import 'package:gramercy/features/localization/services/rebuild_service.dart';
import 'package:gramercy/features/localization/services/snapshot_service.dart';

class FakeSnapshotService extends SnapshotService {
  int createSnapshotCallCount = 0;
  String? lastLabel;
  String? lastDescription;
  bool shouldThrow = false;

  FakeSnapshotService({AppDatabase? db})
    : super(
        db: db ?? AppDatabase(NativeDatabase.memory()),
        baseDir: Directory.systemTemp,
      );

  @override
  Future<SnapshotMetadata?> createSnapshot({
    required String label,
    String? description,
  }) async {
    createSnapshotCallCount++;
    lastLabel = label;
    lastDescription = description;
    if (shouldThrow) {
      throw Exception('Disk full during snapshot creation');
    }
    return SnapshotMetadata(
      id: 'snap_test_123',
      name: label,
      createdAt: DateTime.now(),
      description: description,
      totalOverrides: 1,
      filePath: '/tmp/snap_test_123.json',
    );
  }
}

class ThrowingBackupService extends BackupService {
  const ThrowingBackupService();

  @override
  Future<String?> backupLocalizationFolder(String wtPath) async {
    throw Exception('Simulated backup disk failure');
  }
}

void main() {
  late Directory tempDir;
  late Directory langDir;
  late AppDatabase db;
  late RebuildService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wt_rebuild_test_');
    langDir = Directory('${tempDir.path}/lang');
    await langDir.create(recursive: true);
    db = AppDatabase(NativeDatabase.memory());
    service = const RebuildService();
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RebuildService Tests', () {
    test('purgeLocalizationCache backs up files and deletes csv, orig, and localization.blk', () async {
      final csv1 = File('${langDir.path}/units.csv');
      final orig1 = File('${langDir.path}/units.csv.orig');
      final blkFile = File('${langDir.path}/localization.blk');

      await csv1.writeAsString('id;English\nkey;val');
      await orig1.writeAsString('id;English\nkey;val');
      await blkFile.writeAsString('locTable { file:t="%lang/units.csv" }');

      // Create config.blk without testLocalization
      final configBlk = File('${tempDir.path}/config.blk');
      await configBlk.writeAsString('graphics { renderer:t="auto" }');

      final result = await service.purgeLocalizationCache(tempDir.path);

      expect(result.success, isTrue);
      expect(result.deletedCount, equals(3));
      expect(result.backupPath, isNotNull);
      expect(await csv1.exists(), isFalse);
      expect(await orig1.exists(), isFalse);
      expect(await blkFile.exists(), isFalse);

      // Verify backup folder contains files
      final backupDir = Directory(result.backupPath!);
      expect(await backupDir.exists(), isTrue);
      expect(await File('${backupDir.path}/units.csv').exists(), isTrue);
      expect(await File('${backupDir.path}/localization.blk').exists(), isTrue);

      // Ensure config.blk was patched
      final updatedBlk = await configBlk.readAsString();
      expect(updatedBlk, contains('testLocalization:b=yes'));
    });

    test(
      'purgeLocalizationCache handles missing lang folder gracefully',
      () async {
        await langDir.delete(recursive: true);
        final result = await service.purgeLocalizationCache(tempDir.path);
        expect(result.success, isTrue);
        expect(result.deletedCount, equals(0));
      },
    );

    test(
      'checkFreshStringsExist returns false when lang folder is empty',
      () async {
        final status = await service.checkFreshStringsExist(tempDir.path);
        expect(status.hasFiles, isFalse);
        expect(status.fileCount, equals(0));
      },
    );

    test('checkFreshStringsExist returns true when valid CSVs exist', () async {
      final unitsCsv = File('${langDir.path}/units.csv');
      await unitsCsv.writeAsString('<ID>;<English>\ntank_t90;T-90A');

      final uiCsv = File('${langDir.path}/ui.csv');
      await uiCsv.writeAsString('<ID>;<English>\nmenu_play;Battle');

      final status = await service.checkFreshStringsExist(tempDir.path);
      expect(status.hasFiles, isTrue);
      expect(status.fileCount, equals(2));
      expect(status.keyFilesFound, contains('units.csv'));
    });

    test(
      'checkFreshStringsExist with since parameter ignores older files',
      () async {
        final unitsCsv = File('${langDir.path}/units.csv');
        await unitsCsv.writeAsString('<ID>;<English>\ntank_t90;T-90A');

        // Check with a future since threshold
        final futureSince = DateTime.now().add(const Duration(minutes: 5));
        final statusFuture = await service.checkFreshStringsExist(
          tempDir.path,
          since: futureSince,
        );
        expect(statusFuture.hasFiles, isFalse);
        expect(statusFuture.fileCount, equals(0));

        // Check with a past since threshold
        final pastSince = DateTime.now().subtract(const Duration(minutes: 5));
        final statusPast = await service.checkFreshStringsExist(
          tempDir.path,
          since: pastSince,
        );
        expect(statusPast.hasFiles, isTrue);
        expect(statusPast.fileCount, equals(1));
      },
    );

    test(
      'purgeLocalizationCache records purgedAt and verifies no remaining files',
      () async {
        final unitsCsv = File('${langDir.path}/units.csv');
        await unitsCsv.writeAsString('test');
        final blkFile = File('${langDir.path}/localization.blk');
        await blkFile.writeAsString('test');

        final result = await service.purgeLocalizationCache(tempDir.path);
        expect(result.success, isTrue);
        expect(result.purgedAt, isNotNull);
        expect(result.remainingFiles, isEmpty);
      },
    );

    test(
      'purgeLocalizationCache invokes snapshotService before purge',
      () async {
        final fakeSnapshot = FakeSnapshotService(db: db);
        final customService = RebuildService(snapshotService: fakeSnapshot);

        final csvFile = File('${langDir.path}/units.csv');
        await csvFile.writeAsString('id;English\nkey;val');

        final result = await customService.purgeLocalizationCache(tempDir.path);

        expect(result.success, isTrue);
        expect(fakeSnapshot.createSnapshotCallCount, equals(1));
        expect(fakeSnapshot.lastLabel, equals('Pre-Update Purge'));
        expect(
          fakeSnapshot.lastDescription,
          equals('Auto-snapshot captured before War Thunder cache purge'),
        );
      },
    );

    test('purgeLocalizationCache completes successfully even if snapshotService throws', () async {
      final fakeSnapshot = FakeSnapshotService(db: db)..shouldThrow = true;
      final customService = RebuildService(snapshotService: fakeSnapshot);

      final csvFile = File('${langDir.path}/units.csv');
      await csvFile.writeAsString('id;English\nkey;val');

      final result = await customService.purgeLocalizationCache(tempDir.path);

      expect(result.success, isTrue);
      expect(fakeSnapshot.createSnapshotCallCount, equals(1));
      expect(await csvFile.exists(), isFalse);
    });

    test('purgeLocalizationCache returns failure and locked details when files cannot be deleted', () async {
      final lockedCsv = File('${langDir.path}/units.csv');
      await lockedCsv.writeAsString('id;English\nkey;val');
      final lockedBlk = File('${langDir.path}/localization.blk');
      await lockedBlk.writeAsString('locTable {}');

      final lockedService = RebuildService(
        fileDeleter: (file) async {
          throw const FileSystemException('File locked by another process');
        },
      );

      final result = await lockedService.purgeLocalizationCache(tempDir.path);

      expect(result.success, isFalse);
      expect(result.deletedCount, equals(0));
      expect(result.backupPath, isNotNull);
      expect(
        result.remainingFiles,
        containsAll(['units.csv', 'localization.blk']),
      );
      expect(result.errorMessage, contains('Could not delete 2 file(s)'));
      expect(
        result.errorMessage,
        contains('The file is in use by War Thunder'),
      );
      expect(await lockedCsv.exists(), isTrue);
      expect(await lockedBlk.exists(), isTrue);
    });

    test(
      'purgeLocalizationCache handles unexpected errors gracefully',
      () async {
        const customService = RebuildService(
          backupService: ThrowingBackupService(),
        );
        final csvFile = File('${langDir.path}/units.csv');
        await csvFile.writeAsString('id;English\nkey;val');

        final result = await customService.purgeLocalizationCache(tempDir.path);

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Simulated backup disk failure'));
      },
    );
  });

  group('BackupService Tests', () {
    const backupService = BackupService();

    test('returns null when lang folder is empty', () async {
      final res = await backupService.backupLocalizationFolder(tempDir.path);
      expect(res, isNull);
    });

    test('returns null when path is empty', () async {
      final res = await backupService.backupLocalizationFolder('');
      expect(res, isNull);
    });

    test('copies all files from lang directory to backup directory', () async {
      final file1 = File('${langDir.path}/units.csv');
      await file1.writeAsString('units content');
      final file2 = File('${langDir.path}/localization.blk');
      await file2.writeAsString('blk content');

      final backupPath = await backupService.backupLocalizationFolder(
        tempDir.path,
      );
      expect(backupPath, isNotNull);
      final backupDir = Directory(backupPath!);
      expect(await backupDir.exists(), isTrue);
      expect(
        await File('${backupDir.path}/units.csv').readAsString(),
        equals('units content'),
      );
      expect(
        await File('${backupDir.path}/localization.blk').readAsString(),
        equals('blk content'),
      );
    });
  });
}
