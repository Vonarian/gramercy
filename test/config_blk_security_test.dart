import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/config_blk_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gramercy_cfg_sec_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  String p(String name) => '${tempDir.path}${Platform.pathSeparator}$name';

  group('writeConfigBlkAtomic', () {
    test(
      'writes final content to the target and leaves no .tmp behind',
      () async {
        final target = p('config.blk');

        await writeConfigBlkAtomic(
          target,
          'debug {\n  testLocalization:b=yes\n}\n',
        );

        expect(
          await File(target).readAsString(),
          'debug {\n  testLocalization:b=yes\n}\n',
        );
        expect(File('$target.tmp').existsSync(), isFalse);
      },
    );

    test('replaces an existing target file', () async {
      final target = p('config.blk');
      await File(target).writeAsString('OLD', flush: true);

      await writeConfigBlkAtomic(target, 'NEW');

      expect(await File(target).readAsString(), 'NEW');
      expect(File('$target.tmp').existsSync(), isFalse);
    });

    test('truncates a .tmp orphan left by a prior crash', () async {
      final target = p('config.blk');
      await File('$target.tmp').writeAsString('STALE-LEFTOVER', flush: true);

      await writeConfigBlkAtomic(target, 'CLEAN');

      expect(await File(target).readAsString(), 'CLEAN');
      expect(File('$target.tmp').existsSync(), isFalse);
    });

    test(
      'rethrows and cleans up .tmp when rename cannot replace target',
      () async {
        // A directory occupies the rename destination: rename must fail and
        // the helper must rethrow while still removing its .tmp file.
        final target = p('occupied');
        await Directory(target).create();

        await expectLater(
          writeConfigBlkAtomic(target, 'X'),
          throwsA(isA<FileSystemException>()),
        );

        expect(Directory(target).existsSync(), isTrue);
        expect(File('$target.tmp').existsSync(), isFalse);
      },
    );
  });

  group('patchConfigBlkWorker atomic-write contract', () {
    test('reclaims a stale .tmp orphaned by a prior crash', () async {
      final target = p('config.blk');
      await File(target).writeAsString('debug {\n  testLocalization:b=no\n}\n');
      await File('$target.tmp').writeAsString('STALE-LEFTOVER', flush: true);

      final success = await patchConfigBlkWorker(target);

      expect(success, isTrue);
      expect(
        File(target).readAsStringSync(),
        contains('testLocalization:b=yes'),
      );
      expect(File('$target.tmp').existsSync(), isFalse);
    });
  });

  group('patchConfigBlkWorker preserved semantics', () {
    test('captures pristine content into .bak on first patch', () async {
      final target = p('config.blk');
      const original = 'debug {\n  testLocalization:b=no\n}\n';
      await File(target).writeAsString(original, flush: true);

      await patchConfigBlkWorker(target);

      expect(File('$target.bak').readAsStringSync(), original);
    });

    test('never overwrites an existing .bak', () async {
      final target = p('config.blk');
      await File(target).writeAsString('debug {\n  testLocalization:b=no\n}\n');
      await File('$target.bak').writeAsString('PRISTINE-SENTINEL', flush: true);

      await patchConfigBlkWorker(target);

      expect(File('$target.bak').readAsStringSync(), 'PRISTINE-SENTINEL');
    });

    test(
      'returns true without rewriting when testLocalization is already yes',
      () async {
        final target = File(p('config.blk'));
        await target.writeAsString('debug {\n  testLocalization:b=yes\n}\n');
        final stamp = DateTime(2000);
        await target.setLastModified(stamp);

        final success = await patchConfigBlkWorker(target.path);

        expect(success, isTrue);
        expect(
          target.statSync().modified.millisecondsSinceEpoch,
          stamp.millisecondsSinceEpoch,
        );
      },
    );

    test(
      'still captures .bak for an already-enabled file (order preserved)',
      () async {
        final target = p('config.blk');
        const alreadyEnabled = 'debug {\n  testLocalization:b=yes\n}\n';
        await File(target).writeAsString(alreadyEnabled, flush: true);

        await patchConfigBlkWorker(target);

        expect(File('$target.bak').readAsStringSync(), alreadyEnabled);
      },
    );
  });
}
