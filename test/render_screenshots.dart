import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
    }
    await loader.load();
  }

  final fontFamilies = [
    'Ahem',
    'Inter',
    'Roboto',
    'sans-serif',
    '.AppleSystemUIFont',
    '.SF UI Text',
    '.SF Pro Text',
    'Segoe UI',
  ];
  for (final family in fontFamilies) {
    await load(family, [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ]);
  }

  await load('JetBrainsMono', [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
    'assets/fonts/JetBrainsMono-Bold.ttf',
  ]);

  await load('MaterialIcons', [
    '/Users/vonar/src/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);

  await load('packages/cupertino_icons/CupertinoIcons', [
    '/Users/vonar/src/flutter_sdk/build/unit_test_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  ]);
}

Future<void> _captureToPng(
  WidgetTester tester,
  String outputFilePath, {
  double pixelRatio = 2.0,
}) async {
  await tester.runAsync(() async {
    final repaintBoundaryFinder = find.byType(RepaintBoundary).first;
    final boundary =
        tester.renderObject(repaintBoundaryFinder) as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    File(outputFilePath).writeAsBytesSync(pngBytes);
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('Generate Real Populated Cockpit Screenshot', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      PreferencesService.keyWtInstallPath: '/Applications/WarThunder',
      PreferencesService.keyAutoExportOnSave: false,
      PreferencesService.keyLastOpenedCsv: 'units.csv',
    });

    final prefs = await SharedPreferences.getInstance();
    final prefsService = PreferencesService(prefs);
    final db = AppDatabase(NativeDatabase.memory());

    final sampleBase = <String, String>{
      'germ_leopard_2a7v': 'Leopard 2A7V',
      'us_m1a2_sep_v2': 'M1A2 SEP v2',
      'ussr_t_80bvm': 'T-80BVM',
      'us_f_16c_block_50': 'F-16C Fighting Falcon',
      'ussr_su_27sm': 'Su-27SM',
      'sw_strv_122b_plus': 'Strv 122B+',
      'uk_challenger_3_td': 'Challenger 3 TD',
      'hud_missile_lock_warning': 'MISSILE LOCK',
      'kill_message_headshot': 'Pilot knocked out',
      'germ_panzerfaust_3': 'PzF 3 Ammunition',
      'menu_battle_start': 'To Battle!',
    };

    final sampleOverrides = <String, String>{
      'germ_leopard_2a7v': 'Leopard 2A7V (PzBtl 104)',
      'us_m1a2_sep_v2': 'M1A2 SEP v2 "Iron Horse"',
      'ussr_t_80bvm': 'T-80BVM (Model 2023)',
      'hud_missile_lock_warning': '[WARNING] FOX-2 INCOMING!',
      'kill_message_headshot': 'TARGET NEUTRALIZED [DIRECT HIT]',
    };

    await tester.pumpWidget(
      RepaintBoundary(
        child: ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            prefsProvider.overrideWithValue(prefsService),
            configBlkStatusProvider.overrideWith(
              (ref) => Future.value(
                const ConfigBlkStatus(
                  exists: true,
                  isLocalizationEnabled: true,
                  filePath: '/Applications/WarThunder/config.blk',
                ),
              ),
            ),
            availableFilesProvider.overrideWith(
              (ref) => Future.value([
                'units.csv',
                'menu.csv',
                'ui.csv',
                'missions_briefing.csv',
                'hud.csv',
                'shop.csv',
              ]),
            ),
            baseStringsProvider('units.csv')
                .overrideWith((ref) => Future.value(sampleBase)),
            overridesProvider('units.csv')
                .overrideWith((ref) => Stream.value(sampleOverrides)),
          ],
          child: const WarThunderEditorApp(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Save populated screenshot to docs/screenshots/ and composition assets
    await _captureToPng(
      tester,
      'docs/screenshots/cockpit_populated.png',
      pixelRatio: 1.5,
    );
    await _captureToPng(
      tester,
      'brag-output/composition/assets/images/cockpit.png',
      pixelRatio: 1.5,
    );

    await db.close();
  });

  testWidgets('Generate Real Setup Cockpit Screenshot', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 500));

    await _captureToPng(
      tester,
      'docs/screenshots/cockpit_setup.png',
      pixelRatio: 1.5,
    );

    await db.close();
  });
}
