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
    test('purgeLocalizationCache deletes both .csv and .orig files', () async {
      final csv1 = File('${langDir.path}/units.csv');
      final orig1 = File('${langDir.path}/units.csv.orig');
      final csv2 = File('${langDir.path}/ui.csv');
      final otherFile = File('${langDir.path}/notes.txt');

      await csv1.writeAsString('id;English\nkey;val');
      await orig1.writeAsString('id;English\nkey;val');
      await csv2.writeAsString('id;English\nkey;val2');
      await otherFile.writeAsString('custom notes');

      // Create config.blk without testLocalization
      final configBlk = File('${tempDir.path}/config.blk');
      await configBlk.writeAsString('graphics { renderer:t="auto" }');

      final result = await service.purgeLocalizationCache(tempDir.path);

      expect(result.success, isTrue);
      expect(result.deletedCount, equals(3)); // 2 csv + 1 orig
      expect(await csv1.exists(), isFalse);
      expect(await orig1.exists(), isFalse);
      expect(await csv2.exists(), isFalse);
      expect(await otherFile.exists(), isTrue); // txt preserved

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
}
