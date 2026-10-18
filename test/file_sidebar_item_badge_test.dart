import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/file_sidebar_item.dart';
import 'package:mocktail/mocktail.dart';

class _MockDb extends Mock implements AppDatabase {}

void main() {
  testWidgets('sidebar item badge renders the streamed override count', (
    tester,
  ) async {
    final db = _MockDb();
    when(() => db.watchOverridesCountForFile('units.csv'))
        .thenAnswer((_) => Stream.value(7));
    when(() => db.watchOverridesForFile('units.csv')).thenAnswer(
      (_) => Stream.value(
        List.generate(
          7,
          (i) => LocalizationsOverride(
            id: i + 1,
            fileName: 'units.csv',
            stringKey: 'k$i',
            customValue: 'v$i',
            updatedAt: DateTime(2026),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(
            body: FileSidebarItem(
              file: 'units.csv',
              isSelected: false,
              isCollapsed: false,
              onTap: _noTap,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('7'),
      findsOneWidget,
      reason: 'badge must reflect the DB-driven count stream',
    );
  });
}

void _noTap() {}
