import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

void main() {
  group('Search Debounce & Indexing Unit Tests', () {
    test('LocalizationEntry pre-indexes lowerKey and lowerValue', () {
      final entry = LocalizationEntry(
        key: 'US_M4A3_76W_Sherman',
        value: 'Easy Eight Sherman',
        baseValue: 'M4A3 (76) W',
        isOverridden: true,
      );

      expect(entry.lowerKey, equals('us_m4a3_76w_sherman'));
      expect(entry.lowerValue, equals('easy eight sherman'));
      expect(entry.matchesQuery('m4a3'), isTrue);
      expect(entry.matchesQuery('EIGHT'), isFalse);
      expect(entry.matchesQuery('eight'), isTrue);
      expect(entry.matchesQuery('tiger'), isFalse);
    });

    test('SearchQueryNotifier debounces updates by 150ms', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchQueryProvider.notifier);
      expect(container.read(searchQueryProvider), equals(''));

      notifier.setQuery('tiger');
      expect(container.read(searchQueryProvider), equals(''));

      await Future.delayed(const Duration(milliseconds: 160));
      expect(container.read(searchQueryProvider), equals('tiger'));
    });

    test('SearchQueryNotifier cancels prior timer on rapid keystrokes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchQueryProvider.notifier);

      notifier.setQuery('s');
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('sh');
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('sher');
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('sherman');

      expect(container.read(searchQueryProvider), equals(''));

      await Future.delayed(const Duration(milliseconds: 160));
      expect(container.read(searchQueryProvider), equals('sherman'));
    });

    test('SearchQueryNotifier clears immediately on empty query or immediate flag', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchQueryProvider.notifier);

      notifier.setQuery('panther', immediate: true);
      expect(container.read(searchQueryProvider), equals('panther'));

      notifier.setQuery('');
      expect(container.read(searchQueryProvider), equals(''));
    });
  });

  group('Large Dataset Synthesis & Filtering Performance Tests', () {
    test('synthesizedStringsProvider reuses unchanged instances when overrides change', () async {
      const totalEntries = 5000;
      final baseMap = <String, String>{
        for (var i = 0; i < totalEntries; i++) 'key_$i': 'Value $i',
      };

      final overridesStreamController = StreamController<Map<String, String>>();
      addTearDown(overridesStreamController.close);

      final container = ProviderContainer(
        overrides: [
          baseStringsProvider('test.csv').overrideWith((ref) => Future.value(baseMap)),
          overridesProvider('test.csv').overrideWith((ref) => overridesStreamController.stream),
        ],
      );
      addTearDown(container.dispose);

      overridesStreamController.add({});
      container.listen(synthesizedStringsProvider('test.csv'), (_, _) {});
      await pumpEventQueue();

      final firstPass = container.read(synthesizedStringsProvider('test.csv'));
      expect(firstPass.length, equals(totalEntries));

      overridesStreamController.add({'key_42': 'Overridden Value 42'});
      await pumpEventQueue();

      final secondPass = container.read(synthesizedStringsProvider('test.csv'));
      expect(secondPass.length, equals(totalEntries));

      final overridden = secondPass.firstWhere((e) => e.key == 'key_42');
      expect(overridden.isOverridden, isTrue);
      expect(overridden.value, equals('Overridden Value 42'));

      final unchangedFirst = firstPass.firstWhere((e) => e.key == 'key_0');
      final unchangedSecond = secondPass.firstWhere((e) => e.key == 'key_0');
      expect(identical(unchangedFirst, unchangedSecond), isTrue,
          reason: 'Unmodified entries must reuse the exact same LocalizationEntry instance');
    });

    test('filteredStringsProvider filters 40,000 items in < 50ms', () async {
      const count = 40000;
      final baseMap = <String, String>{
        for (var i = 0; i < count; i++) 'ui_button_action_$i': 'Click button number $i to confirm',
      };
      baseMap['ui_special_target'] = 'Unique special needle text';

      final container = ProviderContainer(
        overrides: [
          baseStringsProvider('ui.csv').overrideWith((ref) => Future.value(baseMap)),
          overridesProvider('ui.csv').overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      container.listen(filteredStringsProvider('ui.csv'), (_, _) {});
      await pumpEventQueue();

      final all = container.read(filteredStringsProvider('ui.csv'));
      expect(all.length, equals(count + 1));

      final stopwatch = Stopwatch()..start();
      container.read(searchQueryProvider.notifier).setQuery('needle', immediate: true);
      final results = container.read(filteredStringsProvider('ui.csv'));
      stopwatch.stop();

      expect(results.length, equals(1));
      expect(results.first.key, equals('ui_special_target'));
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Filtering 40,000 pre-indexed entries should take under 50ms');
    });
  });

  group('Worker Isolate Filter Tests', () {
    test('filterEntriesWorker correctly filters entries by query and mode', () {
      final entries = [
        LocalizationEntry(
          key: 'us_m4a3',
          value: 'M4A3 Sherman',
          baseValue: 'M4A3 Sherman',
          isOverridden: false,
        ),
        LocalizationEntry(
          key: 'germ_tiger_ii',
          value: 'King Tiger Custom',
          baseValue: 'Tiger II',
          isOverridden: true,
        ),
        LocalizationEntry(
          key: 'ussr_t34',
          value: 'T-34-85',
          baseValue: 'T-34-85',
          isOverridden: false,
        ),
      ];

      // 1. Filter by query
      final queryFiltered = filterEntriesWorker(FilterTaskParameters(
        entries: entries,
        query: 'tiger',
      ));
      expect(queryFiltered.length, equals(1));
      expect(queryFiltered.first.key, equals('germ_tiger_ii'));

      // 2. Filter by overridden only
      final overriddenFiltered = filterEntriesWorker(FilterTaskParameters(
        entries: entries,
        query: '',
        filterMode: FilterMode.overriddenOnly,
      ));
      expect(overriddenFiltered.length, equals(1));
      expect(overriddenFiltered.first.key, equals('germ_tiger_ii'));

      // 3. Filter by unmodified only
      final unmodifiedFiltered = filterEntriesWorker(FilterTaskParameters(
        entries: entries,
        query: '',
        filterMode: FilterMode.unmodifiedOnly,
      ));
      expect(unmodifiedFiltered.length, equals(2));

      // 4. Empty query and all
      final allFiltered = filterEntriesWorker(FilterTaskParameters(
        entries: entries,
        query: '',
        filterMode: FilterMode.all,
      ));
      expect(allFiltered.length, equals(3));
    });
  });
}
