import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:gramercy/features/localization/providers/environment_providers.dart';
import 'package:gramercy/features/localization/services/rebuild_synthesizer.dart';

/// End-to-end acceptance test for F1-1 (SEVERE): a hostile community preset
/// row stored in the vault must NOT be able to escape lang/ during the
/// advertised "Reload & Apply" flow, while legit rows keep applying.
///
/// Real file IO lives in setUp / tester.runAsync, never directly in the
/// fake-async test body.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late File unitsFile;
  late File victimFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gramercy_rebuild_sec_');
    db = AppDatabase(NativeDatabase.memory());

    final langDir = Directory('${tempDir.path}/lang');
    await langDir.create(recursive: true);
    unitsFile = File('${langDir.path}/units.csv');
    await unitsFile.writeAsString(
      '<ID>;<English>\r\nus_m4a3;Stock Sherman\r\n',
    );
    // The hostile target must EXIST: the old chain was only gated by
    // existsSync, which is exactly why existing files could be trashed.
    victimFile = File('${tempDir.path}/victim.txt');
    await victimFile.writeAsString('DO NOT TOUCH');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  WidgetRef captureRef(WidgetTester tester) {
    WidgetRef? captured;
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWith((ref) => db),
          workerServiceProvider.overrideWith(
            (ref) => _DirectCsvWorkerService(),
          ),
          availableFilesProvider.overrideWith((ref) async => ['units.csv']),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured!;
  }

  testWidgets(
    'F1-1 hostile preset row is skipped on Reload & Apply; safe rows apply',
    (WidgetTester tester) async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: 'units.csv',
          stringKey: 'us_m4a3',
          customValue: 'Easy Eight',
        ),
      );
      // Hostile rows as they would land from a malicious preset import, in
      // both separator conventions: they previously joined straight into
      // p.join(wtPath, 'lang', entry.key).
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: '..\\victim.csv',
          stringKey: 'pwned',
          customValue: 'PWNED',
        ),
      );
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: '../../victim.csv',
          stringKey: 'pwned2',
          customValue: 'PWNED',
        ),
      );

      final ref = captureRef(tester);
      final summaryOrNull = await tester.runAsync(
        () => RebuildSynthesizer().reloadAndSynthesize(
          ref: ref,
          wtPath: tempDir.path,
        ),
      );
      expect(summaryOrNull, isNotNull);
      final summary = summaryOrNull!;
      await tester.runAsync(() async {
        final unitsOut = await unitsFile.readAsString();

        expect(summary.success, isTrue);
        // Only the safe row is counted (hostile entries are skipped).
        expect(summary.overridesApplied, equals(1));
        // Safe override applied to the real game file.
        expect(unitsOut, contains('us_m4a3;Easy Eight'));
        // Victim outside lang/ survived every hostile row.
        expect(await victimFile.readAsString(), 'DO NOT TOUCH');
      });
    },
  );

  testWidgets(
    'F1-1 success summary reports zero when every vault row is hostile',
    (WidgetTester tester) async {
      await db.saveOverride(
        LocalizationsOverridesCompanion.insert(
          fileName: '../victim.csv',
          stringKey: 'pwned',
          customValue: 'PWNED',
        ),
      );

      final ref = captureRef(tester);
      final summaryOrNull = await tester.runAsync(
        () => RebuildSynthesizer().reloadAndSynthesize(
          ref: ref,
          wtPath: tempDir.path,
        ),
      );
      expect(summaryOrNull, isNotNull);
      expect(summaryOrNull!.overridesApplied, equals(0));
      await tester.runAsync(
        () async => expect(await victimFile.readAsString(), 'DO NOT TOUCH'),
      );
    },
  );
}

/// Runs the real export worker synchronously (no isolate scheduler) so the
/// end-to-end fixture exercises the same code path deterministically.
class _DirectCsvWorkerService extends LocalizationWorkerService {
  @override
  Future<bool> exportPatchedCsv({
    required String baseFilePath,
    required String targetFilePath,
    required Map<String, String> overrides,
  }) {
    return exportPatchedCsvWorker(
      ExportTaskParameters(
        baseFilePath: baseFilePath,
        targetFilePath: targetFilePath,
        overrides: overrides,
      ),
    );
  }
}
