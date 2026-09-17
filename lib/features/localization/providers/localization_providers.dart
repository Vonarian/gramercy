import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/features/localization/models/localization_entry.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:gramercy/features/localization/providers/environment_providers.dart';
import 'package:path/path.dart' as p;

export 'package:gramercy/features/localization/models/localization_entry.dart';
export 'package:gramercy/features/localization/providers/config_providers.dart';
export 'package:gramercy/features/localization/providers/db_provider.dart';
export 'package:gramercy/features/localization/providers/environment_providers.dart';
export 'package:gramercy/features/localization/providers/export_providers.dart';

/// 1. Base Game Strings (Loaded via Worker isolate)
final baseStringsProvider = FutureProvider.family<Map<String, String>, String>((ref, fileName) async {
  final wtPath = ref.watch(wtPathProvider);
  if (wtPath == null || wtPath.isEmpty) return {};

  final filePath = p.join(wtPath, 'lang', fileName);
  return ref.watch(workerServiceProvider).loadBaseStrings(filePath);
});

/// Pre-indexed Base Entries (constructed once per file, avoids repeated allocations)
final baseEntriesProvider = Provider.family<List<LocalizationEntry>, String>((ref, fileName) {
  final base = ref.watch(baseStringsProvider(fileName)).value ?? {};
  if (base.isEmpty) return const [];

  return base.entries.map((e) {
    return LocalizationEntry(
      key: e.key,
      value: e.value,
      baseValue: e.value,
      isOverridden: false,
      lowerKey: e.key.toLowerCase(),
      lowerValue: e.value.toLowerCase(),
    );
  }).toList(growable: false);
});

/// 2. User Overrides (Streamed directly from Drift SQLite)
final overridesProvider = StreamProvider.family<Map<String, String>, String>((ref, fileName) {
  final db = ref.watch(dbProvider);
  return db.watchOverridesForFile(fileName).map((list) {
    return {for (var item in list) item.stringKey: item.customValue};
  });
});

/// 3. The Synthesized View (Reuses base entries to eliminate 40,000 object allocations)
final synthesizedStringsProvider = Provider.family<List<LocalizationEntry>, String>((ref, fileName) {
  final baseEntries = ref.watch(baseEntriesProvider(fileName));
  final overrides = ref.watch(overridesProvider(fileName)).value ?? {};

  if (overrides.isEmpty) return baseEntries;

  final List<LocalizationEntry> entries = [];
  final Set<String> overriddenHandled = {};

  for (var i = 0; i < baseEntries.length; i++) {
    final baseEntry = baseEntries[i];
    final customVal = overrides[baseEntry.key];

    if (customVal != null) {
      overriddenHandled.add(baseEntry.key);
      entries.add(LocalizationEntry(
        key: baseEntry.key,
        value: customVal,
        baseValue: baseEntry.baseValue,
        isOverridden: true,
        lowerKey: baseEntry.lowerKey,
        lowerValue: customVal.toLowerCase(),
      ));
    } else {
      entries.add(baseEntry);
    }
  }

  if (overriddenHandled.length < overrides.length) {
    for (final overrideEntry in overrides.entries) {
      if (!overriddenHandled.contains(overrideEntry.key)) {
        entries.add(LocalizationEntry(
          key: overrideEntry.key,
          value: overrideEntry.value,
          baseValue: '',
          isOverridden: true,
        ));
      }
    }
  }

  return entries;
});

class SearchQueryNotifier extends Notifier<String> {
  Timer? _timer;
  static const debounceDelay = Duration(milliseconds: 150);

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  void setQuery(String q, {bool immediate = false}) {
    _timer?.cancel();
    if (immediate || q.isEmpty) {
      state = q;
      return;
    }
    _timer = Timer(debounceDelay, () {
      state = q;
    });
  }

  void clear() {
    _timer?.cancel();
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class FilterModeNotifier extends Notifier<FilterMode> {
  @override
  FilterMode build() => FilterMode.all;
  void setMode(FilterMode mode) => state = mode;
}

final filterModeProvider = NotifierProvider<FilterModeNotifier, FilterMode>(FilterModeNotifier.new);

/// High-performance filtering with fast-path and pre-indexed case-insensitive comparisons
final filteredStringsProvider = Provider.family<List<LocalizationEntry>, String>((ref, fileName) {
  final allEntries = ref.watch(synthesizedStringsProvider(fileName));
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filterMode = ref.watch(filterModeProvider);

  if (query.isEmpty && filterMode == FilterMode.all) {
    return allEntries;
  }

  final results = <LocalizationEntry>[];
  final matchOverridden = filterMode == FilterMode.overriddenOnly;
  final matchUnmodified = filterMode == FilterMode.unmodifiedOnly;

  for (var i = 0; i < allEntries.length; i++) {
    final entry = allEntries[i];
    if (matchOverridden && !entry.isOverridden) continue;
    if (matchUnmodified && entry.isOverridden) continue;
    if (query.isNotEmpty && !entry.matchesQuery(query)) continue;
    results.add(entry);
  }

  return results;
});
