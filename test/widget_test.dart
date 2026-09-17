import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('War Thunder Editor App boots and renders command header', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      PreferencesService.keyWtInstallPath: '',
      PreferencesService.keyAutoExportOnSave: false,
      PreferencesService.keyLastOpenedCsv: 'units.csv',
    });

    final prefs = await SharedPreferences.getInstance();
    final prefsService = PreferencesService(prefs);
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefsService),
        ],
        child: const WarThunderEditorApp(),
      ),
    );

    // Pump initial frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('WT LOCALIZATION ENGINE'), findsOneWidget);
    expect(find.text('Deploy to Game'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await db.close();
  });
}
