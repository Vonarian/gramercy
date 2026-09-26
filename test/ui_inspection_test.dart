import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _captureToPng(WidgetTester tester, String? outputFilePath) async {
  if (outputFilePath == null || outputFilePath.isEmpty) return;
  final file = File(outputFilePath);
  if (!file.parent.existsSync()) return;
  await tester.runAsync(() async {
    final repaintBoundaryFinder = find.byType(RepaintBoundary).first;
    final boundary =
        tester.renderObject(repaintBoundaryFinder) as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    file.writeAsBytesSync(pngBytes);
  });
}

void main() {
  final artifactDir = Platform.environment['SNAPSHOT_OUTPUT_DIR'];

  testWidgets('Snapshot: Unconfigured / Empty State', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
      RepaintBoundary(
        child: ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            prefsProvider.overrideWithValue(prefsService),
          ],
          child: const WarThunderEditorApp(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    if (artifactDir != null && artifactDir.isNotEmpty) {
      await _captureToPng(tester, '$artifactDir/ui_snapshot_empty.png');
    }
    await db.close();
  });

  testWidgets('Snapshot: Populated State', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
      RepaintBoundary(
        child: ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            prefsProvider.overrideWithValue(prefsService),
            availableFilesProvider.overrideWith(
              (ref) => Future.value([
                'units.csv',
                'menu.csv',
                'ui.csv',
                'missions.csv',
                'hud.csv',
                'shop.csv',
              ]),
            ),
            baseStringsProvider('units.csv').overrideWith(
              (ref) => Future.value({
                'us_m4a3_76w_sherman': 'M4A3 (76) W',
                'germ_tiger_ii': 'Tiger II (H)',
                'ussr_t_34_85': 'T-34-85',
                'uk_spitfire_mk9': 'Spitfire F. Mk IX',
                'jp_a6m5_zero': 'A6M5 Reisen',
              }),
            ),
            overridesProvider('units.csv').overrideWith(
              (ref) => Stream.value({
                'us_m4a3_76w_sherman': 'Easy Eight Sherman',
                'germ_tiger_ii': 'King Tiger (Production Turret)',
              }),
            ),
          ],
          child: const WarThunderEditorApp(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    if (artifactDir != null && artifactDir.isNotEmpty) {
      await _captureToPng(tester, '$artifactDir/ui_snapshot_populated.png');
    }
    await db.close();
  });
}
