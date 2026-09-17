import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/models/localization_entry.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:gramercy/features/localization/providers/environment_providers.dart';
import 'package:path/path.dart' as p;

export 'package:gramercy/features/localization/models/localization_entry.dart';
export 'package:gramercy/features/localization/providers/config_providers.dart';
export 'package:gramercy/features/localization/providers/environment_providers.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('dbProvider must be overridden in ProviderScope');
});

/// 1. Base Game Strings (Loaded via Worker isolate)
final baseStringsProvider = FutureProvider.family<Map<String, String>, String>((ref, fileName) async {
  final wtPath = ref.watch(wtPathProvider);
  if (wtPath == null || wtPath.isEmpty) return {};

  final filePath = p.join(wtPath, 'lang', fileName);
  return ref.watch(workerServiceProvider).loadBaseStrings(filePath);
});

/// 2. User Overrides (Streamed directly from Drift SQLite)
final overridesProvider = StreamProvider.family<Map<String, String>, String>((ref, fileName) {
  final db = ref.watch(dbProvider);
  return db.watchOverridesForFile(fileName).map((list) {
    return {for (var item in list) item.stringKey: item.customValue};
  });
});

/// 3. The Synthesized View (Immutable merge of Base + Drift Overrides)
final synthesizedStringsProvider = Provider.family<List<LocalizationEntry>, String>((ref, fileName) {
  final base = ref.watch(baseStringsProvider(fileName)).value ?? {};
  final overrides = ref.watch(overridesProvider(fileName)).value ?? {};

  final List<LocalizationEntry> entries = [];
  final Set<String> processedKeys = {};

  for (final entry in base.entries) {
    final key = entry.key;
    final baseVal = entry.value;
    final isOverridden = overrides.containsKey(key);
    final currentVal = isOverridden ? overrides[key]! : baseVal;

    entries.add(LocalizationEntry(
      key: key,
      value: currentVal,
      baseValue: baseVal,
      isOverridden: isOverridden,
    ));
    processedKeys.add(key);
  }

  for (final overrideEntry in overrides.entries) {
    if (!processedKeys.contains(overrideEntry.key)) {
      entries.add(LocalizationEntry(
        key: overrideEntry.key,
        value: overrideEntry.value,
        baseValue: '',
        isOverridden: true,
      ));
    }
  }

  return entries;
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class FilterModeNotifier extends Notifier<FilterMode> {
  @override
  FilterMode build() => FilterMode.all;
  void setMode(FilterMode mode) => state = mode;
}

final filterModeProvider = NotifierProvider<FilterModeNotifier, FilterMode>(FilterModeNotifier.new);

final filteredStringsProvider = Provider.family<List<LocalizationEntry>, String>((ref, fileName) {
  final allEntries = ref.watch(synthesizedStringsProvider(fileName));
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filterMode = ref.watch(filterModeProvider);

  return allEntries.where((entry) {
    if (filterMode == FilterMode.overriddenOnly && !entry.isOverridden) {
      return false;
    }
    if (filterMode == FilterMode.unmodifiedOnly && entry.isOverridden) {
      return false;
    }
    if (query.isEmpty) return true;
    return entry.key.toLowerCase().contains(query) ||
        entry.value.toLowerCase().contains(query);
  }).toList();
});

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  Future<bool> exportCurrentFile() async {
    state = const ExportState(status: ExportStatus.inProgress, message: 'Deploying patches to game...');
    final wtPath = ref.read(wtPathProvider);
    final fileName = ref.read(selectedFileProvider);

    if (wtPath == null || wtPath.isEmpty) {
      state = const ExportState(status: ExportStatus.error, message: 'War Thunder install path is not set.');
      return false;
    }

    try {
      final db = ref.read(dbProvider);
      final overridesList = await db.getOverridesForFile(fileName);
      final overridesMap = {for (var o in overridesList) o.stringKey: o.customValue};

      final worker = ref.read(workerServiceProvider);
      final targetPath = p.join(wtPath, 'lang', fileName);

      final configBlkPath = p.join(wtPath, 'config.blk');
      if (File(configBlkPath).existsSync()) {
        await worker.patchConfigBlk(configBlkPath);
        ref.invalidate(configBlkStatusProvider);
      }

      await worker.exportPatchedCsv(
        baseFilePath: targetPath,
        targetFilePath: targetPath,
        overrides: overridesMap,
      );

      ref.invalidate(baseStringsProvider(fileName));

      state = ExportState(
        status: ExportStatus.success,
        message: 'Successfully deployed patches for $fileName to game!',
      );
      return true;
    } catch (e) {
      state = ExportState(status: ExportStatus.error, message: 'Export failed: $e');
      return false;
    }
  }

  void reset() => state = const ExportState();
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(ExportNotifier.new);

Future<void> saveLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
  required String customValue,
}) async {
  final db = ref.read(dbProvider);
  await db.saveOverride(
    LocalizationsOverridesCompanion.insert(
      fileName: fileName,
      stringKey: key,
      customValue: customValue,
    ),
  );

  if (ref.read(autoExportProvider)) {
    await ref.read(exportNotifierProvider.notifier).exportCurrentFile();
  }
}

Future<void> revertLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
}) async {
  final db = ref.read(dbProvider);
  await db.deleteOverride(fileName, key);

  if (ref.read(autoExportProvider)) {
    await ref.read(exportNotifierProvider.notifier).exportCurrentFile();
  }
}
