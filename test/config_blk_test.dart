import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wt_blk_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('config.blk Hook & Verifier Tests', () {
    test(
      'checkConfigBlkStatusWorker detects when testLocalization is enabled',
      () async {
        final blkFile = File('${tempDir.path}/config.blk');
        await blkFile.writeAsString('''
graphics {
  renderer:t="auto"
}
debug {
  testLocalization:b=yes
  screenshotAsJpeg:b=yes
}
''');

        final status = checkConfigBlkStatusWorker(blkFile.path);
        expect(status.exists, isTrue);
        expect(status.isLocalizationEnabled, isTrue);
      },
    );

    test('checkConfigBlkStatusWorker detects when testLocalization is missing or disabled', () async {
      final blkFile = File('${tempDir.path}/config.blk');
      await blkFile.writeAsString('''
graphics {
  renderer:t="auto"
}
debug {
  testLocalization:b=no
}
''');

      final status = checkConfigBlkStatusWorker(blkFile.path);
      expect(status.exists, isTrue);
      expect(status.isLocalizationEnabled, isFalse);
    });

    test('patchConfigBlkWorker updates testLocalization:b=no to yes', () async {
      final blkFile = File('${tempDir.path}/config.blk');
      await blkFile.writeAsString('''
debug {
  testLocalization:b=no
  trace:b=yes
}
''');

      final success = await patchConfigBlkWorker(blkFile.path);
      expect(success, isTrue);

      final updatedStatus = checkConfigBlkStatusWorker(blkFile.path);
      expect(updatedStatus.isLocalizationEnabled, isTrue);

      final content = await blkFile.readAsString();
      expect(content.contains('testLocalization:b=yes'), isTrue);
    });

    test('patchConfigBlkWorker inserts testLocalization inside existing debug block', () async {
      final blkFile = File('${tempDir.path}/config.blk');
      await blkFile.writeAsString('''
debug {
  trace:b=yes
}
''');

      final success = await patchConfigBlkWorker(blkFile.path);
      expect(success, isTrue);

      final updatedStatus = checkConfigBlkStatusWorker(blkFile.path);
      expect(updatedStatus.isLocalizationEnabled, isTrue);
    });

    test('patchConfigBlkWorker creates debug block when none exists', () async {
      final blkFile = File('${tempDir.path}/config.blk');
      await blkFile.writeAsString('''
video {
  resolution:t="1920x1080"
}
''');

      final success = await patchConfigBlkWorker(blkFile.path);
      expect(success, isTrue);

      final updatedStatus = checkConfigBlkStatusWorker(blkFile.path);
      expect(updatedStatus.isLocalizationEnabled, isTrue);
    });
  });
}
