import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

void main() {
  group('Riverpod Localization Synthesis & Filter Tests', () {
    test('synthesizedStringsProvider correctly merges base strings and overrides', () async {
      final container = ProviderContainer(
        overrides: [
          baseStringsProvider('units.csv').overrideWith(
            (ref) => Future.value({
              'us_m4a3_76w_sherman': 'M4A3 (76) W',
              'germ_pzkpfw_VI_ausf_B_tiger_IIh': 'Tiger II (H)',
              'ussr_t_34_85_d_5t': 'T-34-85 (D-5T)',
            }),
          ),
          overridesProvider('units.csv').overrideWith(
            (ref) => Stream.fromIterable([
              {'us_m4a3_76w_sherman': 'Easy Eight Sherman'},
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(synthesizedStringsProvider('units.csv'), (_, _) {});
      await pumpEventQueue();

      final entries = container.read(synthesizedStringsProvider('units.csv'));

      expect(entries.length, equals(3));

      final sherman = entries.firstWhere((e) => e.key == 'us_m4a3_76w_sherman');
      expect(sherman.isOverridden, isTrue);
      expect(sherman.value, equals('Easy Eight Sherman'));
      expect(sherman.baseValue, equals('M4A3 (76) W'));

      final tiger = entries.firstWhere((e) => e.key == 'germ_pzkpfw_VI_ausf_B_tiger_IIh');
      expect(tiger.isOverridden, isFalse);
      expect(tiger.value, equals('Tiger II (H)'));
    });

    test('filteredStringsProvider filters by query and filter mode', () async {
      final container = ProviderContainer(
        overrides: [
          baseStringsProvider('units.csv').overrideWith(
            (ref) => Future.value({
              'us_m4a3_76w_sherman': 'M4A3 (76) W',
              'germ_pzkpfw_VI_ausf_B_tiger_IIh': 'Tiger II (H)',
              'ussr_t_34_85_d_5t': 'T-34-85 (D-5T)',
            }),
          ),
          overridesProvider('units.csv').overrideWith(
            (ref) => Stream.fromIterable([
              {'us_m4a3_76w_sherman': 'Easy Eight Sherman'},
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(filteredStringsProvider('units.csv'), (_, _) {});
      await pumpEventQueue();

      // 1. Initial All
      var filtered = container.read(filteredStringsProvider('units.csv'));
      expect(filtered.length, equals(3));

      // 2. Query filter (debounced)
      container.read(searchQueryProvider.notifier).setQuery('tiger');
      await Future.delayed(const Duration(milliseconds: 160));
      filtered = container.read(filteredStringsProvider('units.csv'));
      expect(filtered.length, equals(1));
      expect(filtered.first.key, equals('germ_pzkpfw_VI_ausf_B_tiger_IIh'));

      // 3. Clear query, filter by modified only
      container.read(searchQueryProvider.notifier).setQuery('');
      container.read(filterModeProvider.notifier).setMode(FilterMode.overriddenOnly);
      filtered = container.read(filteredStringsProvider('units.csv'));
      expect(filtered.length, equals(1));
      expect(filtered.first.key, equals('us_m4a3_76w_sherman'));
    });
  });
}
