import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wt_csv_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CSV Worker Parser & Exporter Tests', () {
    test(
      'parseCsvWorker parses semicolon-delimited War Thunder CSV correctly',
      () async {
        final csvFile = File('${tempDir.path}/units.csv');
        await csvFile.writeAsString(
          '<ID>;<English>;<French>;<German>\r\n'
          'us_m4a3_76w_sherman;M4A3 (76) W;M4A3 (76) W;M4A3 (76) W\r\n'
          'germ_pzkpfw_VI_ausf_B_tiger_IIh;""Tiger II (H)"";""Tiger II (H)"";""Tiger II (H)""\r\n'
          'ussr_t_34_85_d_5t;T-34-85 (D-5T);T-34-85 (D-5T);T-34-85 (D-5T)\r\n',
        );

        final result = await parseCsvWorker(CsvTaskParameters(csvFile.path));

        expect(result.length, equals(3));
        expect(result['us_m4a3_76w_sherman'], equals('M4A3 (76) W'));
        // Verifies quotes are properly unescaped
        expect(
          result['germ_pzkpfw_VI_ausf_B_tiger_IIh'],
          equals('"Tiger II (H)"'),
        );
        expect(result['ussr_t_34_85_d_5t'], equals('T-34-85 (D-5T)'));
      },
    );

    test('parseCsvWorker handles UTF-8 BOM smoothly', () async {
      final csvFile = File('${tempDir.path}/bom_units.csv');
      await csvFile.writeAsString(
        '\uFEFF<ID>;<English>\r\n'
        'spitfire_mk9;Spitfire F Mk.IX\r\n',
      );

      final result = await parseCsvWorker(CsvTaskParameters(csvFile.path));
      expect(result.length, equals(1));
      expect(result['spitfire_mk9'], equals('Spitfire F Mk.IX'));
    });

    test('exportPatchedCsvWorker preserves other language columns and applies overrides', () async {
      final baseFile = File('${tempDir.path}/units.csv');
      await baseFile.writeAsString(
        '<ID>;<English>;<French>;<German>\r\n'
        'us_m4a3_76w_sherman;M4A3 (76) W;M4A3 (76) W;M4A3 (76) W\r\n'
        'ussr_t_34_85_d_5t;T-34-85;T-34-85;T-34-85\r\n',
      );

      final targetFile = File('${tempDir.path}/exported_units.csv');
      final overrides = {'us_m4a3_76w_sherman': 'Easy Eight Sherman'};

      final success = await exportPatchedCsvWorker(
        ExportTaskParameters(
          baseFilePath: baseFile.path,
          targetFilePath: targetFile.path,
          overrides: overrides,
        ),
      );

      expect(success, isTrue);
      expect(await targetFile.exists(), isTrue);

      final parsed = await parseCsvWorker(CsvTaskParameters(targetFile.path));
      expect(parsed['us_m4a3_76w_sherman'], equals('Easy Eight Sherman'));
      expect(parsed['ussr_t_34_85_d_5t'], equals('T-34-85'));

      // Check raw content preserves French/German columns
      final rawTarget = await targetFile.readAsString();
      expect(
        rawTarget.contains('Easy Eight Sherman;M4A3 (76) W;M4A3 (76) W'),
        isTrue,
      );
    });
  });
}
