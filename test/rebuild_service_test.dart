import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/features/localization/services/rebuild_service.dart';

void main() {
  late Directory tempDir;
  late Directory langDir;
  late RebuildService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wt_rebuild_test_');
    langDir = Directory('${tempDir.path}/lang');
    await langDir.create(recursive: true);
    service = const RebuildService();
  });

  tearDown(() async {
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
