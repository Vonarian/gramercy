import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

final workerServiceProvider = Provider<LocalizationWorkerService>((ref) {
  return LocalizationWorkerService();
});

/// App version from the platform package metadata (pubspec `version`), so the
/// About dialog can never drift from the release version. Overridable in
/// widget tests to pin the rendered subtitle.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Lists the real (non-symlink) csv files inside [langDir], basenames only.
/// Symbolic links are excluded so hostile packs cannot expose files that
/// live outside the lang dir (F1-2). Unit-testable without providers.
Future<List<String>> visibleLangCsvFiles(Directory langDir) async {
  final csvFiles = <String>[];
  await for (final entity in langDir.list()) {
    if (_isLink(entity)) continue;
    if (entity is File && entity.path.toLowerCase().endsWith('.csv')) {
      csvFiles.add(p.basename(entity.path));
    }
  }
  return csvFiles;
}

bool _isLink(FileSystemEntity entity) =>
    FileSystemEntity.typeSync(entity.path, followLinks: false) ==
    FileSystemEntityType.link;

final availableFilesProvider = FutureProvider<List<String>>((ref) async {
  final wtPath = ref.watch(wtPathProvider);
  const defaultList = [
    'units.csv',
    'menu.csv',
    'missions.csv',
    'ui.csv',
    'hud.csv',
    'shop.csv',
    'encyclopedia.csv',
  ];

  if (wtPath == null || wtPath.isEmpty) {
    return defaultList;
  }

  final langDir = Directory(p.join(wtPath, 'lang'));
  if (!await langDir.exists()) {
    return defaultList;
  }

  final List<String> csvFiles;
  try {
    csvFiles = await visibleLangCsvFiles(langDir);
  } catch (_) {
    return defaultList;
  }

  if (csvFiles.isEmpty) {
    return defaultList;
  }

  csvFiles.sort((a, b) {
    if (a == 'units.csv') return -1;
    if (b == 'units.csv') return 1;
    return a.compareTo(b);
  });

  return csvFiles;
});

final configBlkStatusProvider = FutureProvider<ConfigBlkStatus>((ref) async {
  final wtPath = ref.watch(wtPathProvider);
  final worker = ref.watch(workerServiceProvider);

  if (wtPath == null || wtPath.isEmpty) {
    return const ConfigBlkStatus(
      exists: false,
      isLocalizationEnabled: false,
      filePath: '',
    );
  }

  final configPath = p.join(wtPath, 'config.blk');
  return worker.checkConfigBlk(configPath);
});
