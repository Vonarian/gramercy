import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/about_gramercy_dialog.dart';
import 'package:gramercy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('War Thunder Editor App boots and renders command header', (
    tester,
  ) async {
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

    expect(find.text('GRAMERCY'), findsOneWidget);
    expect(find.text('Deploy to Game'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await db.close();
  });

  testWidgets(
    'VirtualizedLocalizationList renders with itemExtent 56 and valid scroll controller',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        PreferencesService.keyWtInstallPath: r'C:\Games\WarThunder',
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
            baseStringsProvider('units.csv').overrideWith(
              (ref) => Future.value({
                'us_m4a3_76w_sherman': 'M4A3 (76) W',
                'germ_tiger_ii': 'Tiger II (H)',
                'ussr_t_34_85': 'T-34-85',
              }),
            ),
            overridesProvider('units.csv').overrideWith(
              (ref) =>
                  Stream.value({'us_m4a3_76w_sherman': 'Easy Eight Sherman'}),
            ),
          ],
          child: const WarThunderEditorApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify rows rendered
      expect(find.text('us_m4a3_76w_sherman'), findsOneWidget);
      expect(find.text('Easy Eight Sherman'), findsOneWidget);
      expect(find.text('MODIFIED'), findsOneWidget);
      expect(find.text('germ_tiger_ii'), findsOneWidget);

      // Verify ListView configuration
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.itemExtent, equals(56.0));
      expect(listView.controller, isNotNull);

      // Verify Scrollbar configuration and that scroll controller is attached
      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      expect(scrollbar.controller, equals(listView.controller));

      await db.close();
    },
  );

  testWidgets(
    'AboutGramercyDialog opens on info click and displays BEAC safety card',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
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

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the info/about button
      final aboutButton = find.byTooltip('About & BattlEye Safety');
      expect(aboutButton, findsOneWidget);
      await tester.tap(aboutButton);
      await tester.pumpAndSettle();

      // Verify dialog content
      final dialog = find.byType(AboutGramercyDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Gramercy Cockpit')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('100% BattlEye Anti-Cheat (BEAC) Safe'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('testLocalization:b=yes'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('[T-4-6]')),
        findsOneWidget,
      );

      // Tap close
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutGramercyDialog), findsNothing);

      await db.close();
    },
  );
}
