import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/logging/app_logger.dart';

final presetServiceProvider = Provider<PresetService>((ref) {
  return const PresetService();
});

class PresetService {
  const PresetService();

  static const String currentFormat = 'gramercy_preset_v1';
  static const String currentVersion = '1.0';
  static const String defaultSource = 'Gramercy WT Localization Cockpit';

  String serializePreset(
    List<LocalizationsOverride> overrides, {
    DateTime? exportedAt,
    String? source,
  }) {
    final payload = {
      'format': currentFormat,
      'version': currentVersion,
      'source': source ?? defaultSource,
      'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
      'overrides': overrides
          .map(
            (o) => {
              'file': o.fileName,
              'key': o.stringKey,
              'value': o.customValue,
            },
          )
          .toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    final jsonResult = encoder.convert(payload);
    AppLogger.instance.i(
      'Serialized ${overrides.length} overrides to preset format',
      tag: 'PRESET',
    );
    return jsonResult;
  }

  List<LocalizationsOverridesCompanion> deserializePreset(String jsonString) {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw const FormatException('File does not contain valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root of preset JSON must be an object.');
    }

    final format = decoded['format'];
    if (format != currentFormat) {
      throw FormatException(
        'Incompatible preset format: "$format". Expected "$currentFormat".',
      );
    }

    final rawOverrides = decoded['overrides'];
    if (rawOverrides is! List) {
      throw const FormatException('Missing or invalid "overrides" list.');
    }

    final companions = <LocalizationsOverridesCompanion>[];
    for (final item in rawOverrides) {
      if (item is! Map) continue;
      final file = item['file'];
      final key = item['key'];
      final value = item['value'];

      if (file is String &&
          file.isNotEmpty &&
          key is String &&
          key.isNotEmpty &&
          value is String) {
        companions.add(
          LocalizationsOverridesCompanion.insert(
            fileName: file,
            stringKey: key,
            customValue: value,
          ),
        );
      }
    }

    AppLogger.instance.i(
      'Deserialized ${companions.length} valid overrides from preset JSON',
      tag: 'PRESET',
    );
    return companions;
  }
}
