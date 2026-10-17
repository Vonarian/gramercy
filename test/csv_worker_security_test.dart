import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';

/// Security-audit regression tests for the CSV export/parse pipeline.
///
/// Finding IDs reference the original security audit report (internal).
/// All file IO stays inside a [Directory.systemTemp] sandbox (setUp) that is
/// deleted recursively in tearDown — repo files are never touched.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gramercy_sec_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // -- sandbox helpers ------------------------------------------------------

  Future<File> seedCsv(String name, String content) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  Future<File> seedVictim(String name, String content) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  Future<Link> seedLink(String atPath, String targetPath) async {
    final link = Link(atPath);
    await link.create(targetPath);
    return link;
  }

  Future<bool> runExport(
    FileSystemEntity base,
    FileSystemEntity target,
    Map<String, String> ovr,
  ) => exportPatchedCsvWorker(
    ExportTaskParameters(
      baseFilePath: base.path,
      targetFilePath: target.path,
      overrides: ovr,
    ),
  );

  bool tmpResidueExists() =>
      tempDir.listSync().whereType<File>().any((f) => f.path.endsWith('.tmp'));

  List<File> tmpResidueFiles() => tempDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.tmp'))
      .toList();

  group('F1-2 (MODERATE): export refuses symlinked paths', () {
    test(
      'target is a symlink -> returns false and victim stays untouched',
      () async {
        final base = await seedCsv('base.csv', '<ID>;<English>\r\nk1;v1\r\n');
        final victim = await seedVictim(
          'victim.txt',
          'PRECIOUS ORIGINAL CONTENT',
        );
        final langDir = Directory('${tempDir.path}/lang');
        await langDir.create();
        final target = await seedLink(
          '${langDir.path}/linked.csv',
          victim.path,
        );

        final ok = await runExport(base, target, {});

        expect(ok, isFalse);
        expect(await victim.readAsString(), 'PRECIOUS ORIGINAL CONTENT');
      },
    );

    test(
      'base is a symlink -> returns false and target is not replaced',
      () async {
        final victim = await seedVictim('victim.csv', 'ORIGINAL GAME CONTENT');
        final langDir = Directory('${tempDir.path}/lang');
        await langDir.create();
        final base = await seedLink('${langDir.path}/linked.csv', victim.path);
        final target = await seedCsv('out.csv', 'TARGET ROWS');

        final ok = await runExport(base, target, {'k1': 'patched'});

        expect(ok, isFalse);
        expect(await victim.readAsString(), 'ORIGINAL GAME CONTENT');
        expect(await target.readAsString(), 'TARGET ROWS');
      },
    );

    test('derived .orig path is a symlink -> returns false', () async {
      final base = await seedCsv('base2.csv', '<ID>;<English>\r\nk1;old\r\n');
      final victim = await seedVictim('victim_orig.txt', 'ORIG-VICTIM DATA');
      await seedLink('${tempDir.path}/base2.csv.orig', victim.path);
      final target = await seedCsv('out2.csv', 'TARGET ROWS');

      final ok = await runExport(base, target, {'k1': 'custom'});

      expect(ok, isFalse);
      expect(await victim.readAsString(), 'ORIG-VICTIM DATA');
      expect(await target.readAsString(), 'TARGET ROWS');
    });

    test('derived .tmp path is a symlink -> returns false', () async {
      final base = await seedCsv('base3.csv', '<ID>;<English>\r\nk1;old\r\n');
      final target = await seedCsv('out3.csv', 'TARGET ROWS');
      final victim = await seedVictim('victim_tmp.txt', 'TMP-VICTIM DATA');
      await seedLink('${target.path}.tmp', victim.path);

      final ok = await runExport(base, target, {});

      expect(ok, isFalse);
      expect(await victim.readAsString(), 'TMP-VICTIM DATA');
      expect(await target.readAsString(), 'TARGET ROWS');
    });
  });

  group('F2-2 (MODERATE): line breaks in override values are quoted', () {
    test('multi-line export keeps one logical row in a quoted field', () async {
      final base = await seedCsv('base.csv', '<ID>;<English>\r\nk1;plain\r\n');
      final target = File('${tempDir.path}/out.csv');

      final ok = await runExport(base, target, {'k1': 'line1\nline2'});
      expect(ok, isTrue);

      final exported = await target.readAsString();
      // The two-line value lives inside one quoted field on one row.
      expect(exported, '<ID>;<English>\r\nk1;"line1\nline2"');
      // No bare physical row split: `\r\n` only separates the two rows.
      expect(exported.split('\r\n').length, 2);
    });

    test('carriage return in value is quoted too', () async {
      final base = await seedCsv('base2.csv', '<ID>;<English>\r\nk1;plain\r\n');
      final target = File('${tempDir.path}/out2.csv');

      await runExport(base, target, {'k1': 'a\rb'});

      expect(await target.readAsString(), '<ID>;<English>\r\nk1;"a\rb"');
    });
  });

  group('F2-3 (LOW): quote-aware column splitting', () {
    test('parse keeps a quoted semicolon inside one raw value', () async {
      final csv = await seedCsv(
        'quoted.csv',
        '<ID>;<English>\r\nk1;"some;value";leftover',
      );

      final parsed = await parseCsvWorker(CsvTaskParameters(csv.path));

      expect(parsed['k1'], 'some;value');
    });

    test('export re-split introduces no stray columns', () async {
      final base = await seedCsv(
        'base.csv',
        '<ID>;<English>\r\nk1;"some;value";x\r\n',
      );
      final target = File('${tempDir.path}/out.csv');

      final ok = await runExport(base, target, {'k1': 'OVR'});
      expect(ok, isTrue);

      expect(await target.readAsString(), '<ID>;<English>\r\nk1;OVR;x');
    });
  });

  group('F1-3 (LOW): atomic rename export', () {
    test('success leaves only the final file - no .tmp residue', () async {
      final base = await seedCsv('base.csv', '<ID>;<English>\r\nk1;v\r\n');
      final target = File('${tempDir.path}/out.csv');

      final ok = await runExport(base, target, {'k1': 'patched'});
      expect(ok, isTrue);

      expect(await target.readAsString(), '<ID>;<English>\r\nk1;patched');
      expect(tmpResidueExists(), isFalse);
    });

    test('failed export cleans up its .tmp staging file', () async {
      final base = await seedCsv('base.csv', '<ID>;<English>\r\nk1;v\r\n');
      final dirAsTarget = await Directory('${tempDir.path}/out').create();

      await expectLater(
        runExport(base, dirAsTarget, {'k1': 'patched'}),
        throwsA(isA<FileSystemException>()),
      );
      expect(tmpResidueFiles(), isEmpty);
    });
  });

  group('F1-4 (LOW): export synthesizes from the fresh base file', () {
    test('post-update base content survives the next export', () async {
      final langDir = Directory('${tempDir.path}/lang');
      await langDir.create();
      final units = File('${langDir.path}/units.csv');
      await units.writeAsString('<ID>;<English>\r\nk1;old\r\n');

      // First export creates the .orig restore artifact.
      expect(await runExport(units, units, {}), isTrue);

      // A game update rewrites the lang CSV with fresh strings.
      await units.writeAsString('<ID>;<English>\r\nk1;new\r\nk2;fresh\r\n');

      expect(await runExport(units, units, {'k1': 'override'}), isTrue);

      final exported = await units.readAsString();
      expect(exported, contains('k2;fresh'));
      expect(exported, contains('k1;override'));
      // .orig stays the untouched create-once restore artifact.
      expect(
        await File('${units.path}.orig').readAsString(),
        contains('k1;old'),
      );
    });
  });

  group('F2-6 (INFO): non-UTF-8 packs still parse for display', () {
    test(
      'invalid UTF-8 bytes decode with replacement chars, no throw',
      () async {
        final bytes = <int>[
          ...'<ID>;<English>\r\n'.codeUnits,
          ...'k1;'.codeUnits,
          0xFF, 0xD0, 0xFF, // raw non-UTF-8 payload (legacy cp1251-style pack)
          0x0D, 0x0A,
        ];
        final csv = File('${tempDir.path}/legacy.csv');
        await csv.writeAsBytes(bytes);

        final parsed = await parseCsvWorker(CsvTaskParameters(csv.path));

        expect(parsed['k1'], contains('\uFFFD'));
      },
    );
  });

  group('F2-7 (INFO): export re-emits the base file BOM', () {
    test('BOM base -> BOM export; clean base -> no BOM', () async {
      // writeAsString drops a leading U+FEFF, so seed the BOM via raw bytes.
      final bomBase = File('${tempDir.path}/bom.csv');
      await bomBase.writeAsBytes(
        utf8.encode('\uFEFF<ID>;<English>\r\nk1;v\r\n'),
      );
      final bomTarget = File('${tempDir.path}/out_bom.csv');
      await runExport(bomBase, bomTarget, {'k1': 'patched'});

      // Byte-level check: the base BOM (EF BB BF) must be re-emitted.
      final bomBytes = await bomTarget.readAsBytes();
      expect(bomBytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bomBytes), '<ID>;<English>\r\nk1;patched');

      final cleanBase = await seedCsv(
        'clean.csv',
        '<ID>;<English>\r\nk1;v\r\n',
      );
      final cleanTarget = File('${tempDir.path}/out_clean.csv');
      await runExport(cleanBase, cleanTarget, {});
      final cleanBytes = await cleanTarget.readAsBytes();
      expect(cleanBytes.take(3), isNot([0xEF, 0xBB, 0xBF]));
      expect(utf8.decode(cleanBytes), '<ID>;<English>\r\nk1;v');
    });
  });
}
