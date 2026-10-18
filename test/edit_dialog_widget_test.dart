import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/edit_dialog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDb extends Mock implements AppDatabase {}

LocalizationEntry _entry({
  String key = 'army_tank_label',
  String? base,
  String? value,
  bool overridden = true,
}) {
  final baseText = base ?? 'M4A3 Sherman';
  return LocalizationEntry(
    key: key,
    value: value ?? baseText,
    baseValue: baseText,
    isOverridden: overridden,
  );
}

Future<void> _openDialog(
  WidgetTester tester,
  AppDatabase db,
  PreferencesService prefs, {
  required LocalizationEntry entry,
  String fileName = 'units.csv',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(0.5)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => EditLocalizationDialog.show(
                context,
                fileName: fileName,
                entry: entry,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockDb db;
  late PreferencesService prefs;

  setUpAll(() {
    registerFallbackValue(
      LocalizationsOverridesCompanion.insert(
        fileName: 'x',
        stringKey: 'x',
        customValue: 'x',
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
    db = _MockDb();
  });

  testWidgets('renders title, file name, MODIFIED badge when overridden', (
    tester,
  ) async {
    await _openDialog(tester, db, prefs, entry: _entry());

    expect(find.text('Edit Localization String'), findsOneWidget);
    expect(find.text('units.csv'), findsOneWidget);
    expect(find.text('MODIFIED'), findsOneWidget);
  });

  testWidgets('hides MODIFIED badge and revert action when not overridden', (
    tester,
  ) async {
    await _openDialog(tester, db, prefs, entry: _entry(overridden: false));

    expect(find.text('MODIFIED'), findsNothing);
    expect(find.text('Revert to Base'), findsNothing);
  });

  testWidgets('save persists the typed override and closes the dialog', (
    tester,
  ) async {
    final saved = <LocalizationsOverridesCompanion>[];
    when(() => db.saveOverride(any())).thenAnswer((inv) async {
      saved.add(
        inv.positionalArguments.first as LocalizationsOverridesCompanion,
      );
    });

    await _openDialog(tester, db, prefs, entry: _entry());
    await tester.enterText(find.byType(TextField), 'M4A3 (76) W');
    await tester.tap(find.text('Save Override'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single.fileName.value, 'units.csv');
    expect(saved.single.stringKey.value, 'army_tank_label');
    expect(saved.single.customValue.value, 'M4A3 (76) W');
    expect(find.byType(EditLocalizationDialog), findsNothing);
  });

  testWidgets('saving the base value while overridden deletes instead', (
    tester,
  ) async {
    final deleted = <List<dynamic>>[];
    when(() => db.deleteOverride(any(), any())).thenAnswer((inv) async {
      deleted.add(inv.positionalArguments);
      return 1;
    });

    await _openDialog(tester, db, prefs, entry: _entry(base: 'M4A3 Sherman'));
    await tester.enterText(find.byType(TextField), 'M4A3 Sherman');
    await tester.tap(find.text('Save Override'));
    await tester.pumpAndSettle();

    expect(deleted, hasLength(1));
    expect(deleted.single, ['units.csv', 'army_tank_label']);
    verifyNever(() => db.saveOverride(any()));
    expect(find.byType(EditLocalizationDialog), findsNothing);
  });

  testWidgets('revert button deletes the override and closes', (tester) async {
    when(() => db.deleteOverride(any(), any())).thenAnswer((_) async => 1);
    await _openDialog(tester, db, prefs, entry: _entry());

    await tester.tap(find.text('Revert to Base'));
    await tester.pumpAndSettle();

    verify(() => db.deleteOverride('units.csv', 'army_tank_label')).called(1);
    verifyNever(() => db.saveOverride(any()));
    expect(find.byType(EditLocalizationDialog), findsNothing);
  });

  testWidgets('cancel closes without touching the database', (tester) async {
    await _openDialog(tester, db, prefs, entry: _entry());

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => db.saveOverride(any()));
    verifyNever(() => db.deleteOverride(any(), any()));
    expect(find.byType(EditLocalizationDialog), findsNothing);
  });

  testWidgets('shows saving spinner and hides actions until write ends', (
    tester,
  ) async {
    final hold = Completer<void>();
    when(() => db.saveOverride(any())).thenAnswer((_) => hold.future);
    await _openDialog(
      tester,
      db,
      prefs,
      entry: _entry(base: 'M4A3 Sherman', value: 'M4A3 (76) W'),
    );

    await tester.tap(find.text('Save Override'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save Override'), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(EditLocalizationDialog), findsNothing);
  });
}
