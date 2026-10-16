import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/security/lang_file_guard.dart';
import 'package:gramercy/features/localization/services/preset_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late PresetService presetService;

  setUp(() {
    presetService = const PresetService();
  });

  /// Builds a minimal gramercy_preset_v1 payload with a single override.
  String presetJson(String file, [String key = 'k1', String value = 'v1']) =>
      jsonEncode({
        'format': PresetService.currentFormat,
        'version': PresetService.currentVersion,
        'overrides': [
          {'file': file, 'key': key, 'value': value},
        ],
      });

  group('F1-1/F2-1: deserializePreset rejects unsafe preset target files', () {
    // Keyed by label; raw hostile values are deliberately NOT put into test
    // names (log-forging hygiene: control chars in descriptions pollute logs).
    final hostileTargets = <String, String>{
      'posix parent traversal': '../config.blk',
      'windows parent traversal': r'..\..\victim.csv',
      'absolute windows path': r'C:\tmp\v.csv',
      'windows drive-relative name': 'C:victim.csv',
      'untrimmed leading space': ' units.csv',
      'untrimmed trailing space': 'units.csv ',
      'missing csv suffix': 'units',
      'subdirectory escape': 'sub/units.csv',
      'control char in name': 'a\nb.csv',
    };

    hostileTargets.forEach((label, file) {
      test('rejects hostile target: $label', () {
        final json = presetJson(file);

        expect(
          () => presetService.deserializePreset(json),
          throwsFormatException,
        );
      });
    });
  });

  group('F1-1/F2-1: legitimate file names keep importing', () {
    test('bundled-style basenames pass validation untouched', () {
      const jsonStr = '''
      {
        "format": "gramercy_preset_v1",
        "version": "1.0",
        "source": "Community Pack",
        "overrides": [
          { "file": "units.csv", "key": "germ_tiger_1", "value": "Tiger I" },
          { "file": "menu.csv", "key": "btn_battle", "value": "ENGAGE!" },
          { "file": "ui.csv", "key": "victory", "value": "ACCOMPLISHED" },
          {
            "file": "pc_UiMessages.csv",
            "key": "pc_msg",
            "value": "Hello"
          }
        ]
      }
      ''';

      final companions = presetService.deserializePreset(jsonStr);

      expect(companions.length, equals(4));
      expect(companions[0].fileName.value, equals('units.csv'));
      expect(companions[1].fileName.value, equals('menu.csv'));
      expect(companions[2].fileName.value, equals('ui.csv'));
      expect(companions[3].fileName.value, equals('pc_UiMessages.csv'));
    });
  });

  group(
    'F2-2: imported field values are newline-normalized before storing',
    () {
      test('CR/LF in customValue becomes single spaces', () {
        final companions = presetService.deserializePreset(
          presetJson('units.csv', 'germ_tiger_1', 'line1\nline2'),
        );

        expect(companions, hasLength(1));
        expect(companions[0].customValue.value, equals('line1 line2'));
        expect(companions[0].customValue.value, isNot(contains('\n')));
        expect(companions[0].customValue.value, isNot(contains('\r')));
      });

      test('CRLF and lone CR variants in customValue become single spaces', () {
        final companions = presetService.deserializePreset(
          presetJson('units.csv', 'germ_tiger_1', 'a\r\nb\rc'),
        );

        expect(companions[0].customValue.value, equals('a b c'));
      });

      test('CR/LF in stringKey becomes single spaces', () {
        final companions = presetService.deserializePreset(
          presetJson('units.csv', 'germ\r\ntiger\n1\r', 'Tiger I'),
        );

        expect(companions[0].stringKey.value, equals('germ tiger 1 '));
        expect(companions[0].customValue.value, equals('Tiger I'));
      });
    },
  );

  group('F1-6: snapshot vault restore shares the same choke point', () {
    test('unsafe file field in vault JSON throws from deserializePreset', () {
      // snapshot_service.restoreSnapshot() parses vault JSON with this same
      // call, so one guard here covers both import flows.
      final vaultJson = presetJson(r'C:\tmp\v.csv');

      expect(
        () => presetService.deserializePreset(vaultJson),
        throwsFormatException,
      );
    });
  });

  group('LangFileGuard', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gramercy_preset_guard_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // Pins the exact isSafeLangFileName rule outcomes. Expectations are
    // platform-independent because every separator (both '/' and '\') and the
    // ':' drive/ADS marker are rejected explicitly before p.dirname-based
    // logic could ever see them.
    const ruleCases = <(String, String, bool)>[
      ('legit bundled name', 'units.csv', true),
      ('legit plural name', 'menu.csv', true),
      ('legit prefixed name', 'pc_UiMessages.csv', true),
      ('uppercase suffix ok (case-insensitive)', 'UNITS.CSV', true),
      ('inner dot ok', 'pc.UiMessages.csv', true),
      ('inner space ok (trim rule only covers edges)', 'my units.csv', true),
      ('bare .csv name', '.csv', true),
      ('posix parent traversal', '../config.blk', false),
      ('windows parent traversal', r'..\..\victim.csv', false),
      ('windows absolute path', r'C:\tmp\v.csv', false),
      (
        'windows drive-relative (no separator after colon)',
        'C:victim.csv',
        false,
      ),
      ('subdirectory escape', 'sub/units.csv', false),
      ('windows subdirectory escape', r'sub\units.csv', false),
      ('UNC path', r'\\host\share\v.csv', false),
      ('NTFS alternate data stream', 'units.csv:hidden', false),
      ('dot segment', '.', false),
      ('dot-dot segment', '..', false),
      ('empty', '', false),
      ('leading space (untrimmed)', ' units.csv', false),
      ('trailing space (untrimmed)', 'units.csv ', false),
      ('not csv suffix', 'units.blk', false),
      ('no suffix', 'units', false),
      ('control char', 'a\nb.csv', false),
    ];

    test('isSafeLangFileName pins every rule-set corner case', () {
      for (final (label, raw, expected) in ruleCases) {
        expect(isSafeLangFileName(raw), equals(expected), reason: label);
      }
    });

    test('safeLangFilePath joins safely inside wtPath/lang', () {
      final joined = p.join(tempDir.path, 'lang', 'units.csv');

      expect(safeLangFilePath(tempDir.path, 'units.csv'), equals(joined));
    });

    test('safeLangFilePath returns null for all unsafe variants', () {
      final unsafe = ruleCases.where((c) => !c.$3).toList();

      for (final (label, raw, _) in unsafe) {
        expect(safeLangFilePath(tempDir.path, raw), isNull, reason: label);
      }
    });
  });
}
