import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDb extends Mock implements AppDatabase {}

void main() {
  group('Override count stream providers', () {
    test(
      'fileOverridesCountProvider streams the drift count for the file',
      () async {
        final db = _MockDb();
        when(() => db.watchOverridesCountForFile('units.csv'))
            .thenAnswer((_) => Stream.value(7));

        final container = ProviderContainer(
          overrides: [dbProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        final values = <int>[];
        final sub = container.listen(fileOverridesCountProvider('units.csv'), (
          _,
          next,
        ) {
          if (next case AsyncData(:final value)) values.add(value);
        });
        addTearDown(sub.close);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(values, contains(7));
        verify(() => db.watchOverridesCountForFile('units.csv')).called(1);
      },
    );

    test('totalOverridesCountProvider streams the drift total count', () async {
      final db = _MockDb();
      when(() => db.watchTotalOverridesCount())
          .thenAnswer((_) => Stream.value(42));

      final container = ProviderContainer(
        overrides: [dbProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final values = <int>[];
      final sub = container.listen(totalOverridesCountProvider, (_, next) {
        if (next case AsyncData(:final value)) values.add(value);
      });
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(values, contains(42));
    });

    test(
      'file stream identity survives a widget rebuild (no re-subscribe churn)',
      () async {
        // Regression net for status_bar: the same stream object must be
        // served while the provider is unchanged (Riverpod caches it),
        // instead of building a fresh drift watch() per widget build.
        final db = _MockDb();
        late StreamController<int> ctrl;
        ctrl = StreamController<int>.broadcast();
        addTearDown(() => ctrl.close());
        Stream<int> streamFactory() => ctrl.stream;
        when(() => db.watchOverridesCountForFile(any()))
            .thenAnswer((_) => streamFactory());

        final container = ProviderContainer(
          overrides: [dbProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        final first = container.read(fileOverridesCountProvider('ui.csv'));
        final second = container.read(fileOverridesCountProvider('ui.csv'));

        expect(identical(first, second), isTrue);
      },
    );
  });
}
