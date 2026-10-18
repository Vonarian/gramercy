import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';

/// Pins the worker_manager delegation wrapper (previously uncovered) and the
/// remaining parseCsvWorker edge branches: missing file and stray BOM
/// surviving a malformed/legacy decode.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gramercy_deleg_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalizationWorkerService isolate delegation', () {
    test(
      'loadBaseStrings parses a temp CSV through the isolate wrapper',
      () async {
        final csv = File('${tempDir.path}/units.csv');
        await csv.writeAsString('<ID>;<English>\r\nus_m4a3;M4A3 (76) W\r\n');

        final service = LocalizationWorkerService();
        final result = await service.loadBaseStrings(csv.path);

        expect(result, equals({'us_m4a3': 'M4A3 (76) W'}));
      },
    );

    test(
      'exportPatchedCsv applies overrides through the isolate wrapper',
      () async {
        final base = File('${tempDir.path}/units.csv');
        await base.writeAsString('<ID>;<English>\r\nus_m4a3;Stock\r\n');

        final service = LocalizationWorkerService();
        final ok = await service.exportPatchedCsv(
          baseFilePath: base.path,
          targetFilePath: base.path,
          overrides: {'us_m4a3': 'Easy Eight'},
        );

        expect(ok, isTrue);
        expect(await base.readAsString(), contains('us_m4a3;Easy Eight'));
      },
    );

    test(
      'configBlk delegates detect/patch through the isolate wrapper',
      () async {
        final config = File('${tempDir.path}/config.blk');
        await config.writeAsString('debug {\n  sound:b=yes\n}\n');

        final service = LocalizationWorkerService();

        final before = await service.checkConfigBlk(config.path);
        expect(before.isLocalizationEnabled, isFalse);

        expect(await service.patchConfigBlk(config.path), isTrue);

        final after = await service.checkConfigBlk(config.path);
        expect(after.isLocalizationEnabled, isTrue);
      },
    );
  });

  group('parseCsvWorker edge branches', () {
    test('returns empty map for a missing file', () async {
      final result = await parseCsvWorker(
        CsvTaskParameters('${tempDir.path}/does_not_exist.csv'),
      );
      expect(result, isEmpty);
    });

    test('strips a stray BOM that survives the decode', () async {
      // A double BOM: utf8 decoder consumes one; the residual one must be
      // stripped before parsing so the header does not poison keys.
      final csv = File('${tempDir.path}/double_bom.csv');
      await csv.writeAsBytes(
        utf8.encode('\uFEFF') +
            utf8.encode('\uFEFF') +
            utf8.encode('<ID>;<English>\r\nus_m4a3;M4A3 (76) W\r\n'),
      );

      final result = await parseCsvWorker(CsvTaskParameters(csv.path));

      expect(result, equals({'us_m4a3': 'M4A3 (76) W'}));
    });
  });
}
