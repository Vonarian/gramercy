import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/services/preset_service.dart';

void main() {
  late PresetService presetService;

  setUp(() {
    presetService = const PresetService();
  });

  group('PresetService Tests', () {
    test('serializePreset produces valid gramercy_preset_v1 JSON', () {
      final now = DateTime.utc(2026, 9, 18, 12, 0, 0);
      final overrides = [
        LocalizationsOverride(
          id: 1,
          fileName: 'units.csv',
          stringKey: 'us_m4a3_76w_sherman',
          customValue: 'M4A3 (76) W Sherman',
          updatedAt: now,
        ),
        LocalizationsOverride(
          id: 2,
          fileName: 'menu.csv',
          stringKey: 'btn_battle',
          customValue: 'ENGAGE!',
          updatedAt: now,
        ),
      ];

      final jsonString = presetService.serializePreset(
        overrides,
        exportedAt: now,
      );
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(map['format'], equals('gramercy_preset_v1'));
      expect(map['version'], equals('1.0'));
      expect(map['source'], equals('Gramercy WT Localization Cockpit'));
      expect(map['exportedAt'], equals(now.toIso8601String()));

      final list = map['overrides'] as List<dynamic>;
      expect(list.length, equals(2));
      expect(list[0]['file'], equals('units.csv'));
      expect(list[0]['key'], equals('us_m4a3_76w_sherman'));
      expect(list[0]['value'], equals('M4A3 (76) W Sherman'));
      expect(list[1]['file'], equals('menu.csv'));
      expect(list[1]['key'], equals('btn_battle'));
      expect(list[1]['value'], equals('ENGAGE!'));
    });

    test('deserializePreset parses valid gramercy_preset_v1 JSON', () {
      const jsonStr = '''
      {
        "format": "gramercy_preset_v1",
        "version": "1.0",
        "source": "Community Pack",
        "exportedAt": "2026-09-18T12:00:00.000Z",
        "overrides": [
          {
            "file": "units.csv",
            "key": "germ_tiger_1",
            "value": "Tiger I Ausf. E"
          },
          {
            "file": "ui.csv",
            "key": "victory",
            "value": "MISSION ACCOMPLISHED"
          }
        ]
      }
      ''';

      final companions = presetService.deserializePreset(jsonStr);

      expect(companions.length, equals(2));
      expect(companions[0].fileName.value, equals('units.csv'));
      expect(companions[0].stringKey.value, equals('germ_tiger_1'));
      expect(companions[0].customValue.value, equals('Tiger I Ausf. E'));

      expect(companions[1].fileName.value, equals('ui.csv'));
      expect(companions[1].stringKey.value, equals('victory'));
      expect(companions[1].customValue.value, equals('MISSION ACCOMPLISHED'));
    });

    test('deserializePreset throws FormatException on invalid format tag', () {
      const invalidFormat = '''
      {
        "format": "unknown_format",
        "version": "1.0",
        "overrides": []
      }
      ''';

      expect(
        () => presetService.deserializePreset(invalidFormat),
        throwsFormatException,
      );
    });

    test('deserializePreset throws FormatException on malformed JSON', () {
      const malformedJson = '{ broken json ';

      expect(
        () => presetService.deserializePreset(malformedJson),
        throwsFormatException,
      );
    });

    test(
      'deserializePreset skips corrupted entries missing required fields',
      () {
        const jsonWithInvalidItems = '''
      {
        "format": "gramercy_preset_v1",
        "version": "1.0",
        "overrides": [
          { "file": "units.csv", "key": "k1", "value": "v1" },
          { "file": "units.csv", "key": "k2" },
          { "key": "k3", "value": "v3" },
          { "file": "units.csv", "key": "k4", "value": "v4" }
        ]
      }
      ''';

        final companions = presetService.deserializePreset(
          jsonWithInvalidItems,
        );
        expect(companions.length, equals(2));
        expect(companions[0].stringKey.value, equals('k1'));
        expect(companions[1].stringKey.value, equals('k4'));
      },
    );
  });
}
